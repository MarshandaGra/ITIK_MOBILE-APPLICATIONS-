import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/materi.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'materi_form_screen.dart';
import 'materi_view_screen.dart';

class MateriKelolaScreen extends StatelessWidget {
  const MateriKelolaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final list = app.materiList;
    final subject =
        app.currentUser?.mataPelajaran ?? 'Teknologi Informasi dan Komunikasi';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            const Text(
              'PORTAL GURU',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subject,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${list.length} materi pembelajaran tersedia untuk mata pelajaran ini.',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 18),
            SectionTitle('Materi Pembelajaran (${list.length})'),
            if (list.isEmpty)
              const EmptyState(
                  text:
                      'Belum ada materi yang diunggah.\nTekan tombol di bawah untuk menambahkan.')
            else
              ...list.indexed.map(
                (entry) => _MateriManageCard(
                  materi: entry.$2,
                  app: app,
                  index: entry.$1 + 1,
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'ITIK · Portal Guru — Media Pembelajaran TIK',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MateriFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Tambahkan Materi'),
      ),
    );
  }
}

class _MateriManageCard extends StatelessWidget {
  final Materi materi;
  final AppProvider app;
  final int index;
  const _MateriManageCard({
    required this.materi,
    required this.app,
    required this.index,
  });

  Future<void> _hapus(BuildContext context) async {
    final ok = await confirmDialog(context,
        'Hapus "${materi.judul}"?\n\nTindakan ini tidak dapat dibatalkan.');
    if (ok) {
      try {
        await app.hapusMateri(materi.id);
        if (context.mounted) showAppToast(context, 'Materi telah dihapus');
      } catch (error) {
        if (context.mounted) {
          showAppToast(context, 'Gagal menghapus materi: $error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = materi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m.bab} — ${m.judul}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(m.deskripsi,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (m.bab.isNotEmpty) m.bab,
                          if (m.kelas.isNotEmpty) 'Kelas ${m.kelas}',
                          if (m.pdfName.isNotEmpty) 'PDF: ${m.pdfName}',
                        ].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.muted),
                      ),
                    ]),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MateriViewScreen(materiId: m.id))),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Lihat', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MateriFormScreen(materiId: m.id))),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.redLight)),
                  onPressed: () => _hapus(context),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
