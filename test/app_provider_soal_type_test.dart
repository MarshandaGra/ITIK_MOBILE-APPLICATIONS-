import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:itik_mobile/models/kuis.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('API infer pilihan ganda dari opsi dan mengunggah gambar', () async {
    late Map<String, String> fields;
    late List<http.MultipartFile> files;
    final app = _appWithClient(
      _RecordingClient((request) async {
        final multipart = request as http.MultipartRequest;
        fields = Map<String, String>.from(multipart.fields);
        files = multipart.files;
        return _streamedResponse(request, 'pilihan_ganda');
      }),
    );
    addTearDown(app.dispose);

    await app.tambahSoal(
      'K1',
      Soal(
        pertanyaan: 'Pilih jawaban yang benar.',
        opsi: const ['A', 'B', 'C', 'D', ''],
        jawaban: 0,
        bobot: 100,
        gambar: Uint8List.fromList([1, 2, 3]),
        gambarNamaFile: 'gambar.png',
      ),
    );

    expect(fields['pertanyaan'], 'Pilih jawaban yang benar.');
    expect(fields['opsi_a'], 'A');
    expect(fields['opsi_d'], 'D');
    expect(fields['jawaban'], 'A');
    expect(fields.containsKey('tipe'), isFalse);
    expect(fields.containsKey('tipe_soal'), isFalse);
    expect(files, hasLength(1));
    expect(files.single.field, 'gambar');
    expect(files.single.filename, 'gambar.png');
    expect(app.kuisList.single.soal.single.jenis, Soal.pilihanGanda);
    expect(
      app.kuisList.single.soal.single.gambarUrl,
      endsWith('/storage/soal/soal-1.png'),
    );
  });

  test('API mengirim opsi kosong dan membaca soal esai', () async {
    late Map<String, dynamic> body;
    final app = _appWithClient(
      _RecordingClient((request) async {
        final jsonRequest = request as http.Request;
        body = jsonDecode(jsonRequest.body) as Map<String, dynamic>;
        return _streamedResponse(request, 'esai');
      }),
    );
    addTearDown(app.dispose);

    await app.tambahSoal(
      'K1',
      Soal(
        pertanyaan: 'Jelaskan konsepnya.',
        opsi: const [],
        jawaban: 0,
        bobot: 100,
        jenis: Soal.esai,
      ),
    );

    expect(body.containsKey('tipe'), isFalse);
    expect(body.containsKey('tipe_soal'), isFalse);
    expect(body['opsi_a'], isNull);
    expect(body['jawaban'], isNull);
    expect(app.kuisList.single.soal.single.jenis, Soal.esai);
  });

  test('URL gambar localhost memakai host API mobile', () async {
    final app = _appWithClient(
      _RecordingClient(
        (request) async => _streamedResponse(
          request,
          'esai',
          imageUrl: 'http://localhost/storage/soal/soal-1.png',
        ),
      ),
    );
    addTearDown(app.dispose);

    await app.tambahSoal(
      'K1',
      Soal(
        pertanyaan: 'Jelaskan konsepnya.',
        opsi: const [],
        jawaban: 0,
        bobot: 100,
        jenis: Soal.esai,
      ),
    );

    final imageUri = Uri.parse(app.kuisList.single.soal.single.gambarUrl!);
    expect(imageUri.host, Uri.parse(ApiClient.baseUrl).host);
    expect(imageUri.path, '/storage/soal/soal-1.png');
  });

  test('URL gambar 127.0.0.1 memakai host API mobile', () async {
    final app = _appWithClient(
      _RecordingClient(
        (request) async => _streamedResponse(
          request,
          'esai',
          imageUrl: 'http://127.0.0.1:8000/storage/soal/soal-1.png',
        ),
      ),
    );
    addTearDown(app.dispose);

    await app.tambahSoal(
      'K1',
      Soal(
        pertanyaan: 'Jelaskan konsepnya.',
        opsi: const [],
        jawaban: 0,
        bobot: 100,
        jenis: Soal.esai,
      ),
    );

    final imageUri = Uri.parse(app.kuisList.single.soal.single.gambarUrl!);
    expect(imageUri.host, Uri.parse(ApiClient.baseUrl).host);
    expect(imageUri.port, Uri.parse(ApiClient.baseUrl).port);
    expect(imageUri.path, '/storage/soal/soal-1.png');
  });

  test('URL gambar hostname server memakai host API mobile', () async {
    final app = _appWithClient(
      _RecordingClient(
        (request) async => _streamedResponse(
          request,
          'esai',
          imageUrl: 'http://itik.test/storage/soal/soal-1.png',
        ),
      ),
    );
    addTearDown(app.dispose);

    await app.tambahSoal(
      'K1',
      Soal(
        pertanyaan: 'Jelaskan konsepnya.',
        opsi: const [],
        jawaban: 0,
        bobot: 100,
        jenis: Soal.esai,
      ),
    );

    final imageUri = Uri.parse(app.kuisList.single.soal.single.gambarUrl!);
    expect(imageUri.host, Uri.parse(ApiClient.baseUrl).host);
    expect(imageUri.path, '/storage/soal/soal-1.png');
  });

  test('path gambar dipakai jika URL gambar kosong', () async {
    final app = _appWithClient(
      _RecordingClient(
        (request) async => http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'data': {
                  'id_soal': 'S1',
                  'tipe_soal': 'esai',
                  'pertanyaan': 'Jelaskan konsepnya.',
                  'gambar_url': '',
                  'gambar_path': 'soal/soal-1.png',
                  'opsi_a': null,
                  'opsi_b': null,
                  'opsi_c': null,
                  'opsi_d': null,
                  'jawaban': null,
                  'bobot': 100,
                },
              }),
            ),
          ),
          201,
          request: request,
        ),
      ),
    );
    addTearDown(app.dispose);

    await app.tambahSoal(
      'K1',
      Soal(
        pertanyaan: 'Jelaskan konsepnya.',
        opsi: const [],
        jawaban: 0,
        bobot: 100,
        jenis: Soal.esai,
      ),
    );

    expect(
      app.kuisList.single.soal.single.gambarUrl,
      endsWith('/storage/soal/soal-1.png'),
    );
  });
}

AppProvider _appWithClient(http.Client client) {
  return AppProvider(apiClient: ApiClient(client: client))
    ..kuisList.add(
      Kuis(
        id: 'K1',
        judul: 'Kuis',
        materiId: 'M1',
        level: 'mudah',
        oleh: 'Guru',
        tanggal: '2026-11-19',
        waktu: 30,
        kkm: 75,
        soal: [],
      ),
    );
}

http.StreamedResponse _streamedResponse(
  http.BaseRequest request,
  String type, {
  String? imageUrl,
}) =>
    http.StreamedResponse(
      Stream.value(
        utf8.encode(jsonEncode({
          'data': {
            'id_soal': 'S1',
            'tipe_soal': type,
            'pertanyaan': 'Pertanyaan.',
            if (imageUrl == null)
              'gambar_path': 'soal/soal-1.png'
            else
              'gambar_url': imageUrl,
            'opsi_a': type == 'esai' ? null : 'A',
            'opsi_b': type == 'esai' ? null : 'B',
            'opsi_c': type == 'esai' ? null : 'C',
            'opsi_d': type == 'esai' ? null : 'D',
            'jawaban': type == 'esai' ? null : 'A',
            'bobot': 100,
          },
        })),
      ),
      201,
      request: request,
    );

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);

  @override
  void close() {}
}
