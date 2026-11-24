import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hasil submit menyimpan ID pengerjaan untuk membuka evaluasi', () async {
    final app = AppProvider(
      apiClient: ApiClient(
        client: _RecordingClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/siswa/kuis/K001/submit');
          return _jsonResponse(request, {
            'data': {'id_mengerjakan': 42, 'nilai': '80.00'},
          });
        }),
      ),
    );
    addTearDown(app.dispose);

    final result = await app.kumpulkanKuisSiswa('K001');

    expect(result.idMengerjakan, '42');
    expect(result.nilai, 80);
  });

  test('nilai null tetap menjadi hasil menunggu penilaian esai', () async {
    final app = AppProvider(
      apiClient: ApiClient(
        client: _RecordingClient(
          (request) async => _jsonResponse(request, {
            'data': {'id_mengerjakan': 43, 'nilai': null},
          }),
        ),
      ),
    );
    addTearDown(app.dispose);

    final result = await app.kumpulkanKuisSiswa('K002');

    expect(result.idMengerjakan, '43');
    expect(result.nilai, isNull);
  });

  test('memuat kunci dan jawaban siswa untuk setiap soal evaluasi', () async {
    late String requestPath;
    final app = AppProvider(
      apiClient: ApiClient(
        client: _RecordingClient((request) async {
          requestPath = request.url.path;
          return _jsonResponse(request, {
            'data': {
              'tampil_evaluasi': true,
              'soal': [
                {
                  'pertanyaan': 'Perangkat keras yang menjadi otak komputer?',
                  'tipe_soal': 'pilihan_ganda',
                  'opsi_a': 'RAM',
                  'opsi_b': 'CPU',
                  'opsi_c': 'Monitor',
                  'opsi_d': 'Keyboard',
                  'jawaban_benar': 'B',
                  'jawaban_dipilih': 'C',
                  'bobot': '50.00',
                },
                {
                  'pertanyaan': 'Jelaskan prosesnya.',
                  'tipe_soal': 'esai',
                  'jawaban_teks': 'Jawaban siswa',
                  'nilai_essay': null,
                  'bobot': '50.00',
                },
              ],
            },
          });
        }),
      ),
    );
    addTearDown(app.dispose);

    final evaluation = await app.loadEvaluasiSoal('42');

    expect(requestPath, '/api/siswa/nilai/42/evaluasi');
    expect(evaluation.tampilEvaluasi, isTrue);
    expect(evaluation.soal, hasLength(2));
    expect(evaluation.soal.first.jawabanBenar, 1);
    expect(evaluation.soal.first.jawabanDipilih, 2);
    expect(evaluation.soal.first.opsi[1], 'CPU');
    expect(evaluation.soal.last.jenis, 'esai');
    expect(evaluation.soal.last.jawabanTeks, 'Jawaban siswa');
  });

  test('menghormati kebijakan kuis yang menyembunyikan evaluasi', () async {
    final app = AppProvider(
      apiClient: ApiClient(
        client: _RecordingClient(
          (request) async => _jsonResponse(request, {
            'data': {'tampil_evaluasi': false, 'soal': []},
          }),
        ),
      ),
    );
    addTearDown(app.dispose);

    final evaluation = await app.loadEvaluasiSoal('42');

    expect(evaluation.tampilEvaluasi, isFalse);
    expect(evaluation.soal, isEmpty);
  });
}

http.StreamedResponse _jsonResponse(
  http.BaseRequest request,
  Map<String, dynamic> body,
) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
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
