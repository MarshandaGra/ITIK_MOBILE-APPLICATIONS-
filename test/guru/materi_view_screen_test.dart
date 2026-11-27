import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/materi_view_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('detail materi menampilkan informasi dari materi yang dipilih',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider()
      ..materiList.add(
        Materi(
          id: 'materi-1',
          bab: 'Bab 4',
          judul: 'Pengolahan Data',
          kelas: 'X TKJ',
          deskripsi: 'Pengolahan data dan rumus sederhana.',
          isi: '',
          mataPelajaran: 'Teknologi Informasi dan Komunikasi (TIK)',
          pdfName: 'pengolahan-data.pdf',
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
          home: MateriViewScreen(materiId: 'materi-1'),
        ),
      ),
    );

    expect(find.text('Informasi Materi'), findsOneWidget);
    expect(
      find.text('Teknologi Informasi dan Komunikasi (TIK)'),
      findsOneWidget,
    );
    expect(find.text('Bab 4'), findsOneWidget);
    expect(find.text('Kelas X TKJ'), findsOneWidget);
    expect(find.text('Pengolahan data dan rumus sederhana.'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Pratinjau Materi'), findsOneWidget);
    expect(find.text('Informasi Materi'), findsOneWidget);
    expect(find.text('Isi Dokumen Materi'), findsOneWidget);
    expect(find.text('File PDF belum tersedia.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Informasi Materi')).dy,
      lessThan(tester.getTopLeft(find.text('Isi Dokumen Materi')).dy),
    );
  });
}
