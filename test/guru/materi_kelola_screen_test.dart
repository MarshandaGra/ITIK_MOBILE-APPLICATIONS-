import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/materi_kelola_screen.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('mapel dari API menjadi kartu dan memfilter daftar materi',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/guru/mapel');
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id_mapel': 'MP001',
                  'kode_mapel': 'TIK',
                  'nama_mapel': 'Teknologi Informasi dan Komunikasi',
                },
                {
                  'id_mapel': 'MP002',
                  'kode_mapel': 'IPA',
                  'nama_mapel': 'Ilmu Pengetahuan Alam',
                },
                {
                  'id_mapel': 'MP003',
                  'kode_mapel': 'DG',
                  'nama_mapel': 'Desain Grafis',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    )..materiList.addAll([
        _materi(
          id: 'materi-1',
          idMapel: 'MP001',
          judul: 'Internet dan Email',
        ),
        _materi(
          id: 'materi-2',
          idMapel: 'MP002',
          judul: 'Sistem Tata Surya',
        ),
      ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: MateriKelolaScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Teknologi Informasi dan Komunikasi'), findsOneWidget);
    expect(find.text('Ilmu Pengetahuan Alam'), findsOneWidget);
    expect(find.text('Desain Grafis'), findsOneWidget);
    expect(find.text('0 Materi Pembelajaran'), findsOneWidget);

    await tester.tap(find.text('Teknologi Informasi dan Komunikasi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Internet dan Email'), findsOneWidget);
    expect(find.text('Sistem Tata Surya'), findsNothing);
    expect(find.text('Materi Pembelajaran (1)'), findsOneWidget);
    expect(find.text('1 materi pembelajaran tersedia'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Pilih mata pelajaran lain')).dy,
      lessThan(
        tester.getTopLeft(find.text('1 materi pembelajaran tersedia')).dy,
      ),
    );

    await tester.tap(find.text('Pilih mata pelajaran lain'));
    await tester.pumpAndSettle();
    expect(find.text('Ilmu Pengetahuan Alam'), findsOneWidget);

    await tester.tap(find.text('Teknologi Informasi dan Komunikasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambahkan Materi'));
    await tester.pumpAndSettle();

    expect(find.text('Formulir Materi Baru'), findsOneWidget);
    expect(find.text('Teknologi Informasi dan Komunikasi'), findsOneWidget);
  });
}

Materi _materi({
  required String id,
  required String idMapel,
  required String judul,
}) =>
    Materi(
      id: id,
      bab: 'Bab 1',
      judul: judul,
      kelas: 'X TKJ',
      deskripsi: '',
      isi: '',
      idMapel: idMapel,
      mataPelajaran: 'Mapel',
      pdfName: '',
      ukuran: '',
      oleh: 'Guru',
      tanggal: '',
    );
