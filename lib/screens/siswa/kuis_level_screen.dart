import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hasil_kuis.dart';
import '../../models/kuis.dart';
import '../../models/materi.dart';
import '../../models/user.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../shared/profil_screen.dart';
import 'kuis_play_screen.dart';
import 'siswa_nilai_screen.dart';

const _portalPurple = Color(0xFF604CE8);
const _portalPurpleLight = Color(0xFFF0EDFF);

class KuisLevelScreen extends StatefulWidget {
  const KuisLevelScreen({super.key});

  @override
  State<KuisLevelScreen> createState() => _KuisLevelScreenState();
}

class _KuisLevelScreenState extends State<KuisLevelScreen> {
  String? _selectedMapel;
  String? _selectedMateriId;

  String _mapel(Materi materi) =>
      materi.mataPelajaran?.trim().isNotEmpty == true
          ? materi.mataPelajaran!.trim()
          : MataPelajaranGuru.tik;

  List<Kuis> _kuisUntukMateri(AppProvider app, String materiId) => app.kuisList
      .where((item) => item.isPublished && item.materiId == materiId)
      .toList();

  void _kembali() {
    setState(() {
      if (_selectedMateriId != null) {
        _selectedMateriId = null;
      } else {
        _selectedMapel = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    final mapelList = app.materiList.map(_mapel).toSet().toList();
    final selectedMateri =
        _selectedMateriId == null ? null : app.materiById(_selectedMateriId!);
    final materiMapel = _selectedMapel == null
        ? <Materi>[]
        : app.materiList
            .where((item) => _mapel(item) == _selectedMapel)
            .toList();
    final riwayat = app.riwayatSiswaSaatIni;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final horizontalPadding = wide ? 30.0 : 20.0;
                final contentWidth =
                    constraints.maxWidth - horizontalPadding * 2;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 22, horizontalPadding, 28),
                  children: [
                    _PortalHeader(
                      nama: user?.nama ?? 'Siswa',
                      initials: user?.initials ?? 'S',
                    ),
                    const SizedBox(height: 26),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daftar Kuis',
                                style: TextStyle(
                                    fontSize: 28,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Pilih kuis pembelajaran yang tersedia dan selesaikan tantangannya.',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (wide) ...[
                          const SizedBox(width: 14),
                          _nilaiButton(context),
                        ],
                      ],
                    ),
                    if (!wide) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _nilaiButton(context),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_selectedMapel != null) ...[
                      _Breadcrumb(
                        mapel: _selectedMapel!,
                        bab: selectedMateri?.bab,
                        onBack: _kembali,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_selectedMapel != null && selectedMateri == null) ...[
                      _SubjectBanner(
                        mapel: _selectedMapel!,
                        babCount: materiMapel.length,
                        kuisCount: materiMapel.fold<int>(
                          0,
                          (total, materi) =>
                              total + _kuisUntukMateri(app, materi.id).length,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedMateri != null)
                      _buildKuis(
                        context,
                        selectedMateri,
                        _kuisUntukMateri(app, selectedMateri.id),
                        riwayat,
                        contentWidth,
                      )
                    else if (_selectedMapel != null)
                      _buildBab(materiMapel, app, contentWidth)
                    else
                      _buildMapel(mapelList, app, contentWidth),
                    const Padding(
                      padding: EdgeInsets.only(top: 22),
                      child: Text(
                        'ITIK · Portal Siswa — Media Pembelajaran TIK',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _nilaiButton(BuildContext context) => SizedBox(
        width: 180,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: _portalPurple,
            side: const BorderSide(color: AppColors.border),
            backgroundColor: Colors.white,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SiswaNilaiScreen()),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                  child: Text('Lihat Nilai Saya',
                      overflow: TextOverflow.ellipsis)),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 15),
            ],
          ),
        ),
      );

  Widget _buildMapel(
      List<String> mapelList, AppProvider app, double availableWidth) {
    return _Panel(
      title: 'Pilih Mata Pelajaran',
      subtitle: 'Pilih mata pelajaran untuk melihat kuis yang tersedia',
      child: mapelList.isEmpty
          ? const EmptyState(text: 'Belum ada mata pelajaran tersedia.')
          : _cardGrid(
              availableWidth,
              mapelList.length,
              (index) {
                final mapel = mapelList[index];
                final materiIds = app.materiList
                    .where((item) => _mapel(item) == mapel)
                    .map((item) => item.id)
                    .toSet();
                final count = app.kuisList
                    .where((item) =>
                        item.isPublished && materiIds.contains(item.materiId))
                    .length;
                return _SubjectCard(
                  title: mapel,
                  count: count,
                  onTap: () => setState(() => _selectedMapel = mapel),
                );
              },
            ),
    );
  }

  Widget _buildBab(
      List<Materi> materiList, AppProvider app, double availableWidth) {
    return _Panel(
      title: 'Pilih Bab Materi',
      subtitle:
          'Pilih materi yang ingin kamu pelajari dan kerjakan kuisnya (Mudah → Sedang → Sulit)',
      child: materiList.isEmpty
          ? const EmptyState(
              text: 'Belum ada bab materi untuk mata pelajaran ini.')
          : _cardGrid(
              availableWidth,
              materiList.length,
              (index) {
                final materi = materiList[index];
                final kuis = _kuisUntukMateri(app, materi.id);
                return _ChapterCard(
                  materi: materi,
                  kuis: kuis,
                  onTap: () => setState(() => _selectedMateriId = materi.id),
                );
              },
            ),
    );
  }

  Widget _buildKuis(
    BuildContext context,
    Materi materi,
    List<Kuis> kuis,
    List<HasilKuis> riwayat,
    double availableWidth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF735FF2), Color(0xFF5944DE)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedMapel ?? _mapel(materi),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${materi.bab} · ${kuis.length} kuis tersedia',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: materi.judul,
          subtitle: materi.deskripsi,
          child: kuis.isEmpty
              ? const EmptyState(text: 'Belum ada kuis untuk bab ini.')
              : _cardGrid(
                  availableWidth,
                  kuis.length,
                  (index) {
                    final item = kuis[index];
                    final attempts = riwayat
                        .where((result) => result.kuisId == item.id)
                        .toList();
                    final bestScore = attempts.isEmpty
                        ? null
                        : attempts
                            .map((result) => result.nilai)
                            .reduce((a, b) => a > b ? a : b);
                    return _QuizCard(
                      kuis: item,
                      nilaiTerbaik: bestScore,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KuisPlayScreen(kuis: item),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _cardGrid(
    double availableWidth,
    int itemCount,
    Widget Function(int index) buildCard,
  ) {
    final columns = availableWidth >= 1000
        ? 4
        : availableWidth >= 640
            ? 2
            : 1;
    const spacing = 14.0;
    final width = columns == 1
        ? availableWidth
        : (availableWidth - (columns - 1) * spacing) / columns;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(
        itemCount,
        (index) => SizedBox(width: width, child: buildCard(index)),
      ),
    );
  }
}

class _PortalHeader extends StatelessWidget {
  final String nama;
  final String initials;

  const _PortalHeader({required this.nama, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'PORTAL SISWA',
            style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: _portalPurpleLight,
                  foregroundColor: _portalPurple,
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w800)),
                    const Text('Siswa',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final String mapel;
  final String? bab;
  final VoidCallback onBack;

  const _Breadcrumb(
      {required this.mapel, required this.bab, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 15),
          label: const Text('Kembali'),
          style: TextButton.styleFrom(
            foregroundColor: _portalPurple,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.menu_book_rounded, color: _portalPurple, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            bab == null ? mapel : '$mapel  ›  $bab',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: _portalPurple,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SubjectBanner extends StatelessWidget {
  final String mapel;
  final int babCount;
  final int kuisCount;

  const _SubjectBanner({
    required this.mapel,
    required this.babCount,
    required this.kuisCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF735FF2), Color(0xFF5944DE)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mapel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$babCount bab materi · $kuisCount kuis tersedia',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Panel(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;

  const _SubjectCard(
      {required this.title, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BookIcon(),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text('Kuis tersedia',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ),
              Text('$count',
                  style: const TextStyle(
                      color: _portalPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Materi materi;
  final List<Kuis> kuis;
  final VoidCallback onTap;

  const _ChapterCard(
      {required this.materi, required this.kuis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final availableLevels = ['Mudah', 'Sedang', 'Sulit']
        .where((level) => kuis.any((item) => item.level == level))
        .toList();
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BookIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPill(
                        label: materi.bab,
                        color: _portalPurple,
                        background: _portalPurpleLight),
                    const SizedBox(height: 8),
                    Text(materi.judul,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(materi.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 11.5, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final level in availableLevels) LevelPill(level: level),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('${kuis.length} kuis tersedia',
                    style: const TextStyle(
                        color: _portalPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const Text('Buka Bab Ini  →',
                  style: TextStyle(
                      color: _portalPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Kuis kuis;
  final int? nilaiTerbaik;
  final VoidCallback onTap;

  const _QuizCard(
      {required this.kuis, required this.nilaiTerbaik, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kategori = kuis.kategori?.trim().isNotEmpty == true
        ? kuis.kategori!
        : 'Kuis Harian';
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(kuis.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.quiz_outlined, color: _portalPurple, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppPill(
                  label: kategori,
                  color: _portalPurple,
                  background: _portalPurpleLight),
              LevelPill(level: kuis.level),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
            decoration: BoxDecoration(
                color: const Color(0xFFF7F6FC),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _QuizMetric(value: '${kuis.waktu}', label: 'Menit'),
                _QuizMetric(value: '${kuis.kkm}', label: 'KKM'),
                _QuizMetric(value: '${kuis.soal.length}', label: 'Soal'),
              ],
            ),
          ),
          if (nilaiTerbaik != null) ...[
            const SizedBox(height: 12),
            Text('Nilai terbaik kamu: $nilaiTerbaik',
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 180,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _portalPurple,
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                onPressed: onTap,
                child: const Text('Mulai Kuis  →'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizMetric extends StatelessWidget {
  final String value;
  final String label;

  const _QuizMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _portalPurple)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _BookIcon extends StatelessWidget {
  const _BookIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: _portalPurpleLight, borderRadius: BorderRadius.circular(12)),
      child:
          const Icon(Icons.menu_book_rounded, color: _portalPurple, size: 22),
    );
  }
}
