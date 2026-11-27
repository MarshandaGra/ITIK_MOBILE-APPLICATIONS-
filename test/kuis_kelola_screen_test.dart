import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itik_mobile/models/kuis.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/kuis_kelola_screen.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('kuis dikelompokkan per mapel dan bisa dibuat langsung',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
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
                  {
                    'id_mapel': 'MP002',
                    'kode_mapel': 'BIN',
                    'nama_mapel': 'Bahasa Indonesia',
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
          throw StateError('Unexpected API request: ${request.url.path}');
        }),
      ),
    )
      ..materiList.addAll([
        Materi(
          id: 'materi-1',
          bab: 'Bab 3',
          judul: 'Internet & Email',
          kelas: 'X TKJ',
          deskripsi: '',
          isi: '',
          idMapel: 'MP001',
          pdfName: '',
          ukuran: '',
          oleh: 'Guru',
          tanggal: '2026-11-17',
        ),
        Materi(
          id: 'materi-2',
          bab: 'Bab 1',
          judul: 'Teks Laporan',
          kelas: 'X',
          deskripsi: '',
          isi: '',
          idMapel: 'MP002',
          pdfName: '',
          ukuran: '',
          oleh: 'Guru',
          tanggal: '2026-11-17',
        ),
      ])
      ..kuisList.addAll([
        _kuis('1', 'terbit'),
        _kuis('2', 'terbit'),
        _kuis('3', 'terbit'),
        _kuis('4', 'draft'),
        _kuis('5', 'draft', materiId: 'materi-2'),
      ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: KuisKelolaScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kuis & Soal'), findsOneWidget);
    expect(find.text('Teknologi Informasi'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);

    await tester.tap(find.text('Teknologi Informasi'));
    await tester.pumpAndSettle();

    expect(find.text('Materi untuk Kuis (1)'), findsNothing);
    expect(find.text('Buat kuis untuk materi ini'), findsNothing);
    expect(find.text('1 materi • 4 kuis'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Pilih mata pelajaran lain')).dy,
      lessThan(tester.getTopLeft(find.text('1 materi • 4 kuis')).dy),
    );
    expect(find.text('Semua (4)'), findsOneWidget);
    expect(find.text('Terbit (3)'), findsOneWidget);
    expect(find.text('Draft (1)'), findsOneWidget);

    await tester.tap(find.text('Pilih mata pelajaran lain'));
    await tester.pumpAndSettle();
    expect(find.text('Bahasa Indonesia'), findsOneWidget);

    await tester.tap(find.text('Teknologi Informasi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terbit (3)'));
    await tester.pumpAndSettle();

    expect(find.text('Semua (4)'), findsOneWidget);
    expect(find.text('Terbit (3)'), findsOneWidget);
    expect(find.text('Draft (1)'), findsOneWidget);
    expect(find.text('Kuis & Soal (3)'), findsOneWidget);

    final createQuizButton = find.text('Tambah Kuis');
    expect(createQuizButton, findsOneWidget);
    await tester.tap(createQuizButton);
    await tester.pumpAndSettle();

    expect(find.text('Formulir Kuis'), findsOneWidget);
    expect(find.text('Teknologi Informasi'), findsOneWidget);
    expect(find.text('Materi Terkait *'), findsOneWidget);
    expect(find.text('2026/2027'), findsOneWidget);
  });
}

Kuis _kuis(String id, String status, {String materiId = 'materi-1'}) => Kuis(
      id: id,
      judul: 'Kuis $id',
      materiId: materiId,
      level: 'Mudah',
      oleh: 'Guru',
      tanggal: '2026-11-17',
      waktu: 30,
      kkm: 75,
      soal: const [],
      statusPublikasi: status,
    );
