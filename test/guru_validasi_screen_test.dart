import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itik_mobile/models/hasil_kuis.dart';
import 'package:itik_mobile/models/kelas_guru.dart';
import 'package:itik_mobile/models/user.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/guru_validasi_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 'U2',
      'user_role': 'guru',
    });
  });

  Future<AppProvider> createApp() async {
    final app = AppProvider();
    await app.restoreSession();
    return app;
  }

  testWidgets('tabel nilai tampil pada layar lebar', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = await createApp();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: GuruValidasiScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Nilai Siswa'), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kelas master tampil walau belum memiliki hasil nilai',
      (tester) async {
    final app = await createApp();
    app.kelasGuruList.add(
      const KelasGuru(
        id: 'KLS003',
        namaKelas: 'TKJ 3',
        tingkat: 'X',
        totalSiswa: 0,
        totalMateri: 0,
        kuisAktif: 0,
        jumlahNilai: 0,
        rataNilai: null,
      ),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: GuruValidasiScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('X TKJ 3'), findsOneWidget);
    expect(find.text('Kuis Aktif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter kategori dan percobaan membatasi daftar nilai',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = await createApp();
    app.currentUser = AppUser(
      id: 'G001',
      nama: 'Guru',
      email: '',
      password: '',
      role: UserRole.guru,
    );
    app.hasilList.addAll([
      _hasil(id: '1', kategori: 'kuis harian', percobaan: 1, nilai: 65),
      _hasil(id: '2', kategori: 'ulangan', percobaan: 2, nilai: 85),
    ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: GuruValidasiScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Menampilkan 2 dari 2 data pengerjaan kuis siswa'),
      findsOneWidget,
    );

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Kuis Harian'), findsOneWidget);
    expect(find.text('Ulangan'), findsOneWidget);
    expect(find.text('Remedial'), findsWidgets);
    await tester.tap(find.text('Kuis Harian'));
    await tester.pumpAndSettle();
    expect(
      find.text('Menampilkan 1 dari 2 data pengerjaan kuis siswa'),
      findsOneWidget,
    );

    await tester.tap(find.byType(PopupMenuButton<String>).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Ke-0'), findsNothing);
    for (var attempt = 1; attempt <= 10; attempt++) {
      expect(find.text('Ke-$attempt'), findsWidgets);
    }
    await tester.tap(find.text('Ke-1').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Menampilkan 1 dari 2 data pengerjaan kuis siswa'),
      findsOneWidget,
    );
    expect(find.text('Ke-1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filter-kelulusan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lulus'));
    await tester.pumpAndSettle();
    expect(
      find.text('Menampilkan 0 dari 2 data pengerjaan kuis siswa'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('filter-kelulusan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak Lulus'));
    await tester.pumpAndSettle();
    expect(
      find.text('Menampilkan 1 dari 2 data pengerjaan kuis siswa'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter tanggal membuka pemilih dan memfilter tanggal dipilih',
      (tester) async {
    final app = await createApp();
    app.currentUser = AppUser(
      id: 'G001',
      nama: 'Guru',
      email: '',
      password: '',
      role: UserRole.guru,
    );
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    app.hasilList.addAll([
      _hasil(
        id: 'today',
        kategori: 'kuis harian',
        percobaan: 1,
        tanggal: _dateString(today),
      ),
      _hasil(
        id: 'yesterday',
        kategori: 'ulangan',
        percobaan: 1,
        tanggal: _dateString(yesterday),
      ),
    ]);
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: GuruValidasiScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('Semua'), findsWidgets);
    await tester.tap(find.text('Pilih tanggal...'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byType(CalendarDatePicker),
            matching: find.text('${today.day}'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.text('Menampilkan 1 dari 2 data pengerjaan kuis siswa'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail hasil menampilkan evaluasi jawaban di ponsel',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = await createApp();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: GuruValidasiScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (var attempt = 0;
        attempt < 5 && find.text('Lihat Detail').evaluate().isEmpty;
        attempt++) {
      await tester.drag(
        find.byType(ListView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Lihat Detail'), findsWidgets);
    final detailButton = find.text('Lihat Detail').first;
    await tester.ensureVisible(detailButton);
    await tester.pumpAndSettle();
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('Detail Nilai Siswa'), findsOneWidget);
    expect(find.text('Data Siswa'), findsOneWidget);
    expect(find.text('Jawaban Benar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

HasilKuis _hasil({
  required String id,
  required String kategori,
  required int percobaan,
  double nilai = 80,
  String? tanggal,
}) =>
    HasilKuis(
      id: id,
      siswaId: 'S$id',
      siswa: 'Siswa $id',
      kuisId: 'K$id',
      kuis: 'Kuis $id',
      kategori: kategori,
      percobaanKe: percobaan,
      level: 'Mudah',
      nilai: nilai,
      kkm: 70,
      durasi: null,
      benar: 0,
      jawabanSiswa: const [],
      tanggal: tanggal ?? '2026-11-25',
    );

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
