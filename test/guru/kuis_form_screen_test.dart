import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/kuis_form_screen.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('materi terkait wajib dipilih sebelum membuat kuis',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var createQuizRequested = false;
    final app = AppProvider(
      apiClient: ApiClient(
        client: MockClient((request) async {
          if (request.url.path == '/api/guru/mapel') {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id_mapel': 'MP001',
                    'kode_mapel': 'TIK',
                    'nama_mapel': 'Teknologi Informasi',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/guru/tahun-ajaran/aktif') {
            return http.Response(
              jsonEncode({
                'data': {
                  'id_tahun_ajaran': 'TA001',
                  'nama': '2026/2027',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/guru/kuis') {
            createQuizRequested = true;
          }
          throw StateError('Unexpected API request: ${request.url.path}');
        }),
      ),
    )..materiList.add(
        Materi(
          id: 'M001',
          bab: 'Bab 1',
          judul: 'Perangkat Komputer',
          kelas: 'X',
          deskripsi: '',
          isi: '',
          idMapel: 'MP001',
          pdfName: '',
          ukuran: '',
          oleh: 'Guru',
          tanggal: '',
        ),
      );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
          home: KuisFormScreen(initialMapelId: 'MP001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Materi Terkait *'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Kuis Perangkat Komputer',
    );
    await tester.scrollUntilVisible(
      find.text('Buat Kuis & Tambah Soal'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Buat Kuis & Tambah Soal'));
    await tester.pumpAndSettle();

    expect(find.text('Materi terkait wajib dipilih.'), findsOneWidget);
    expect(createQuizRequested, isFalse);
  });
}
