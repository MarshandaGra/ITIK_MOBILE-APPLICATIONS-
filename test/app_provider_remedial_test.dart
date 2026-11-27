import 'dart:convert';

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

  test('kuis remedial dibuat lewat endpoint remedial dan membaca kuis terkait',
      () async {
    late Map<String, dynamic> body;
    final app = AppProvider(
      apiClient: ApiClient(
        client: _RecordingClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/guru/remedial');
          body = jsonDecode((request as http.Request).body)
              as Map<String, dynamic>;
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'data': {
                    'id_remedial': 1,
                    'id_kuis_remedial': 'K101',
                    'id_kuis_asal': 'K100',
                    'kuis_remedial': {
                      'id_kuis': 'K101',
                      'judul': 'Remedial Bab 1',
                      'kategori': 'remedial',
                      'status_publikasi': 'draft',
                      'alokasi_waktu': 20,
                      'kkm': 70,
                    },
                  },
                }),
              ),
            ),
            201,
            request: request,
          );
        }),
      ),
    );
    addTearDown(app.dispose);

    final saved = await app.tambahKuis(
      Kuis(
        id: '',
        judul: 'Remedial Bab 1',
        materiId: 'M001',
        level: 'mudah',
        oleh: 'Guru',
        tanggal: '',
        waktu: 20,
        kkm: 70,
        soal: const [],
        kategori: 'remedial',
        idKuisAsal: 'K100',
      ),
    );

    expect(body['judul'], 'Remedial Bab 1');
    expect(body['id_kuis_asal'], 'K100');
    expect(body['id_materi'], 'M001');
    expect(saved.id, 'K101');
    expect(saved.idKuisAsal, 'K100');
    expect(app.kuisList.single.id, 'K101');
  });
}

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
