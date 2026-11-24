import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itik_mobile/models/kuis.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/kuis_kelola_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('filter status tidak mengubah jumlah tiap status',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider()
      ..materiList.add(
        Materi(
          id: 'materi-1',
          bab: 'Bab 3',
          judul: 'Internet & Email',
          kelas: 'X TKJ',
          deskripsi: '',
          isi: '',
          pdfName: '',
          ukuran: '',
          oleh: 'Guru',
          tanggal: '2026-11-17',
        ),
      )
      ..kuisList.addAll([
        _kuis('1', 'terbit'),
        _kuis('2', 'terbit'),
        _kuis('3', 'terbit'),
        _kuis('4', 'draft'),
      ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: KuisKelolaScreen()),
      ),
    );

    expect(find.text('Kuis & Soal'), findsOneWidget);
    expect(find.text('Semua (4)'), findsOneWidget);
    expect(find.text('Terbit (3)'), findsOneWidget);
    expect(find.text('Draft (1)'), findsOneWidget);

    await tester.tap(find.text('Terbit (3)'));
    await tester.pumpAndSettle();

    expect(find.text('Semua (4)'), findsOneWidget);
    expect(find.text('Terbit (3)'), findsOneWidget);
    expect(find.text('Draft (1)'), findsOneWidget);
    expect(find.text('Kuis (3)'), findsOneWidget);
    expect(find.text('Bab 3 — Internet & Email'), findsNWidgets(2));
  });
}

Kuis _kuis(String id, String status) => Kuis(
      id: id,
      judul: 'Kuis $id',
      materiId: 'materi-1',
      level: 'Mudah',
      oleh: 'Guru',
      tanggal: '2026-11-17',
      waktu: 30,
      kkm: 75,
      soal: const [],
      statusPublikasi: status,
    );
