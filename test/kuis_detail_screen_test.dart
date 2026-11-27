import 'dart:convert' show jsonEncode, utf8;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:itik_mobile/providers/app_provider.dart';
import 'package:itik_mobile/screens/guru/kuis_detail_screen.dart';
import 'package:itik_mobile/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('detail soal esai menampilkan label tanpa daftar pilihan',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider(
      apiClient: ApiClient(
        client: _DetailClient((request) async {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'data': {
                    'id_kuis': 'K1',
                    'judul': 'Kuis Esai',
                    'kategori': 'kuis harian',
                    'status_publikasi': 'draft',
                    'alokasi_waktu': 30,
                    'kkm': 75,
                    'soal': [
                      {
                        'id_soal': 'S1',
                        'tipe_soal': 'esai',
                        'pertanyaan': 'Jelaskan konsepnya.',
                        'opsi_a': 'Pilihan A',
                        'opsi_b': 'Pilihan B',
                        'opsi_c': null,
                        'opsi_d': null,
                        'opsi_e': null,
                        'jawaban': 'A',
                        'bobot': 100,
                      },
                    ],
                  },
                }),
              ),
            ),
            200,
            request: request,
          );
        }),
      ),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: app,
        child: const MaterialApp(home: KuisDetailScreen(kuisId: 'K1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Soal 1 • Bobot: 100.00%'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Soal 1 • Bobot: 100.00%'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Esai'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Esai'), findsOneWidget);
    expect(find.text('Pertanyaan bertipe esai'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.startsWith('A. ') == true,
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

class _DetailClient extends http.BaseClient {
  _DetailClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handler(request);

  @override
  void close() {}
}
