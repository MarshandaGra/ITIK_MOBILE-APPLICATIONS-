import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:itik_mobile/models/user.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads master classes and their IDs for teacher score filtering',
      () async {
    final requestedPaths = <String>[];
    final app = AppProvider(
      apiClient: ApiClient(
        client: _RecordingClient((request) async {
          requestedPaths.add(request.url.path);
          final response = request.url.path.endsWith('/guru/nilai')
              ? {
                  'data': {
                    'data': [
                      {
                        'id_mengerjakan': 12,
                        'id_kuis': 'K001',
                        'id_user': 'S001',
                        'nilai': 65,
                        'percobaan_ke': 2,
                        'status_pengerjaan': 'final',
                        'status_validasi': 'belum divalidasi',
                        'tanggal': '2026-11-25',
                        'kuis': {
                          'id_kuis': 'K001',
                          'judul': 'Kuis Informatika',
                          'kategori': 'kuis harian',
                          'kkm': 70,
                        },
                        'siswa': {
                          'id_user': 'S001',
                          'nama_lengkap': 'Siswa Satu',
                          'kelas_diikuti': [
                            {
                              'id_kelas': 'KLS001',
                              'nama_kelas': 'TKJ 1',
                              'tingkat': 'X',
                            },
                          ],
                        },
                      },
                    ],
                    'last_page': 1,
                  },
                }
              : {
                  'data': [
                    {
                      'id_kelas': 'KLS001',
                      'nama_kelas': 'TKJ 1',
                      'tingkat': 'X',
                      'total_siswa': 1,
                      'total_materi': 0,
                      'kuis_aktif': 0,
                      'jumlah_nilai': 1,
                      'rata_nilai': 65,
                    },
                  ],
                };

          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(response))),
            200,
            request: request,
          );
        }),
      ),
    );
    addTearDown(app.dispose);

    await app.restoreSession();
    app.currentUser = AppUser(
      id: 'G001',
      nama: 'Guru',
      email: '',
      password: '',
      role: UserRole.guru,
    );

    await app.loadNilaiGuru();

    expect(requestedPaths, contains('/api/guru/kelas'));
    expect(app.kelasGuruList.single.id, 'KLS001');
    expect(app.hasilList.single.kelasIds, ['KLS001']);
    expect(app.hasilList.single.kategori, 'kuis harian');
    expect(app.hasilList.single.percobaanKe, 2);
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
