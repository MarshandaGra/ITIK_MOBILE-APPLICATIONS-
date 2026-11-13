import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../widgets/shared_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ---------------- Simpan akun ----------------

  void _simpan() {
    final err = context.read<AppProvider>().updateAccount(
          passwordSaatIni: currentPasswordCtrl.text,
          passwordBaru: newPasswordCtrl.text,
          konfirmasiPassword: confirmPasswordCtrl.text,
        );
    if (err != null) {
      showAppToast(context, err);
      return;
    }

    currentPasswordCtrl.clear();
    newPasswordCtrl.clear();
    confirmPasswordCtrl.clear();
    showAppToast(context, 'Pengaturan akun berhasil disimpan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar('Pengaturan Akun'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // ---------- Kata sandi ----------
            const Text(
              'Ubah Kata Sandi',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Kata sandi saat ini'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  hintText: 'Kata sandi baru (minimal 6 karakter)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Konfirmasi kata sandi baru'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _simpan,
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}
