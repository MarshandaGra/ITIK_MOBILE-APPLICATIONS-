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

  testWidgets('Tambah Soal Berikutnya menyimpan pilihan ganda dan mereset form',
      (tester) async {
    final app = AppProvider();
    final kuis = app.kuisList.first;
    final jumlahSoalAwal = kuis.soal.length;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(home: SoalFormScreen(kuisId: kuis.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Pertanyaan baru');
    await tester.enterText(find.byType(TextField).at(1), 'Opsi A');
    await tester.enterText(find.byType(TextField).at(2), 'Opsi B');
    await tester.tap(find.text('Tambah Soal Berikutnya'));
    await tester.pumpAndSettle();

    expect(kuis.soal, hasLength(jumlahSoalAwal + 1));
    expect(kuis.soal.last.pertanyaan, 'Pertanyaan baru');
    expect(find.text('Tambah Soal'), findsOneWidget);
    expect(tester.takeException(), isNull);
    app.dispose();
  });

  testWidgets('Selesai menyimpan esai terakhir dan kembali', (tester) async {
    final app = AppProvider();
    final kuis = app.kuisList.first;
    final jumlahSoalAwal = kuis.soal.length;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(home: SoalFormScreen(kuisId: kuis.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(Soal.esai));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Pertanyaan esai');
    await tester.enterText(find.byType(TextField).at(1), 'Kunci jawaban');
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(kuis.soal, hasLength(jumlahSoalAwal + 1));
    expect(kuis.soal.last.jenis, Soal.esai);
    expect(kuis.soal.last.jawabanEsai, 'Kunci jawaban');
    expect(find.text('Tambah Soal'), findsNothing);
    expect(tester.takeException(), isNull);
    app.dispose();
  });
}
