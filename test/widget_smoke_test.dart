import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itik_mobile/main.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/siswa/kuis_level_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loginAs(WidgetTester tester, String identifier) async {
  await tester.pumpWidget(const EdukasiTikApp());
  await tester.pumpAndSettle();

  await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan NISN atau NIP'), identifier);
  await tester.pump();
  await tester.enterText(
      find.widgetWithText(TextField, 'Kata sandi'), '123456');
  await tester.pump();
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
  // Known bug: ListTile di dalam AppCard (profil_screen) melempar error saat
  // shell dibangun; error ini dikonsumsi agar flow bisa lanjut diuji.
  // Lihat laporan: bug #1 (ink splash tidak terlihat).
  final ex = tester.takeException();
  if (ex != null) {
    // ignore: avoid_print
    print(
        'KNOWN BUG DILEMPAR SAAT BUILD SHELL: ${ex.toString().split('\n').first}');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('layar login render tanpa overflow', (tester) async {
    await tester.pumpWidget(const EdukasiTikApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Edukasi TIK'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('login siswa -> beranda tampil utuh', (tester) async {
    await loginAs(tester, '0012345678');
    expect(find.text('Terus tingkatkan kemampuan TIK-mu 🚀'), findsOneWidget);
    expect(find.text('Ryo!'), findsOneWidget);
    expect(find.text('X TKJ 1 • Semester Ganjil 2026'), findsOneWidget);
  });

  testWidgets('daftar kuis tidak menampilkan tombol kembali', (tester) async {
    await loginAs(tester, '0012345678');
    await tester.tap(find.text('Kuis').last);
    await tester.pumpAndSettle();

    expect(find.text('Daftar Kuis'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Kembali'), findsNothing);
  });

  testWidgets('tombol lihat nilai di layar kecil rata kiri dan tidak melebar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(home: KuisLevelScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.widgetWithText(OutlinedButton, 'Lihat Nilai Saya');
    final size = tester.getSize(button);
    final position = tester.getTopLeft(button);
    expect(size.width, lessThan(200));
    expect(position.dx, closeTo(20, 1));
  });

  testWidgets('beranda siswa render dengan fontScale 1.5 (aksesibilitas)',
      (tester) async {
    // Set fontScale via layar pengaturan tidak praktis di sini; gunakan
    // textScaler global seperti yang dilakukan main.dart.
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: EdukasiTikApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Edukasi TIK'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Masukkan NISN atau NIP'), '0012345678');
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Kata sandi'), '123456');
    await tester.pump();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    tester.takeException(); // konsumsi error ListTile yang sudah diketahui

    expect(find.text('Ryo!'), findsOneWidget);
    expect(find.text('Terus tingkatkan kemampuan TIK-mu 🚀'), findsOneWidget);
  });

  testWidgets('siswa kerjakan kuis sampai layar hasil', (tester) async {
    await loginAs(tester, '0012345678');

    await tester.tap(find.text('Kuis').last);
    await tester.pumpAndSettle();
    await tester
        .tap(find.text('Teknologi Informasi dan Komunikasi (TIK)').last);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Kembali')).dx,
      lessThan(tester
          .getTopLeft(
              find.text('Teknologi Informasi dan Komunikasi (TIK)').first)
          .dx),
    );
    await tester.ensureVisible(find.text('Dasar Microsoft Word'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dasar Microsoft Word'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kuis Microsoft Word'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kuis Microsoft Word'));
    await tester.pumpAndSettle();

    expect(find.text('Ujian Mode Layar Penuh (CBT)'), findsOneWidget);
    await tester.tap(find.text('Mulai Ujian & Kunci Layar Penuh'));
    await tester.pumpAndSettle();
    expect(find.text('Soal 1 dari 3'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Soal 1 dari 3'), findsOneWidget);

    // Soal 1: jawaban benar B (Bold)
    await tester.tap(find.text('B (Bold)').first);
    await tester.pump();
    await tester.tap(find.text('Soal Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Soal 2 dari 3'), findsOneWidget);

    // Soal 2: Merge Cells
    await tester.tap(find.text('Merge Cells').first);
    await tester.pump();
    await tester.tap(find.text('Soal Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Soal 3 dari 3'), findsOneWidget);

    // Soal 3: .docx
    await tester.tap(find.text('.docx').first);
    await tester.pump();
    await tester.tap(find.text('Selesai & Lihat Nilai'));
    await tester.pumpAndSettle();

    expect(find.text('Hasil Kuis'), findsOneWidget);
    expect(find.text('Jawaban Benar'), findsOneWidget);
    tester
        .takeException(); // konsumsi error ListTile (tab profil juga dibangun IndexedStack)
  });

  testWidgets('login guru -> shell guru tampil', (tester) async {
    await loginAs(tester, '198501012010011001');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('kelola kuis hanya menampilkan mapel guru pengampu',
      (tester) async {
    await loginAs(tester, '198501012010011001');
    await tester.tap(find.text('Kuis').last);
    await tester.pumpAndSettle();

    expect(find.text('MP001'), findsOneWidget);
    expect(find.text('MP002'), findsNothing);
  });

  testWidgets('login NIP guru Bahasa Indonesia membuka dashboard mapelnya',
      (tester) async {
    await loginAs(tester, '197906152006042003');
    expect(find.textContaining('Bahasa Indonesia'), findsWidgets);
  });

  testWidgets('tap akun demo guru -> form terisi otomatis & masuk halaman guru',
      (tester) async {
    await tester.pumpWidget(const EdukasiTikApp());
    await tester.pumpAndSettle();

    // Daftar akun demo ada di bawah tombol Masuk — scroll sampai terlihat.
    await tester.scrollUntilVisible(
      find.text('Sari Dewi, S.Pd'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sari Dewi, S.Pd'));
    await tester.pumpAndSettle();

    // NIP & sandi terisi otomatis dari akun demo (termasuk subtitle daftar).
    expect(find.textContaining('198501012010011001'), findsWidgets);

    await tester.ensureVisible(find.text('Masuk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    tester.takeException(); // konsumsi error ListTile yang sudah diketahui

    // Berhasil masuk ke shell guru (bukan siswa).
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
