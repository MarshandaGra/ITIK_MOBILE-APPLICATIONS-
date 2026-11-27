import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hasil_kuis.dart';
import '../../models/kuis.dart';
import '../../models/materi.dart';
import '../../models/mapel_option.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_play_screen.dart';
import 'siswa_nilai_screen.dart';

class KuisLevelScreen extends StatefulWidget {
  const KuisLevelScreen({super.key});

  @override
  State<KuisLevelScreen> createState() => _KuisLevelScreenState();
}

class _KuisLevelScreenState extends State<KuisLevelScreen> {
  String? _startingKuisId;
  String? _selectedMapelId;
  String? _selectedMateriId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppProvider>().loadKuisData();
    });
  }

  Future<void> _mulaiKuis(AppProvider app, String kuisId) async {
    if (_startingKuisId != null) return;
    setState(() => _startingKuisId = kuisId);
    try {
      final kuis = await app.mulaiKuisSiswa(kuisId);
      if (!mounted) return;
      if (kuis.soal.isEmpty) {
        showAppToast(context, 'Kuis ini belum memiliki soal.');
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KuisPlayScreen(kuis: kuis, serverManaged: true),
        ),
      );
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal membuka kuis: $error');
    } finally {
      if (mounted) setState(() => _startingKuisId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final riwayat = app.riwayatSiswaSaatIni;
    final counts = <String, int>{};
    for (final kuis in app.kuisList) {
      final idMapel = _mapelIdForKuis(app, kuis);
      if (idMapel != null && idMapel.isNotEmpty) {
        counts.update(idMapel, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final mapelOptions = app.siswaMapelOptions
        .where((mapel) => (counts[mapel.id] ?? 0) > 0)
        .toList();
    MapelOption? selectedMapel;
    for (final mapel in mapelOptions) {
      if (mapel.id == _selectedMapelId) {
        selectedMapel = mapel;
        break;
      }
    }
    final selectedMapelValue = selectedMapel;
    final visibleKuis = selectedMapelValue == null
        ? const <Kuis>[]
        : app.kuisList
            .where(
                (kuis) => _mapelIdForKuis(app, kuis) == selectedMapelValue.id)
            .toList();
    final visibleMateri = selectedMapelValue == null
        ? const <Materi>[]
        : app.materiList
            .where((materi) => materi.idMapel == selectedMapelValue.id)
            .toList();
    Materi? selectedMateri;
    for (final materi in visibleMateri) {
      if (materi.id == _selectedMateriId) {
        selectedMateri = materi;
        break;
      }
    }
    final selectedMateriValue = selectedMateri;
    final selectedMateriKuis = selectedMateriValue == null
        ? const <Kuis>[]
        : visibleKuis
            .where((kuis) => kuis.materiId == selectedMateriValue.id)
            .toList();
    final kuisTanpaMateri = visibleKuis.where((kuis) {
      final materi = app.materiById(kuis.materiId);
      return materi == null || materi.idMapel != selectedMapelValue?.id;
    }).toList();

    return Scaffold(
      appBar: simpleAppBar('Daftar Kuis'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.loadKuisData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Text(
                'Pilih kuis pembelajaran yang tersedia dan selesaikan tantangannya.',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              if (selectedMapelValue == null) ...[
                _lihatNilaiButton(),
                const SizedBox(height: 12),
              ],
              if (app.kuisLoadError != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kuis gagal dimuat.'),
                      const SizedBox(height: 8),
                      Text(
                        app.kuisLoadError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            app.kuisLoading ? null : () => app.loadKuisData(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              if (app.kuisLoading && app.kuisList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (!app.kuisLoading &&
                  app.kuisLoadError == null &&
                  app.kuisList.isEmpty)
                const AppCard(
                  child: Text(
                    'Belum ada kuis yang diterbitkan guru. Kuis draft belum tampil untuk siswa.',
                  ),
                ),
              if (!app.kuisLoading &&
                  app.kuisList.isNotEmpty &&
                  selectedMapel == null)
                MapelSelectionList(
                  mapelOptions: mapelOptions,
                  counts: counts,
                  itemLabel: 'kuis',
                  icon: Icons.quiz_rounded,
                  iconColor: AppColors.purple,
                  iconBackground: AppColors.purpleLight,
                  detailBuilder: (mapel, count) {
                    final materiCount = app.materiList
                        .where((materi) => materi.idMapel == mapel.id)
                        .length;
                    return '$materiCount Materi • $count Kuis';
                  },
                  onSelect: (mapel) => setState(() {
                    _selectedMapelId = mapel.id;
                    _selectedMateriId = null;
                  }),
                ),
              if (selectedMapel != null) ...[
                _buildBreadcrumb(selectedMapel, selectedMateriValue),
                const SizedBox(height: 10),
                SubjectSummaryBanner(
                  title: selectedMapel.nama,
                  detail: selectedMateriValue == null
                      ? '${visibleMateri.length} bab materi • ${visibleKuis.length} kuis tersedia'
                      : '${selectedMateriValue.bab} • ${selectedMateriKuis.length} kuis tersedia',
                ),
                const SizedBox(height: 18),
                if (selectedMateriValue == null)
                  ..._buildMaterialPicker(
                    app,
                    visibleMateri,
                    visibleKuis,
                    kuisTanpaMateri,
                    riwayat,
                  )
                else
                  ..._buildQuizDetails(
                    app,
                    selectedMateriValue,
                    selectedMateriKuis,
                    riwayat,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(MapelOption mapel, Materi? materi) {
    if (materi != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _materiBreadcrumb(mapel, materi),
          Align(
            alignment: Alignment.centerRight,
            child: _lihatNilaiButton(compact: true),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: MapelBackButton(
            compact: true,
            onPressed: () => setState(() {
              _selectedMapelId = null;
              _selectedMateriId = null;
            }),
          ),
        ),
        const SizedBox(width: 8),
        _lihatNilaiButton(compact: true),
      ],
    );
  }

  Widget _materiBreadcrumb(MapelOption mapel, Materi materi) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _selectedMateriId = null),
          icon: const Icon(Icons.arrow_back_rounded, size: 17),
          label: const Text('Kembali'),
        ),
        const Icon(Icons.menu_book_rounded, color: AppColors.purple, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '${mapel.nama} › ${materi.bab}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _lihatNilaiButton({bool compact = false}) {
    return AppCompactActionButton(
      label: 'Lihat Nilai Saya',
      icon: Icons.arrow_forward_rounded,
      alignment: Alignment.centerRight,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.purple,
      borderColor: AppColors.border,
      compact: compact,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SiswaNilaiScreen(),
        ),
      ),
    );
  }

  List<Widget> _buildMaterialPicker(
    AppProvider app,
    List<Materi> materi,
    List<Kuis> visibleKuis,
    List<Kuis> kuisTanpaMateri,
    List<HasilKuis> riwayat,
  ) {
    if (materi.isEmpty) {
      return [
        const EmptyState(
          text: 'Belum ada bab materi untuk mata pelajaran ini.',
        ),
        if (kuisTanpaMateri.isNotEmpty) ...[
          const SectionTitle('Kuis tersedia'),
          ...kuisTanpaMateri.map(
            (kuis) => _quizDetailCard(app, kuis, riwayat),
          ),
        ],
      ];
    }

    return [
      const AppCard(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Bab Materi',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Pilih materi yang ingin kamu pelajari dan kerjakan kuisnya (Mudah → Sedang → Sulit)',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      ...materi.map((item) {
        final itemKuis =
            visibleKuis.where((kuis) => kuis.materiId == item.id).toList();
        final levels = itemKuis
            .map((kuis) => _normalizedLevel(kuis.level))
            .toSet()
            .map(_difficultyBadge)
            .toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MateriSelectionCard(
            materi: item,
            badges: levels,
            footer: '${itemKuis.length} kuis tersedia',
            footerAction: TextButton(
              onPressed: () => _bukaBab(item),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.purple,
              ),
              child: const Text('Buka Bab Ini →'),
            ),
            onTap: () => _bukaBab(item),
          ),
        );
      }),
      if (kuisTanpaMateri.isNotEmpty) ...[
        const SizedBox(height: 6),
        const SectionTitle('Kuis tanpa materi terkait'),
        ...kuisTanpaMateri.map(
          (kuis) => _quizDetailCard(app, kuis, riwayat),
        ),
      ],
    ];
  }

  List<Widget> _buildQuizDetails(
    AppProvider app,
    Materi materi,
    List<Kuis> kuis,
    List<HasilKuis> riwayat,
  ) {
    return [
      AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              materi.judul,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (materi.deskripsi.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                materi.deskripsi,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (kuis.isEmpty)
        const EmptyState(text: 'Belum ada kuis untuk bab materi ini.')
      else
        ...kuis.map((item) => _quizDetailCard(app, item, riwayat)),
    ];
  }

  Widget _quizDetailCard(
    AppProvider app,
    Kuis kuis,
    List<HasilKuis> riwayat,
  ) {
    final nilaiSelesai = riwayat
        .where((hasil) => hasil.kuisId == kuis.id && !hasil.nilaiMenunggu)
        .map((hasil) => hasil.nilai)
        .toList();
    final nilaiTerbaik = nilaiSelesai.isEmpty
        ? null
        : nilaiSelesai.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _QuizDetailCard(
        kuis: kuis,
        bestScore: nilaiTerbaik == null ? null : formatSkor(nilaiTerbaik),
        isStarting: _startingKuisId == kuis.id,
        onStart: () => _mulaiKuis(app, kuis.id),
      ),
    );
  }

  AppPill _difficultyBadge(String level) {
    final normalized = _normalizedLevel(level);
    switch (normalized.toLowerCase()) {
      case 'mudah':
        return AppPill(
          label: normalized,
          color: AppColors.green,
          background: AppColors.greenLight,
        );
      case 'sedang':
        return AppPill(
          label: normalized,
          color: const Color(0xFFB9701C),
          background: AppColors.orangeLight,
        );
      default:
        return AppPill(
          label: normalized,
          color: AppColors.red,
          background: AppColors.redLight,
        );
    }
  }

  String _normalizedLevel(String level) {
    return level.isEmpty
        ? 'Mudah'
        : '${level[0].toUpperCase()}${level.substring(1)}';
  }

  void _bukaBab(Materi materi) {
    setState(() => _selectedMateriId = materi.id);
  }

  String? _mapelIdForKuis(AppProvider app, Kuis kuis) {
    return kuis.idMapel ?? app.materiById(kuis.materiId)?.idMapel;
  }
}

class _QuizDetailCard extends StatelessWidget {
  const _QuizDetailCard({
    required this.kuis,
    required this.bestScore,
    required this.isStarting,
    required this.onStart,
  });

  final Kuis kuis;
  final String? bestScore;
  final bool isStarting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final level = kuis.level.isEmpty
        ? 'Mudah'
        : '${kuis.level[0].toUpperCase()}${kuis.level.substring(1)}';
    final category = kuis.kategori
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kuis.judul,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.quiz_outlined,
                color: AppColors.purple,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              AppPill(
                label: category,
                color: AppColors.purple,
                background: AppColors.purpleLight,
              ),
              _difficultyBadge(level),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5FC),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _QuizMetric(value: '${kuis.waktu}', label: 'Menit'),
                _QuizMetric(value: '${kuis.kkm}', label: 'KKM'),
                _QuizMetric(value: '${kuis.jumlahSoal}', label: 'Soal'),
              ],
            ),
          ),
          if (bestScore != null) ...[
            const SizedBox(height: 12),
            Text(
              'Nilai terbaik kamu: $bestScore',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: 225,
              child: FilledButton.icon(
                onPressed: isStarting ? null : onStart,
                icon: isStarting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('Mulai Kuis'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppPill _difficultyBadge(String level) {
    switch (level.toLowerCase()) {
      case 'mudah':
        return AppPill(
          label: level,
          color: AppColors.green,
          background: AppColors.greenLight,
        );
      case 'sedang':
        return AppPill(
          label: level,
          color: const Color(0xFFB9701C),
          background: AppColors.orangeLight,
        );
      default:
        return AppPill(
          label: level,
          color: AppColors.red,
          background: AppColors.redLight,
        );
    }
  }
}

class _QuizMetric extends StatelessWidget {
  const _QuizMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.purple,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
