import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/providers/a11y_provider.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/siswa/materi_detail_screen.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('siswa memuat pratinjau melalui endpoint siswa terautentikasi',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    http.Request? pdfRequest;
    final api = ApiClient(
      client: MockClient((request) async {
        pdfRequest = request;
        return http.Response(
          '{"message":"File PDF materi tidak ditemukan."}',
          404,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..token = 'student-token';
    final app = AppProvider(apiClient: api);
    app.materiList.add(
      Materi(
        id: 'M001',
        bab: 'Bab 1',
        judul: 'Algoritma',
        kelas: 'X TKJ',
        deskripsi: 'Pengenalan algoritma.',
        isi: '',
        pdfName: 'Materi Algoritma.pdf',
        pdfUrl: 'https://example.test/storage/materi/hashed-name.pdf',
        ukuran: '',
        oleh: 'Guru',
        tanggal: '',
      ),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: app),
          ChangeNotifierProvider(create: (_) => A11yProvider()),
        ],
        child: const MaterialApp(
          home: MateriDetailScreen(materiId: 'M001'),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Buka Pratinjau PDF'));
    await tester.tap(find.text('Buka Pratinjau PDF'));
    await tester.pumpAndSettle();

    expect(pdfRequest?.url.path, endsWith('/api/siswa/materi/M001/pdf'));
    expect(pdfRequest?.headers['authorization'], 'Bearer student-token');
    expect(pdfRequest?.headers['accept'], 'application/pdf');
    expect(find.text('Pratinjau Materi'), findsOneWidget);
    expect(find.text('Materi Algoritma.pdf'), findsOneWidget);
    expect(find.text('Gagal memuat PDF: File PDF materi tidak ditemukan.'),
        findsOneWidget);
  });
}
