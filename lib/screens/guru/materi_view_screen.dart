import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/materi.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'materi_form_screen.dart';

class MateriViewScreen extends StatelessWidget {
  final String materiId;
  const MateriViewScreen({super.key, required this.materiId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final m = app.materiById(materiId);
    if (m == null) {
      return const Scaffold(
          body: Center(child: Text('Materi tidak ditemukan')));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
            const SizedBox(height: 18),
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Kembali'),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MateriFormScreen(materiId: m.id),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Materi'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              m.judul,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${m.bab} • Kelas ${m.kelas}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isiMateri = Column(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Isi & Dokumen Pembelajaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pratinjau dokumen materi siswa.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.purpleLight.withValues(
                                alpha: .28,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: AppColors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.pdfName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (m.ukuran.isNotEmpty)
                                        Text(
                                          m.ukuran,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 140),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              m.isi,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _MateriFullScreenPage(materi: m),
                                ),
                              ),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 17,
                              ),
                              label: const Text('Buka Pratinjau Penuh'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if ((m.youtubeUrl ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Video Pembelajaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              m.youtubeUrl!,
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );

                final informasi = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Informasi Materi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          AppPill(
                            label: 'Kelas ${m.kelas}',
                            color: AppColors.purple,
                            background: AppColors.purpleLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MateriInfo(
                          label: 'Mata Pelajaran',
                          value: m.mataPelajaran ?? '-'),
                      const SizedBox(height: 12),
                      _MateriInfo(label: 'Bab', value: m.bab),
                      const SizedBox(height: 12),
                      _MateriInfo(label: 'Kelas', value: m.kelas),
                      const Divider(height: 24),
                      const Text(
                        'Deskripsi Materi',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.deskripsi.isEmpty
                            ? 'Belum ada deskripsi.'
                            : m.deskripsi,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                );

                if (constraints.maxWidth >= 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: isiMateri),
                      const SizedBox(width: 16),
                      Expanded(child: informasi),
                    ],
                  );
                }
                return Column(
                  children: [
                    isiMateri,
                    const SizedBox(height: 14),
                    informasi,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'ITIK · Portal Guru — Media Pembelajaran TIK',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _MateriInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MateriInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MateriFullScreenPage extends StatelessWidget {
  final Materi materi;
  const _MateriFullScreenPage({required this.materi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(materi.judul),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                materi.bab,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                materi.judul,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${materi.pdfName}${materi.ukuran.isNotEmpty ? ' • ${materi.ukuran}' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              if (materi.gambar != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(kRadius),
                  child: Image.memory(
                    materi.gambar!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            color: AppColors.red, size: 22),
                        SizedBox(width: 8),
                        Text('Preview materi',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      materi.isi,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.muted,
                      ),
                    ),
                    if (materi.deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Deskripsi',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        materi.deskripsi,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.7,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
