import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itik_mobile/main.dart';
import 'package:itik_mobile/providers/app_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('aplikasi dimulai tanpa data contoh', (tester) async {
    await tester.pumpWidget(const EdukasiTikApp());
    await tester.pumpAndSettle();

    expect(find.text('NISN / NIP'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Ryo Febriyansah'), findsNothing);
    expect(find.text('Sari Dewi, S.Pd'), findsNothing);

    final app = Provider.of<AppProvider>(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    expect(app.users, isEmpty);
    expect(app.materiList, isEmpty);
    expect(app.kuisList, isEmpty);
    expect(app.hasilList, isEmpty);
  });
}
