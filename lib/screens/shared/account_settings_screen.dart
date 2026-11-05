import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController identifierCtrl;
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser!;
    identifierCtrl = TextEditingController(text: user.induk ?? '');
  }

  @override
  void dispose() {
    identifierCtrl.dispose();
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ---------------- Foto profil ----------------

  Future<void> _pilihFoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return; // dibatalkan
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      context.read<AppProvider>().updateFoto(bytes);
      showAppToast(context, 'Foto profil berhasil diperbarui');
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'Gagal mengambil foto. Coba lagi.');
    }
  }

  Future<void> _hapusFoto() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Foto Profil?'),
        content: const Text('Foto profil saat ini akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    context.read<AppProvider>().updateFoto(null);
    showAppToast(context, 'Foto profil dihapus');
  }

  void _tampilkanPilihanFoto(bool adaFoto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.blue),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pilihFoto(ImageSource.gallery);
                },
              ),
              // Kamera tidak tersedia di web.
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded,
                      color: AppColors.blue),
                  title: const Text('Ambil dengan Kamera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pilihFoto(ImageSource.camera);
                  },
                ),
              if (adaFoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.red),
                  title: const Text('Hapus Foto Profil',
                      style: TextStyle(color: AppColors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _hapusFoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Simpan akun ----------------

  void _simpan() {
    final err = context.read<AppProvider>().updateAccount(
          identifier: identifierCtrl.text,
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
    final user = context.watch<AppProvider>().currentUser!;
    final identifierLabel = user.role == UserRole.siswa ? 'NISN' : 'NIP';
    final color = RoleColors.of(user.role.value);
    final adaFoto = user.foto != null;

    return Scaffold(
      appBar: simpleAppBar('Pengaturan Akun'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // ---------- Foto Profil ----------
            Center(
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    label: 'Ganti foto profil',
                    child: GestureDetector(
                      onTap: () => _tampilkanPilihanFoto(adaFoto),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: color,
                            backgroundImage:
                                adaFoto ? MemoryImage(user.foto!) : null,
                            child: adaFoto
                                ? null
                                : Text(
                                    user.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.photo_camera_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _tampilkanPilihanFoto(adaFoto),
                    child: const Text('Ganti Foto Profil'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ---------- NISN / NIP ----------
            Text(
              'Ubah $identifierLabel',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: identifierCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  InputDecoration(hintText: 'Masukkan $identifierLabel baru'),
            ),
            const SizedBox(height: 18),

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
