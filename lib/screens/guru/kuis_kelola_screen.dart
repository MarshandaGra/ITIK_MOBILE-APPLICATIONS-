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
  bool _showQuizList = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    if (!_showQuizList) {
      return _buildSubjectOverview(context, app);
    }

    final kuisKategori = app.kuisGuruSaatIni
        .where((kuis) =>
            _kategoriFilter == _semuaKategori ||
            kuis.kategori == _kategoriFilter)
        .toList()
        .reversed
        .toList();
    final list = kuisKategori.where((kuis) {
      switch (_statusFilter) {
        case _StatusFilter.semua:
          return true;
        case _StatusFilter.terbit:
          return kuis.isPublished;
        case _StatusFilter.draft:
          return !kuis.isPublished;
      }
    }).toList();
    final statusLabel =
        _statusFilter == _StatusFilter.terbit ? 'Terbit' : 'Draft';
    final statusEmptyMessage = _kategoriFilter == _semuaKategori
        ? 'Belum ada kuis berstatus $statusLabel.'
        : 'Belum ada kuis berstatus $statusLabel untuk kategori $_kategoriFilter.';
    final groupedList = <String, List<Kuis>>{};
    for (final kuis in list) {
      final materi = app.materiById(kuis.materiId);
      final bab =
          materi == null ? 'Materi lainnya' : '${materi.bab} - ${materi.judul}';
      groupedList.putIfAbsent(bab, () => []).add(kuis);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'PORTAL GURU',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showQuizList = false),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Mata Pelajaran'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Kuis & Soal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola kuis mata pelajaran: ${app.currentUser?.mataPelajaran ?? 'TIK'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            _SubjectSummaryBanner(
              subject: app.currentUser?.mataPelajaran ?? 'TIK',
              quizCount: app.kuisGuruSaatIni.length,
              code: app.currentUser?.mataPelajaran == 'Bahasa Indonesia'
                  ? 'MP002'
                  : 'MP001',
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 10),
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
            SectionTitle('Kuis (${list.length})'),
            if (list.isEmpty)
              EmptyState(
                  text: _statusFilter != _StatusFilter.semua
                      ? statusEmptyMessage
                      : _kategoriFilter == _semuaKategori
                          ? 'Belum ada kuis yang dibuat.\nTekan tombol di bawah untuk membuat kuis pertama.'
                          : 'Belum ada kuis kategori $_kategoriFilter.')
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

  Widget _buildSubjectOverview(BuildContext context, AppProvider app) {
    final mataPelajaranGuru =
        app.currentUser?.mataPelajaran ?? MataPelajaranGuru.tik;
    final mataPelajaran = [mataPelajaranGuru];

    Widget kartuMataPelajaran(String nama) {
      final kode =
          nama == MataPelajaranGuru.bahasaIndonesia ? 'MP002' : 'MP001';
      final label = nama == MataPelajaranGuru.tik
          ? 'Teknologi Informasi dan Komunikasi'
          : nama;
      final kuisAktif = app.kuisList.where((kuis) {
        final materi = app.materiById(kuis.materiId);
        return materi?.mataPelajaran == nama && kuis.isPublished;
      }).length;

      return _SubjectCard(
        title: label,
        code: kode,
        activeQuizCount: kuisAktif,
        onTap: () {
          if (nama != mataPelajaranGuru) {
            showAppToast(
              context,
              'Akun guru ini hanya dapat mengelola $mataPelajaranGuru',
            );
            return;
          }
          setState(() => _showQuizList = true);
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
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
            const SizedBox(height: 32),
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
            const Text(
              'Pilih mata pelajaran untuk mengelola kuis dan soal.',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Mata Pelajaran',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Klik mata pelajaran untuk mengelola kuis dan soal di dalamnya.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = mataPelajaran
                          .map(kartuMataPelajaran)
                          .toList(growable: false);
                      if (constraints.maxWidth >= 700) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var index = 0;
                                index < cards.length;
                                index++) ...[
                              if (index > 0) const SizedBox(width: 16),
                              Expanded(child: cards[index]),
                            ],
                          ],
                        );
                      }
                      return Column(
                        children: [
                          for (var index = 0;
                              index < cards.length;
                              index++) ...[
                            SizedBox(
                              width: double.infinity,
                              child: cards[index],
                            ),
                            if (index < cards.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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

class _SubjectCard extends StatelessWidget {
  final String title;
  final String code;
  final int activeQuizCount;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.title,
    required this.code,
    required this.activeQuizCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.purple,
              size: 21,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            code,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$activeQuizCount kuis aktif',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              const Text(
                'Kelola',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.purple,
                size: 15,
              ),
            ],
          ),
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
        'Hapus "${kuis.judul}" beserta ${kuis.soal.length} soal di dalamnya?\n\nTindakan ini tidak dapat dibatalkan.');
    if (ok) {
      app.hapusKuis(kuis.id);
      if (context.mounted) showAppToast(context, 'Kuis telah dihapus');
    }
  }

  void _ubahStatus(BuildContext context) {
    if (!kuis.isPublished && kuis.soal.isEmpty) {
      showAppToast(
          context, 'Tambahkan minimal satu soal sebelum menerbitkan kuis');
      return;
    }
    app.setKuisPublished(kuis.id, !kuis.isPublished);
    showAppToast(context,
        kuis.isPublished ? 'Kuis diterbitkan' : 'Kuis dipindahkan ke draft');
  }

  @override
  Widget build(BuildContext context) {
    final k = kuis;
    final m = app.materiById(k.materiId);
    final adaGambar = k.soal.where((s) => s.gambar != null).length;

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
                      const SizedBox(height: 5),
                      AppPill(
                        label: k.isPublished ? 'Terbit' : 'Draft',
                        color:
                            k.isPublished ? AppColors.green : AppColors.orange,
                        background: k.isPublished
                            ? AppColors.greenLight
                            : AppColors.orangeLight,
                      ),
                      const SizedBox(height: 2),
                      Text(
                          m != null
                              ? '${m.bab} — ${m.judul}'
                              : 'Belum terkait materi',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        AppPill(
                          label: k.kategori ?? 'Tanpa kategori',
                          color: AppColors.purple,
                          background: AppColors.purpleLight,
                        ),
                        Text('${k.soal.length} soal',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                        Text('KKM ${k.kkm}',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                        Text('${k.waktu} menit',
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.muted)),
                        if (adaGambar > 0)
                          Text('🖼 $adaGambar bergambar',
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
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => KuisFormScreen(kuisId: k.id))),
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
