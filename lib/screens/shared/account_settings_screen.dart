import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
  final currentPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _saving = false;
  bool _photoLoading = false;

  @override
  void dispose() {
    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ---------------- Foto profil ----------------

  // Future<void> _pilihFoto(ImageSource source) async {
  //   if (_photoLoading) return;
  //   try {
  //     final picked = await _picker.pickImage(
  //       source: source,
  //       maxWidth: 800,
  //       maxHeight: 800,
  //       imageQuality: 80,
  //     );
  //     if (picked == null) return; // dibatalkan
  //     final bytes = await picked.readAsBytes();
  //     if (!mounted) return;
  //     setState(() => _photoLoading = true);
  //     await context
  //         .read<AppProvider>()
  //         .updateFoto(bytes, fileName: picked.name);
  //     if (mounted) showAppToast(context, 'Foto profil berhasil diperbarui');
  //   } catch (error) {
  //     if (mounted) showAppToast(context, 'Gagal memperbarui foto: $error');
  //   } finally {
  //     if (mounted) setState(() => _photoLoading = false);
  //   }
  // }

  // Future<void> _hapusFoto() async {
  //   if (_photoLoading) return;
  //   final yakin = await showDialog<bool>(
  //     context: context,
  //     builder: (dialogContext) => AlertDialog(
  //       title: const Text('Hapus Foto Profil?'),
  //       content: const Text('Foto profil saat ini akan dihapus.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(dialogContext, false),
  //           child: const Text('Batal'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(dialogContext, true),
  //           style: TextButton.styleFrom(foregroundColor: AppColors.red),
  //           child: const Text('Hapus'),
  //         ),
  //       ],
  //     ),
  //   );
  //   if (yakin != true || !mounted) return;

  //   setState(() => _photoLoading = true);
  //   try {
  //     await context.read<AppProvider>().updateFoto(null);
  //     if (mounted) showAppToast(context, 'Foto profil dihapus');
  //   } catch (error) {
  //     if (mounted) showAppToast(context, 'Gagal menghapus foto: $error');
  //   } finally {
  //     if (mounted) setState(() => _photoLoading = false);
  //   }
  // }

  // void _tampilkanPilihanFoto(bool adaFoto) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (ctx) => SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 12),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Container(
  //               width: 40,
  //               height: 4,
  //               margin: const EdgeInsets.only(bottom: 8),
  //               decoration: BoxDecoration(
  //                 color: AppColors.border,
  //                 borderRadius: BorderRadius.circular(2),
  //               ),
  //             ),
  //             ListTile(
  //               leading: const Icon(Icons.photo_library_rounded,
  //                   color: AppColors.blue),
  //               title: const Text('Pilih dari Galeri'),
  //               onTap: () {
  //                 Navigator.pop(ctx);
  //                 _pilihFoto(ImageSource.gallery);
  //               },
  //             ),
  //             // Kamera tidak tersedia di web.
  //             if (!kIsWeb)
  //               ListTile(
  //                 leading: const Icon(Icons.photo_camera_rounded,
  //                     color: AppColors.blue),
  //                 title: const Text('Ambil dengan Kamera'),
  //                 onTap: () {
  //                   Navigator.pop(ctx);
  //                   _pilihFoto(ImageSource.camera);
  //                 },
  //               ),
  //             if (adaFoto)
  //               ListTile(
  //                 leading: const Icon(Icons.delete_outline_rounded,
  //                     color: AppColors.red),
  //                 title: const Text('Hapus Foto Profil',
  //                     style: TextStyle(color: AppColors.red)),
  //                 onTap: () {
  //                   Navigator.pop(ctx);
  //                   _hapusFoto();
  //                 },
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ---------------- Simpan akun ----------------

  Future<void> _simpan() async {
    if (_saving) return;
    final currentPassword = currentPasswordCtrl.text;
    final newPassword = newPasswordCtrl.text;
    final confirmation = confirmPasswordCtrl.text;
    if (currentPassword.isEmpty && newPassword.isEmpty && confirmation.isEmpty) {
      showAppToast(context, 'Isi kolom password jika ingin mengubahnya.');
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AppProvider>().updatePassword(
            passwordSaatIni: currentPassword,
            passwordBaru: newPassword,
            konfirmasiPassword: confirmation,
          );
      if (!mounted) return;
      currentPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmPasswordCtrl.clear();
      showAppToast(context, 'Password berhasil diperbarui');
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal memperbarui password: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser!;
    final color = RoleColors.of(user.role.value);
    final adaFoto = user.foto != null || user.fotoUrl != null;
    final ImageProvider<Object>? fotoProvider = user.foto != null
        ? MemoryImage(user.foto!) as ImageProvider<Object>
        : user.fotoUrl != null
            ? NetworkImage(user.fotoUrl!) as ImageProvider<Object>
            : null;

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
                      // onTap: () => _tampilkanPilihanFoto(adaFoto),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: color,
                            backgroundImage: fotoProvider,
                            child: fotoProvider != null
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
                          // Positioned(
                          //   right: 0,
                          //   bottom: 0,
                          //   child: Container(
                          //     width: 32,
                          //     height: 32,
                          //     decoration: BoxDecoration(
                          //       color: AppColors.blue,
                          //       shape: BoxShape.circle,
                          //       border:
                          //           Border.all(color: Colors.white, width: 2),
                          //     ),
                          //     child: _photoLoading
                          //         ? const Padding(
                          //             padding: EdgeInsets.all(8),
                          //             child: CircularProgressIndicator(
                          //               strokeWidth: 2,
                          //               color: Colors.white,
                          //             ),
                          //           )
                          //         : const Icon(Icons.photo_camera_rounded,
                          //             color: Colors.white, size: 16),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
            //       const SizedBox(height: 8),
            //       TextButton(
            //         onPressed: () => _tampilkanPilihanFoto(adaFoto),
            //         child: const Text('Ganti Foto Profil'),
            //       ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // ---------- Kata sandi ----------
            const Text(
              'Ubah Kata Sandi',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              enabled: !_saving,
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Kata sandi saat ini'),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !_saving,
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  hintText: 'Kata sandi baru (minimal 6 karakter)'),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !_saving,
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Konfirmasi kata sandi baru'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _simpan,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan Password'),
            ),
          ],
        ),
      ),
    );
  }
}
