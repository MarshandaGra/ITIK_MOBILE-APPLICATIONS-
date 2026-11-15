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
    final confirmed = await confirmDialog(
        context, 'Arsipkan kuis "${quiz.judul}"? Kuis tidak akan terlihat oleh siswa.');
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
      if (mounted) showAppToast(context, 'Soal berhasil dihapus.');
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal menghapus soal: $error');
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
                        _loading =
                            context.read<AppProvider>().loadKuisDetail(widget.kuisId);
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
      appBar: simpleAppBar('Detail Kuis'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz.judul,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    '${quiz.kategori} • ${quiz.statusPublikasi} • ${quiz.level}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${materi?.judul ?? 'Tanpa materi terkait'} • ${quiz.jumlahSoal} soal • ${quiz.waktu} menit • KKM ${quiz.kkm}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total bobot soal: ${quiz.soal.fold<double>(0, (total, question) => total + question.bobot).toStringAsFixed(2)}%',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted),
                  ),
                  if (quiz.deskripsi.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(quiz.deskripsi),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isDraft)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    KuisFormScreen(kuisId: quiz.id)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Kuis'),
                        ),
                      if (isDraft)
                        FilledButton.icon(
                          onPressed: () => _publish(app, quiz),
                          icon: const Icon(Icons.publish_outlined, size: 16),
                          label: const Text('Publikasikan'),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red),
                        onPressed: () => _hapusKuis(app, quiz),
                        icon: const Icon(Icons.archive_outlined, size: 16),
                        label: const Text('Arsipkan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle('Daftar Soal (${quiz.soal.length})'),
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
                        Text('Soal ${index + 1} • Bobot ${question.bobot}%',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 6),
                        Text(question.pertanyaan,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.5)),
                        const SizedBox(height: 8),
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
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SoalFormScreen(
                                          kuisId: quiz.id, index: index),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 16),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.red),
                                  onPressed: () =>
                                      _hapusSoal(app, quiz, index),
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SoalFormScreen(kuisId: quiz.id)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Soal'),
            )
          : null,
    );
  }
}
