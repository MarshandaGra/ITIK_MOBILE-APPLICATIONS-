import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itik_mobile/models/materi.dart';
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('materi keeps the original PDF filename returned by the API', () async {
    SharedPreferences.setMockInitialValues({});
    const originalName = 'Materi Algoritma.pdf';
    final api = ApiClient(
      client: MockClient((request) async {
        expect(request.body, contains('filename="$originalName"'));
        return http.Response(
          jsonEncode({
            'data': {
              'id_materi': 'M001',
              'judul': 'Algoritma',
              'isi_materi': 'materi/hashed-name.pdf',
              'nama_file_pdf': originalName,
              'pdf_name': 'Algoritma.pdf',
              'pdf_url': 'https://example.test/storage/materi/hashed-name.pdf',
            },
          }),
          201,
        );
      }),
    );
    final app = AppProvider(apiClient: api);
    addTearDown(app.dispose);

    await app.tambahMateri(
      Materi(
        id: '',
        bab: '',
        judul: 'Algoritma',
        kelas: 'X TKJ 1',
        deskripsi: '',
        isi: '',
        pdfName: '',
        ukuran: '',
        oleh: '',
        tanggal: '',
      ),
      pdfBytes: Uint8List.fromList(utf8.encode('%PDF-1.4')),
      pdfName: originalName,
    );

    expect(app.materiList.single.pdfName, originalName);
  });
}
