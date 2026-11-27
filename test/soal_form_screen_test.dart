import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itik_mobile/models/kuis.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/soal_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'form soal menampilkan tipe dan tidak menampilkan tingkat kesulitan',
      (tester) async {
    final app = AppProvider()
      ..kuisList.add(
        Kuis(
          id: 'kuis-1',
          judul: 'Kuis',
          materiId: 'materi-1',
          level: 'Mudah',
          oleh: 'Guru',
          tanggal: '2026-11-18',
          waktu: 30,
          kkm: 75,
          soal: const [],
        ),
      );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
          home: SoalFormScreen(kuisId: 'kuis-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilihan Jawaban'), findsOneWidget);
    expect(
      find.text(
          'Opsi A–D wajib diisi, opsi E opsional. Ketuk huruf opsi untuk memilih jawaban benar.'),
      findsOneWidget,
    );
    expect(find.text('Bobot Otomatis'), findsNothing);
    expect(find.text('100.00%'), findsNothing);
    expect(find.text('Tingkat Kesulitan'), findsNothing);
    expect(find.text('Jenis Soal *'), findsOneWidget);
    expect(find.text('Pilihan Ganda'), findsOneWidget);
    expect(find.text('Esai'), findsOneWidget);
    expect(find.text('Gambar Soal (opsional)'), findsOneWidget);
    final questionTop =
        tester.getTopLeft(find.text('Pertanyaan / Butir Soal *')).dy;
    final imageTop = tester.getTopLeft(find.text('Gambar Soal (opsional)')).dy;
    final typeTop = tester.getTopLeft(find.text('Jenis Soal *')).dy;
    final optionsTop = tester.getTopLeft(find.text('Pilihan Jawaban')).dy;
    expect(questionTop < imageTop, isTrue);
    expect(imageTop < typeTop, isTrue);
    expect(typeTop < optionsTop, isTrue);
    expect(find.byType(TextFormField), findsNWidgets(6));
  });

  testWidgets('memilih tipe esai menyembunyikan pilihan jawaban',
      (tester) async {
    final app = AppProvider()
      ..kuisList.add(
        Kuis(
          id: 'kuis-essay',
          judul: 'Kuis Esai',
          materiId: 'materi-1',
          level: 'Mudah',
          oleh: 'Guru',
          tanggal: '2026-11-18',
          waktu: 30,
          kkm: 75,
          soal: const [],
        ),
      );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
          home: SoalFormScreen(kuisId: 'kuis-essay'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esai'));
    await tester.pumpAndSettle();

    expect(find.text('Pilihan Jawaban'), findsNothing);
    expect(find.text('Jawaban siswa untuk soal esai akan dinilai oleh guru.'),
        findsOneWidget);
    expect(find.text('Bobot Otomatis'), findsNothing);
  });

  testWidgets('esai tidak tersedia untuk pre-test', (tester) async {
    final app = AppProvider()
      ..kuisList.add(
        Kuis(
          id: 'kuis-pre',
          judul: 'Pre-test',
          materiId: 'materi-1',
          level: 'Mudah',
          oleh: 'Guru',
          tanggal: '2026-11-18',
          waktu: 30,
          kkm: 75,
          kategori: 'pre-test',
          soal: const [],
        ),
      );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(
          home: SoalFormScreen(kuisId: 'kuis-pre'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Kategori pre-test dan post-test hanya mendukung pilihan ganda.'),
      findsOneWidget,
    );
  });
}
