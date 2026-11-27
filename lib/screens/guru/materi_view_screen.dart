import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../shared/materi_pdf_preview_screen.dart';
import 'materi_form_screen.dart';

class MateriViewScreen extends StatelessWidget {
  const MateriViewScreen({super.key, required this.materiId});

  final String materiId;

  @override
  Widget build(BuildContext context) {
    final materi = context.watch<AppProvider>().materiById(materiId);
    if (materi == null) {
      return const Scaffold(
        body: Center(child: Text('Materi tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: simpleAppBar('Detail Materi'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              materi.judul,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            MateriInformationCard(materi: materi),
            const SizedBox(height: 16),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.red,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      materi.pdfName.isEmpty
                          ? 'PDF belum tersedia.'
                          : materi.pdfName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MateriPdfPreviewScreen(
                          materi: materi,
                          pdfEndpoint:
                              '/guru/materi/${Uri.encodeComponent(materi.id)}/pdf',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                    label: const Text('Buka PDF'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MateriFormScreen(materiId: materi.id),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Edit Materi'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    materi.deskripsi.isEmpty
                        ? 'Tidak ada deskripsi.'
                        : materi.deskripsi,
                    style: const TextStyle(
                      height: 1.6,
                      color: AppColors.muted,
                    ),
                  ),
                  if (materi.isi.isNotEmpty &&
                      !materi.isi.toLowerCase().endsWith('.pdf')) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Isi Materi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      materi.isi,
                      style: const TextStyle(
                        height: 1.6,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  if (materi.linkYoutube?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => openExternalUrl(
                        context,
                        materi.linkYoutube,
                        contentName: 'video YouTube',
                      ),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Buka video pembelajaran'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
