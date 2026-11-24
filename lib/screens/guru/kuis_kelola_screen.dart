import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/kuis.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_form_screen.dart';
import 'kuis_detail_screen.dart';

class KuisKelolaScreen extends StatefulWidget {
  const KuisKelolaScreen({super.key});

  @override
  State<KuisKelolaScreen> createState() => _KuisKelolaScreenState();
}

enum _StatusFilter { semua, terbit, draft }

class _KuisKelolaScreenState extends State<KuisKelolaScreen> {
  static const _semuaKategori = 'Semua';
  String _kategoriFilter = _semuaKategori;
  _StatusFilter _statusFilter = _StatusFilter.semua;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final list = app.kuisList;
    final subject = app.currentUser?.mataPelajaran ?? MataPelajaranGuru.tik;
    final subjectLabel = subject == MataPelajaranGuru.tik
        ? 'Teknologi Informasi dan Komunikasi (TIK)'
        : subject;
    final subjectCode =
        subject == MataPelajaranGuru.bahasaIndonesia ? 'MP002' : 'MP001';
    final kategoriKuisOptions =
        list.map((kuis) => kuis.kategori).toSet().toList()..sort();
    final kuisKategori = list
        .where((kuis) =>
            _kategoriFilter == _semuaKategori ||
            kuis.kategori == _kategoriFilter)
        .toList();
    final kuisTerfilter = kuisKategori.where((kuis) {
      final cocokStatus = switch (_statusFilter) {
        _StatusFilter.semua => true,
        _StatusFilter.terbit => kuis.isPublished,
        _StatusFilter.draft => !kuis.isPublished,
      };
      return cocokStatus;
    }).toList();
    final groupedList = <String, List<Kuis>>{};
    for (final kuis in kuisTerfilter) {
      final materi = app.materiById(kuis.materiId);
      final groupName = materi == null
          ? 'Belum terkait materi'
          : '${materi.bab} — ${materi.judul}';
      groupedList.putIfAbsent(groupName, () => []).add(kuis);
    }

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
            const Text(
              'Kuis & Soal',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kelola kuis mata pelajaran: $subjectLabel',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 18),
            _SubjectSummaryBanner(
              subject: subjectLabel,
              quizCount: list.length,
              code: subjectCode,
            ),
            const SizedBox(height: 16),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EDF3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _kategoriFilter,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _kategoriFilter = value);
                    }
                  },
                  selectedItemBuilder: (context) => [
                    const _FilterLabel(value: _semuaKategori),
                    ...kategoriKuisOptions
                        .map((value) => _FilterLabel(value: value)),
                  ],
                  items: [
                    const DropdownMenuItem(
                        value: _semuaKategori, child: Text(_semuaKategori)),
                    ...kategoriKuisOptions.map((value) =>
                        DropdownMenuItem(value: value, child: Text(value))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusFilterChip(
                  label: 'Semua',
                  count: kuisKategori.length,
                  selected: _statusFilter == _StatusFilter.semua,
                  selectedColor: AppColors.blue,
                  backgroundColor: AppColors.blueLight,
                  foregroundColor: AppColors.blue,
                  onSelected: () =>
                      setState(() => _statusFilter = _StatusFilter.semua),
                ),
                _StatusFilterChip(
                  label: 'Terbit',
                  count: kuisKategori.where((kuis) => kuis.isPublished).length,
                  selected: _statusFilter == _StatusFilter.terbit,
                  selectedColor: AppColors.green,
                  backgroundColor: AppColors.greenLight,
                  foregroundColor: AppColors.green,
                  onSelected: () =>
                      setState(() => _statusFilter = _StatusFilter.terbit),
                ),
                _StatusFilterChip(
                  label: 'Draft',
                  count: kuisKategori.where((kuis) => !kuis.isPublished).length,
                  selected: _statusFilter == _StatusFilter.draft,
                  selectedColor: AppColors.red,
                  backgroundColor: AppColors.redLight,
                  foregroundColor: AppColors.red,
                  onSelected: () =>
                      setState(() => _statusFilter = _StatusFilter.draft),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionTitle('Kuis (${kuisTerfilter.length})'),
            if (kuisTerfilter.isEmpty)
              const EmptyState(
                  text:
                      'Belum ada kuis yang dibuat.\nTekan tombol di bawah untuk membuat kuis pertama.')
            else
              ...groupedList.entries.expand((entry) => [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          AppPill(
                            label: '${entry.value.length} kuis',
                            color: AppColors.purple,
                            background: AppColors.purpleLight,
                          ),
                        ],
                      ),
                    ),
                    ...entry.value.map(
                      (kuis) => _KuisManageCard(kuis: kuis, app: app),
                    ),
                  ]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const KuisFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Tambahkan Kuis'),
      ),
    );
  }
}

class _SubjectSummaryBanner extends StatelessWidget {
  final String subject;
  final int quizCount;
  final String code;

  const _SubjectSummaryBanner({
    required this.subject,
    required this.quizCount,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7057F5), Color(0xFF5B43E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$quizCount kuis tersedia • Kode: $code',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.menu_book_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color selectedColor;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.selectedColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: selectedColor,
      backgroundColor: backgroundColor,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : foregroundColor,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String value;
  const _FilterLabel({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sell_outlined, size: 15, color: AppColors.blue),
        const SizedBox(width: 7),
        const Text('Kategori: ', style: TextStyle(fontSize: 13)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _KuisManageCard extends StatelessWidget {
  final Kuis kuis;
  final AppProvider app;
  const _KuisManageCard({required this.kuis, required this.app});

  Future<void> _hapus(BuildContext context) async {
    final ok = await confirmDialog(context,
        'Arsipkan kuis "${kuis.judul}"? Kuis tidak akan terlihat oleh siswa.');
    if (ok) {
      try {
        await app.hapusKuis(kuis.id);
        if (context.mounted) {
          showAppToast(context, 'Kuis berhasil diarsipkan.');
        }
      } catch (error) {
        if (context.mounted) {
          showAppToast(context, 'Gagal mengarsipkan kuis: $error');
        }
      }
    }
  }

  Future<void> _ubahStatus(BuildContext context) async {
    if (kuis.isPublished) {
      showAppToast(
          context, 'Kuis yang sudah terbit tidak dapat dijadikan draft.');
      return;
    }
    if (kuis.soal.isEmpty) {
      showAppToast(
          context, 'Tambahkan minimal satu soal sebelum menerbitkan kuis');
      return;
    }
    try {
      await app.publishKuis(kuis.id);
      if (context.mounted) {
        showAppToast(context, 'Kuis berhasil diterbitkan.');
      }
    } catch (error) {
      if (context.mounted) {
        showAppToast(context, 'Gagal menerbitkan kuis: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = kuis;
    final m = app.materiById(k.materiId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.orangeLight,
                    borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.quiz_rounded,
                    color: AppColors.orange, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(k.judul,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5))),
                        LevelPill(level: k.level),
                      ]),
                      const SizedBox(height: 2),
                      AppPill(
                        label: k.isPublished ? 'Terbit' : 'Draft',
                        color: k.isPublished ? AppColors.green : AppColors.red,
                        background: k.isPublished
                            ? AppColors.greenLight
                            : AppColors.redLight,
                      ),
                      const SizedBox(height: 6),
                      Text(
                          m != null
                              ? '${m.bab} — ${m.judul}'
                              : 'Belum terkait materi',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        Text('${k.jumlahSoal} soal',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                        Text('KKM ${k.kkm}',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                        Text('${k.waktu} menit',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                        Text(k.kategori,
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                        Text('oleh ${k.oleh}',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                      ]),
                    ]),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _ubahStatus(context),
                icon: Icon(
                    k.isPublished
                        ? Icons.unpublished_outlined
                        : Icons.publish_outlined,
                    size: 16),
                label: Text(k.isPublished ? 'Jadikan Draft' : 'Terbitkan Kuis',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => KuisDetailScreen(kuisId: k.id))),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Soal', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: k.statusPublikasi == 'draft'
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => KuisFormScreen(kuisId: k.id)))
                      : null,
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
