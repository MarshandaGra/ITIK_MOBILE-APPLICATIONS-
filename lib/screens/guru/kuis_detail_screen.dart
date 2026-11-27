import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kuis.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_form_screen.dart';
import 'soal_form_screen.dart';

class KuisDetailScreen extends StatefulWidget {
  final String kuisId;

  const KuisDetailScreen({super.key, required this.kuisId});

  @override
  State<KuisDetailScreen> createState() => _KuisDetailScreenState();
}

class _KuisDetailScreenState extends State<KuisDetailScreen> {
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = context.read<AppProvider>().loadKuisDetail(widget.kuisId);
  }

  Future<void> _hapusKuis(AppProvider app, Kuis quiz) async {
    final confirmed = await confirmDialog(context,
        'Arsipkan kuis "${quiz.judul}"? Kuis tidak akan terlihat oleh siswa.');
    if (!confirmed || !mounted) return;
    try {
      await app.hapusKuis(quiz.id);
      if (!mounted) return;
      Navigator.pop(context);
      showAppToast(context, 'Kuis berhasil diarsipkan.');
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal mengarsipkan kuis: $error');
    }
  }

  Future<void> _hapusSoal(AppProvider app, Kuis quiz, int index) async {
    final confirmed = await confirmDialog(
        context, 'Hapus soal nomor ${index + 1} dari kuis ini?');
    if (!confirmed || !mounted) return;
    try {
      await app.hapusSoal(quiz.id, index);
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal menghapus soal: $error');
      return;
    }
    if (!mounted) return;
    showAppToast(context, 'Soal berhasil dihapus.');
    try {
      await app.loadKuisDetail(quiz.id);
    } catch (error) {
      if (mounted) {
        showAppToast(context, 'Bobot soal terbaru gagal dimuat: $error');
      }
    }
  }

  Future<void> _bukaFormSoal({int? index}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SoalFormScreen(kuisId: widget.kuisId, index: index),
      ),
    );
    if (!mounted) return;
    try {
      await context.read<AppProvider>().loadKuisDetail(widget.kuisId);
    } catch (error) {
      if (mounted) {
        showAppToast(context, 'Bobot soal terbaru gagal dimuat: $error');
      }
    }
  }

  Future<void> _publish(AppProvider app, Kuis quiz) async {
    try {
      await app.publishKuis(quiz.id);
      if (mounted) showAppToast(context, 'Kuis berhasil dipublikasikan.');
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal mempublikasikan kuis: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: simpleAppBar('Detail Kuis'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: simpleAppBar('Detail Kuis'),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Gagal memuat detail kuis: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _loading = context
                            .read<AppProvider>()
                            .loadKuisDetail(widget.kuisId);
                      }),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final quiz = app.kuisById(widget.kuisId);
        if (quiz == null) {
          return Scaffold(
            appBar: simpleAppBar('Detail Kuis'),
            body: const Center(child: Text('Kuis tidak ditemukan.')),
          );
        }

        return _buildQuiz(context, app, quiz);
      },
    );
  }

  Widget _buildQuiz(BuildContext context, AppProvider app, Kuis quiz) {
    final materi = app.materiById(quiz.materiId);
    final isDraft = quiz.statusPublikasi == 'draft';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Kembali'),
                ),
                if (isDraft)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KuisFormScreen(kuisId: quiz.id),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Kuis'),
                  ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('Kelola Kuis'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              quiz.judul,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Detail kuis, jadwal, daftar butir soal, dan publikasi.',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            if (quiz.isPublished) ...[
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: AppColors.green, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Kuis telah diterbitkan',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Informasi Kuis',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                      AppPill(
                        label: isDraft ? 'Draft' : 'Terbit',
                        color: isDraft ? AppColors.orange : AppColors.green,
                        background: isDraft
                            ? AppColors.orangeLight
                            : AppColors.greenLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ringkasan konfigurasi dan parameter pengerjaan.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tileWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _InfoTile(
                            width: tileWidth,
                            label: 'Mata Pelajaran',
                            value: materi?.mataPelajaran ?? '-',
                          ),
                          _InfoTile(
                            width: tileWidth,
                            label: 'Kategori',
                            value: quiz.kategori.isEmpty ? '-' : quiz.kategori,
                          ),
                          _InfoTile(
                            width: tileWidth,
                            label: 'Tingkat Kesulitan',
                            value: quiz.level,
                          ),
                          _InfoTile(
                            width: tileWidth,
                            label: 'KKM',
                            value: '${quiz.kkm}',
                          ),
                          _InfoTile(
                            width: tileWidth,
                            label: 'Alokasi Waktu',
                            value: '${quiz.waktu} Menit',
                          ),
                          _InfoTile(
                            width: tileWidth,
                            label: 'Tahun Ajaran',
                            value: quiz.tahunAjaran ?? '-',
                          ),
                        ],
                      );
                    },
                  ),
                  if (quiz.deskripsi.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(quiz.deskripsi),
                  ],
                  if (isDraft) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.red),
                        onPressed: () => _hapusKuis(app, quiz),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Hapus Kuis'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _publish(app, quiz),
                        icon: const Icon(Icons.publish_outlined, size: 16),
                        label: const Text('Terbitkan Kuis'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (materi != null) ...[
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Materi Terkait',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text(
                      'Bab pembelajaran yang dicakup oleh kuis ini.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.purpleLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book_rounded,
                              color: AppColors.purple, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            materi.judul,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          materi.bab,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SectionTitle('Butir Soal (${quiz.soal.length})'),
            const Text(
              'Pratinjau butir pertanyaan dalam kuis ini.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            if (quiz.soal.isEmpty)
              const EmptyState(text: 'Belum ada soal pada kuis ini.')
            else
              ...List.generate(quiz.soal.length, (index) {
                final question = quiz.soal[index];
                const letters = ['A', 'B', 'C', 'D', 'E'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Soal ${index + 1} • Bobot: ${question.bobot.toStringAsFixed(2)}%',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        AppPill(
                          label: question.jenis == Soal.esai
                              ? 'Esai'
                              : 'Pilihan Ganda',
                          color: question.jenis == Soal.esai
                              ? AppColors.purple
                              : AppColors.blue,
                          background: question.jenis == Soal.esai
                              ? AppColors.purpleLight
                              : AppColors.blueLight,
                        ),
                        const SizedBox(height: 6),
                        Text(question.pertanyaan,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.5)),
                        if (question.gambar != null ||
                            question.gambarUrl != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: question.gambar != null
                                ? Image.memory(
                                    question.gambar!,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.contain,
                                  )
                                : Image.network(
                                    question.gambarUrl!,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, error, ___) {
                                      debugPrint(
                                        'Gagal memuat gambar soal '
                                        '${question.gambarUrl}: $error',
                                      );
                                      return const SizedBox(
                                        height: 100,
                                        child: Center(
                                          child: Text(
                                            'Gambar gagal dimuat. Periksa URL dan akses storage publik.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (question.jenis == Soal.esai)
                          const Text(
                            'Pertanyaan bertipe esai',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          ...List.generate(question.opsi.length, (optionIndex) {
                            final isAnswer = optionIndex == question.jawaban;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${letters[optionIndex]}. ${question.opsi[optionIndex]}${isAnswer ? '  ✓' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAnswer
                                      ? AppColors.green
                                      : AppColors.text,
                                  fontWeight: isAnswer
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }),
                        if (isDraft) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _bukaFormSoal(index: index),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.red),
                                  onPressed: () => _hapusSoal(app, quiz, index),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16),
                                  label: const Text('Hapus'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: isDraft
          ? FloatingActionButton.extended(
              onPressed: _bukaFormSoal,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Soal'),
            )
          : null,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _InfoTile({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purpleLight.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
