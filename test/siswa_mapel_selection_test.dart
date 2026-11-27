import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itik_mobile/models/hasil_kuis.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/models/kuis.dart';
import 'package:itik_mobile/models/user.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/siswa/kuis_level_screen.dart';
import 'package:itik_mobile/screens/siswa/siswa_materi_screen.dart';
import 'package:itik_mobile/screens/siswa/siswa_nilai_screen.dart';
import 'package:itik_mobile/widgets/shared_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('materi dimulai dari mapel dan hanya menampilkan materi terpilih',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    app.materiList.addAll([
      Materi(
        id: 'M001',
        bab: 'Bab 1',
        judul: 'Perangkat Komputer',
        kelas: '',
        deskripsi: '',
        isi: '',
        idMapel: 'MP001',
        mataPelajaran: 'Informatika',
        pdfName: 'perangkat.pdf',
        ukuran: '',
        oleh: '',
        tanggal: '',
      ),
      Materi(
        id: 'M002',
        bab: 'Bab 1',
        judul: 'Pengolah Kata',
        kelas: '',
        deskripsi: '',
        isi: '',
        idMapel: 'MP002',
        mataPelajaran: 'Teknologi',
        pdfName: 'pengolah-kata.pdf',
        ukuran: '',
        oleh: '',
        tanggal: '',
      ),
    ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: SiswaMateriScreen()),
      ),
    );

    expect(find.text('Informatika'), findsOneWidget);
    expect(find.text('Teknologi'), findsOneWidget);
    expect(find.text('Bab 1 — Perangkat Komputer'), findsNothing);
    expect(tester.getSize(find.byType(SubjectSelectionCard).first).height, 210);

    await tester.tap(find.text('Informatika'));
    await tester.pumpAndSettle();

    expect(find.text('1 materi pembelajaran tersedia'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Pilih mata pelajaran lain')).dy,
      lessThan(
        tester.getTopLeft(find.text('1 materi pembelajaran tersedia')).dy,
      ),
    );
    expect(find.text('Perangkat Komputer'), findsOneWidget);
    expect(find.text('Pengolah Kata'), findsNothing);

    final mapelBackAlignments = tester.widgetList<Align>(
      find.ancestor(
        of: find.text('Pilih mata pelajaran lain'),
        matching: find.byType(Align),
      ),
    );
    expect(
      mapelBackAlignments
          .any((align) => align.alignment == Alignment.centerRight),
      isTrue,
    );
    final mapelBackButton = find.ancestor(
      of: find.text('Pilih mata pelajaran lain'),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.getSize(mapelBackButton.first).width, lessThan(200));
    expect(
      tester
          .widgetList<Icon>(
            find.descendant(
              of: mapelBackButton.first,
              matching: find.byType(Icon),
            ),
          )
          .first
          .icon,
      Icons.arrow_back_rounded,
    );

    await tester.tap(find.text('Pilih mata pelajaran lain'));
    await tester.pumpAndSettle();
    expect(find.text('Teknologi'), findsOneWidget);
  });

  testWidgets('kuis dipilih berdasarkan mata pelajaran', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = AppProvider();
    app.materiList.addAll([
      Materi(
        id: 'M001',
        bab: 'Bab 1',
        judul: 'Perangkat Komputer',
        kelas: '',
        deskripsi: 'Pengenalan hardware dan software.',
        isi: '',
        idMapel: 'MP001',
        pdfName: '',
        ukuran: '',
        oleh: '',
        tanggal: '',
      ),
      Materi(
        id: 'M002',
        bab: 'Bab 1',
        judul: 'Pengolah Kata',
        kelas: '',
        deskripsi: '',
        isi: '',
        idMapel: 'MP002',
        pdfName: '',
        ukuran: '',
        oleh: '',
        tanggal: '',
      ),
    ]);
    app.kuisList.addAll([
      _kuis('K001', 'Kuis Komputer', 'MP001', 'Informatika', materiId: 'M001'),
      _kuis('K002', 'Kuis Digital', 'MP002', 'Teknologi', materiId: 'M002'),
    ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: KuisLevelScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Informatika'), findsOneWidget);
    expect(find.text('Teknologi'), findsOneWidget);
    expect(find.text('Kuis Komputer'), findsNothing);
    final nilaiButton = find.text('Lihat Nilai Saya');
    final nilaiButtonAlignments = tester.widgetList<Align>(
      find.ancestor(
        of: nilaiButton,
        matching: find.byType(Align),
      ),
    );
    expect(
      nilaiButtonAlignments
          .any((align) => align.alignment == Alignment.centerRight),
      isTrue,
    );
    final nilaiOutline = find.ancestor(
      of: nilaiButton,
      matching: find.byType(OutlinedButton),
    );
    expect(
      tester
          .widgetList<Icon>(
            find.descendant(
              of: nilaiOutline.first,
              matching: find.byType(Icon),
            ),
          )
          .first
          .icon,
      Icons.arrow_forward_rounded,
    );
    final subjectCard = tester
        .widget<SubjectSelectionCard>(find.byType(SubjectSelectionCard).first);
    expect(subjectCard.icon, Icons.quiz_rounded);
    expect(tester.getSize(find.byType(SubjectSelectionCard).first).height, 210);

    await tester.tap(find.text('Informatika'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pilih Bab Materi'), findsOneWidget);
    expect(find.text('Perangkat Komputer'), findsOneWidget);
    expect(find.text('Kuis Komputer'), findsNothing);
    final quizMapelBack = find.ancestor(
      of: find.text('Pilih mata pelajaran lain'),
      matching: find.byType(OutlinedButton),
    );
    expect(
      tester.getTopLeft(quizMapelBack.first).dy,
      lessThan(tester.getTopLeft(find.text('Informatika').last).dy),
    );
    expect(
      tester.getSize(quizMapelBack.first).height,
      tester.getSize(nilaiOutline.first).height,
    );
    final mapelBackRect = tester.getRect(quizMapelBack.first);
    final nilaiRect = tester.getRect(nilaiOutline.first);
    expect(mapelBackRect.center.dy, closeTo(nilaiRect.center.dy, 0.5));
    expect(mapelBackRect.right, lessThan(nilaiRect.left));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Pilih mata pelajaran lain'));
    await tester.pumpAndSettle();
    expect(find.text('Teknologi'), findsOneWidget);
    await tester.tap(find.text('Informatika'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Bab Materi'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Buka Bab Ini →'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Bab Ini →').first);
    await tester.pumpAndSettle();

    expect(find.text('Kuis Komputer'), findsOneWidget);
    expect(find.text('Kuis Digital'), findsNothing);
    expect(find.text('Mulai Kuis'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('KKM'), findsOneWidget);
  });

  testWidgets('nilai dipilih berdasarkan mata pelajaran', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    final student = AppUser(
      id: 'S001',
      nama: 'Siswa',
      email: '',
      password: '',
      role: UserRole.siswa,
    );
    app.hasilList.addAll([
      _hasil('N001', 'Kuis Komputer', 'MP001', 'Informatika'),
      _hasil('N002', 'Kuis Digital', 'MP002', 'Teknologi'),
    ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: SiswaNilaiScreen()),
      ),
    );
    app.currentUser = student;
    app.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.text('Informatika'), findsOneWidget);
    expect(find.text('Teknologi'), findsOneWidget);
    expect(find.text('Kuis Komputer'), findsNothing);

    await tester.tap(find.text('Informatika'));
    await tester.pumpAndSettle();

    expect(find.text('Kuis Komputer'), findsOneWidget);
    expect(find.text('Kuis Digital'), findsNothing);

    final mapelBackButton = find.ancestor(
      of: find.text('Pilih mata pelajaran lain'),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.getSize(mapelBackButton.first).width, lessThan(200));
    expect(find.text('1 hasil kuis tersedia'), findsOneWidget);
    expect(
      tester.getTopLeft(mapelBackButton.first).dy,
      lessThan(
        tester.getTopLeft(find.text('1 hasil kuis tersedia')).dy,
      ),
    );
    await tester.tap(find.text('Pilih mata pelajaran lain'));
    await tester.pumpAndSettle();
    expect(find.text('Teknologi'), findsOneWidget);
  });

  testWidgets('daftar kuis dapat digulir turun lalu kembali ke atas',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = AppProvider();
    app.materiList.addAll(
      List.generate(
        20,
        (index) => Materi(
          id: 'M${(index + 1).toString().padLeft(3, '0')}',
          bab: 'Bab ${index + 1}',
          judul: 'Materi ${index + 1}',
          kelas: '',
          deskripsi: '',
          isi: '',
          idMapel: 'MP001',
          mataPelajaran: 'Informatika',
          pdfName: '',
          ukuran: '',
          oleh: '',
          tanggal: '',
        ),
      ),
    );
    app.kuisList.addAll(
      List.generate(
        30,
        (index) => _kuis(
          'K${(index + 1).toString().padLeft(3, '0')}',
          'Kuis ${index + 1}',
          'MP001',
          'Informatika',
          materiId: 'M020',
        ),
      ),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: KuisLevelScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Informatika'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Materi 20'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Materi 20'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Materi 1'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Materi 1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Materi 20'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Materi 20'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Kuis 30'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kuis 30'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kuis 1'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Kuis 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Kuis _kuis(
  String id,
  String judul,
  String idMapel,
  String namaMapel, {
  String materiId = '',
}) =>
    Kuis(
      id: id,
      judul: judul,
      materiId: materiId,
      level: 'mudah',
      oleh: 'Guru',
      tanggal: '',
      waktu: 10,
      kkm: 70,
      soal: const [],
      idMapel: idMapel,
      namaMapel: namaMapel,
      soalCount: 1,
    );

HasilKuis _hasil(
  String id,
  String judul,
  String idMapel,
  String namaMapel,
) =>
    HasilKuis(
      id: id,
      siswaId: 'S001',
      siswa: 'Siswa',
      kuisId: id,
      kuis: judul,
      idMapel: idMapel,
      namaMapel: namaMapel,
      level: 'mudah',
      nilai: 80,
      kkm: 70,
      durasi: null,
      benar: 1,
      jawabanSiswa: const [],
      totalSoal: 1,
      tanggal: '2025-01-01',
    );
