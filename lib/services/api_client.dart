import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Laravel API client. Override the default URL with
/// `--dart-define=API_BASE_URL=http://<host>:8000/api` when running the app.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static const _configuredAssetUrl = String.fromEnvironment('ASSET_BASE_URL');
  static String get baseUrl => _configuredUrl.isNotEmpty
      ? _configuredUrl
      : (kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api');
  static String get assetBaseUrl {
    if (_configuredAssetUrl.isNotEmpty) return _configuredAssetUrl;

    final base = Uri.parse(baseUrl);
    final rootPath = base.path
        .replaceFirst(RegExp(r'/api/?$'), '')
        .replaceAll(RegExp(r'/+$'), '');
    return base
        .replace(
            path: rootPath.isEmpty ? '/' : rootPath,
            query: null,
            fragment: null)
        .toString()
        .replaceFirst(RegExp(r'/+$'), '');
  }

  final http.Client _client;
  String? token;

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    late http.Response response;
    switch (method) {
      case 'POST':
        response =
            await _client.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PUT':
        response =
            await _client.put(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PATCH':
        response =
            await _client.patch(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        response = await _client.get(uri, headers: headers);
    }
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = data['errors'];
      final detail = errors is Map
          ? errors.values.expand((v) => v is List ? v : [v]).join('\n')
          : null;
      throw ApiException(
          (detail?.toString().isNotEmpty ?? false)
              ? detail.toString()
              : (data['message']?.toString() ??
                  'Permintaan gagal (${response.statusCode}).'),
          response.statusCode);
    }
    return data;
  }

  Future<Uint8List> getPdf(
    String path, {
    bool authenticated = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/pdf'};
    if (authenticated && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          message = decoded['message']?.toString();
        }
      } on FormatException {
        // The server may return a non-JSON error page.
      }
      throw ApiException(
        message ?? 'Gagal mengambil PDF (${response.statusCode}).',
        response.statusCode,
      );
    }

    final contentType =
        response.headers['content-type']?.split(';').first.trim().toLowerCase();
    if (contentType != 'application/pdf') {
      throw const FormatException(
        'Server tidak mengembalikan file PDF.',
      );
    }

    final bytes = response.bodyBytes;
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('File yang diterima bukan PDF yang valid.');
    }
    return bytes;
  }

  Future<Map<String, dynamic>> multipartRequest(
    String path, {
    required Map<String, String> fields,
    Uint8List? fileBytes,
    String? fileName,
    String fileField = 'file_pdf',
    bool update = false,
    bool authenticated = true,
  }) async {
    if ((fileBytes == null) != (fileName == null)) {
      throw ArgumentError('fileBytes dan fileName harus diberikan bersama.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
    )..headers['Accept'] = 'application/json';
    if (update) request.fields['_method'] = 'PUT';
    request.fields.addAll(fields);
    if (authenticated && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (fileBytes != null && fileName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
      ));
    }

    final response =
        await http.Response.fromStream(await _client.send(request));
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errors = data['errors'];
      final detail = errors is Map
          ? errors.values
              .expand((value) => value is List ? value : [value])
              .join('\n')
          : null;
      throw ApiException(
        (detail?.toString().isNotEmpty ?? false)
            ? detail.toString()
            : (data['message']?.toString() ??
                'Permintaan gagal (${response.statusCode}).'),
        response.statusCode,
      );
    }
    return data;
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message;
}
