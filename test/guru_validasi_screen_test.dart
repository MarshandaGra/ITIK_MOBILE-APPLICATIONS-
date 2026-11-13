import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
