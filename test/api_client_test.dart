import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itik_mobile/services/api_client.dart';

void main() {
  test('materi upload sends multipart fields and the PDF with bearer auth',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/guru/materi');
      expect(
          request.headers['content-type'], startsWith('multipart/form-data;'));
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(request.body, contains('name="id_mapel"'));
      expect(request.body, contains('name="judul"'));
      expect(request.body, contains('name="file_pdf"; filename="materi.pdf"'));
      expect(request.body, contains('%PDF-1.4'));

      return http.Response(
        jsonEncode({
          'data': {
            'id_materi': 'M001',
            'pdf_url': 'https://example.test/materi.pdf'
          }
        }),
        201,
      );
    });
    final api = ApiClient(client: client)..token = 'test-token';

    final response = await api.multipartRequest(
      '/guru/materi',
      fields: {'id_mapel': 'MP001', 'judul': 'Materi'},
      fileBytes: Uint8List.fromList(utf8.encode('%PDF-1.4')),
      fileName: 'materi.pdf',
    );

    expect(response['data']['pdf_url'], 'https://example.test/materi.pdf');
    api.close();
  });

  test('materi edit uses POST multipart with Laravel method spoofing',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.body, contains('name="_method"'));
      expect(request.body, contains('PUT'));
      return http.Response(
          jsonEncode({
            'data': {'id_materi': 'M001'}
          }),
          200);
    });
    final api = ApiClient(client: client);

    await api.multipartRequest(
      '/guru/materi/M001',
      fields: {'id_mapel': 'MP001', 'judul': 'Materi'},
      update: true,
    );

    api.close();
  });

  test('materi PDF request uses bearer auth and validates the PDF response',
      () async {
    final pdfBytes = Uint8List.fromList(utf8.encode('%PDF-1.4\n'));
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/guru/materi/M001/pdf');
      expect(request.headers['accept'], 'application/pdf');
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response.bytes(
        pdfBytes,
        200,
        headers: {'content-type': 'application/pdf'},
      );
    });
    final api = ApiClient(client: client)..token = 'test-token';

    expect(await api.getPdf('/guru/materi/M001/pdf'), pdfBytes);
    api.close();
  });

  test('materi PDF request rejects an HTML page instead of a PDF', () async {
    final client = MockClient((request) async => http.Response(
          '<html>login</html>',
          200,
          headers: {'content-type': 'text/html'},
        ));
    final api = ApiClient(client: client);

    await expectLater(
      api.getPdf('/guru/materi/M001/pdf'),
      throwsA(isA<FormatException>()),
    );
    api.close();
  });
}
