import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itik_mobile/models/kuis.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/siswa/kuis_result_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'hanya menampilkan pilihan siswa jika jawabannya berbeda dari kunci',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          home: KuisResultScreen(
            kuis: Kuis(
              id: 'K001',
              judul: 'Kuis Perangkat Komputer',
              materiId: '',
              level: 'mudah',
              oleh: 'Guru',
              tanggal: '',
              waktu: 10,
              kkm: 75,
              soal: [
                Soal(
                  pertanyaan: 'Perangkat keras yang menjadi otak komputer?',
                  opsi: const ['RAM', 'CPU', 'Monitor', 'Keyboard'],
                  jawaban: 1,
                ),
                Soal(
                  pertanyaan: 'Alat untuk menampilkan hasil visual?',
                  opsi: const ['Printer', 'Speaker', 'Monitor', 'Mouse'],
                  jawaban: 2,
                ),
              ],
            ),
            nilai: 0,
            benar: 1,
            salah: 1,
            jawabanSiswa: const [2, 2],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Evaluasi Soal'), findsOneWidget);
    expect(find.text('Soal #1 (Bobot: 100%)'), findsOneWidget);
    expect(find.text('Soal #2 (Bobot: 100%)'), findsOneWidget);
    expect(find.text('Perangkat keras yang menjadi otak komputer?'),
        findsOneWidget);
    expect(find.text('Alat untuk menampilkan hasil visual?'), findsOneWidget);
    expect(find.text('Kunci Jawaban'), findsNWidgets(2));
    expect(find.text('Pilihan Kamu'), findsOneWidget);
  });
}
