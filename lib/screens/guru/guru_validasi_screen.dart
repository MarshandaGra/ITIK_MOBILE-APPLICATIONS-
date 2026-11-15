import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/hasil_kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

enum _Filter { semua, lulus, tidakLulus }

class GuruValidasiScreen extends StatefulWidget {
  const GuruValidasiScreen({super.key});

  @override
  State<GuruValidasiScreen> createState() => _GuruValidasiScreenState();
}

class _GuruValidasiScreenState extends State<GuruValidasiScreen> {
  _Filter _filter = _Filter.semua;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppProvider>().loadNilaiGuru();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final lulus = app.hasilList.where((h) => !h.dibawahKkm).toList();
    final tidakLulus = app.hasilList.where((h) => h.dibawahKkm).toList();

    final perluRemedial = tidakLulus
        .where((h) => !h.remedialDitugaskan && !h.remedialSelesai)
        .length;

    final List<HasilKuis> tampil;
    final String intro;
    final String kosong;
    switch (_filter) {
      case _Filter.lulus:
        tampil = lulus;
        intro =
            'Siswa dengan nilai di atas/sama dengan KKM. Nilai otomatis tervalidasi.';
        kosong = 'Belum ada siswa yang lulus.';
        break;
      case _Filter.tidakLulus:
        tampil = tidakLulus;
        intro =
            'Siswa dengan nilai di bawah KKM. $perluRemedial siswa belum mendapat tugas remedial.';
        kosong = 'Tidak ada siswa di bawah KKM. 🎉';
        break;
      case _Filter.semua:
        tampil = app.hasilList;
        intro =
            'Pantau nilai, waktu pengerjaan tiap siswa, dan tugaskan remedial untuk yang di bawah KKM (${tidakLulus.length} siswa).';
        kosong = 'Belum ada nilai kuis yang masuk.';
        break;
    }

    return Scaffold(
      appBar: simpleAppBar('Validasi & Remedial'),
      body: SafeArea(
        child: app.nilaiLoading && app.hasilList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : app.nilaiLoadError != null && app.hasilList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Nilai kuis gagal dimuat.'),
                          const SizedBox(height: 8),
                          Text(
                            app.nilaiLoadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                          TextButton.icon(
                            onPressed:
                                app.nilaiLoading ? null : app.loadNilaiGuru,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : app.hasilList.isEmpty
                    ? RefreshIndicator(
                        onRefresh: app.loadNilaiGuru,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 300,
                              child: EmptyState(
                                  text: 'Belum ada nilai kuis yang masuk.'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          if (app.nilaiLoadError != null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Gagal memperbarui nilai: ${app.nilaiLoadError}',
                                style: const TextStyle(color: AppColors.red),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: Row(
                              children: [
                                _FilterChipKecil(
                                  label: 'Semua (${app.hasilList.length})',
                                  selected: _filter == _Filter.semua,
                                  color: AppColors.blue,
                                  onTap: () =>
                                      setState(() => _filter = _Filter.semua),
                                ),
                                const SizedBox(width: 8),
                                _FilterChipKecil(
                                  label: 'Lulus (${lulus.length})',
                                  selected: _filter == _Filter.lulus,
                                  color: AppColors.green,
                                  onTap: () =>
                                      setState(() => _filter = _Filter.lulus),
                                ),
                                const SizedBox(width: 8),
                                _FilterChipKecil(
                                  label: 'Tidak Lulus (${tidakLulus.length})',
                                  selected: _filter == _Filter.tidakLulus,
                                  color: AppColors.red,
                                  onTap: () => setState(
                                      () => _filter = _Filter.tidakLulus),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: app.loadNilaiGuru,
                              child: _DaftarHasil(
                                list: tampil,
                                app: app,
                                intro: intro,
                                kosong: kosong,
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _FilterChipKecil extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChipKecil({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _DaftarHasil extends StatelessWidget {
  final List<HasilKuis> list;
  final AppProvider app;
  final String intro;
  final String kosong;
  const _DaftarHasil({
    required this.list,
    required this.app,
    required this.intro,
    required this.kosong,
  });

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: EmptyState(text: kosong),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(intro,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        const SizedBox(height: 12),
        ...list.map((h) => _ValidasiCard(hasil: h, app: app)),
      ],
    );
  }
}

class _ValidasiCard extends StatefulWidget {
  final HasilKuis hasil;
  final AppProvider app;
  const _ValidasiCard({required this.hasil, required this.app});

  @override
  State<_ValidasiCard> createState() => _ValidasiCardState();
}

class _ValidasiCardState extends State<_ValidasiCard> {
  bool _assigning = false;

  Future<void> _tugaskanRemedial(BuildContext context) async {
    final hasil = widget.hasil;
    setState(() => _assigning = true);
    try {
      final remedials = await widget.app.remedialUntukKuis(hasil.kuisId);
      if (remedials.isEmpty) {
        throw StateError(
          'Belum ada kuis kategori Remedial untuk "${hasil.kuis}". Buat kuis remedial dengan kuis asal yang sesuai terlebih dahulu.',
        );
      }

      final tersedia = remedials.where((remedial) {
        final kuis = remedial['kuis_remedial'];
        return kuis is Map &&
            kuis['status_publikasi'] == 'terbit' &&
            kuis['is_aktif'] == true;
      }).toList();
      if (tersedia.isEmpty) {
        throw StateError(
          'Kuis remedial untuk "${hasil.kuis}" belum diterbitkan atau sudah tidak aktif.',
        );
      }

      final terpilih = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pilih kuis remedial'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: tersedia.map((remedial) {
                final kuis =
                    Map<String, dynamic>.from(remedial['kuis_remedial'] as Map);
                return ListTile(
                  title: Text('${kuis['judul'] ?? 'Kuis remedial'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(dialogContext, remedial),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
          ],
        ),
      );
      if (terpilih == null || !context.mounted) return;

      final kuisTerpilih =
          Map<String, dynamic>.from(terpilih['kuis_remedial'] as Map);
      final remedialId = terpilih['id_remedial']?.toString();
      if (remedialId == null || remedialId.isEmpty) {
        throw const FormatException('ID tugas remedial tidak ditemukan.');
      }

      final ok = await confirmDialog(
        context,
        'Tugaskan "${kuisTerpilih['judul'] ?? 'kuis remedial'}" kepada ${hasil.siswa}?',
      );
      if (!ok || !context.mounted) return;

      await widget.app.tugaskanRemedial(hasil.id, remedialId);
      if (context.mounted) {
        showAppToast(context, 'Remedial ditugaskan ke ${hasil.siswa} ✔');
      }
    } catch (error) {
      if (context.mounted) {
        showAppToast(context, 'Gagal menugaskan remedial: $error');
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hasil;
    final dibawahKkm = h.dibawahKkm;
    final kuisRef = widget.app.kuisById(h.kuisId);
    final alokasi = kuisRef?.waktu ?? 10;
    final rasio = (h.durasi ?? 0) / (alokasi * 60);
    final kecepatanLabel = rasio <= 0.6
        ? '⚡ Cepat'
        : rasio <= 1.0
            ? 'Sesuai alokasi'
            : '🐢 Lambat';
    final kecepatanColor = rasio <= 0.6
        ? AppColors.green
        : rasio <= 1.0
            ? AppColors.blue
            : AppColors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.siswa,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                            '${h.tanggal} • ${h.kuis}${h.remedial ? ' • Remedial' : ''}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                      ]),
                ),
                Text(formatSkor(h.nilai),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: dibawahKkm ? AppColors.red : AppColors.blue)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              LevelPill(level: h.level),
              dibawahKkm
                  ? AppPill(
                      label: '↓ KKM ${formatSkor(h.kkm)}',
                      color: AppColors.red,
                      background: AppColors.redLight)
                  : AppPill(
                      label: '✔ KKM ${formatSkor(h.kkm)}',
                      color: AppColors.green,
                      background: AppColors.greenLight),
              if (h.durasi != null) ...[
                Text(
                  '${fmtWaktu(h.durasi!)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                AppPill(
                    label: kecepatanLabel,
                    color: kecepatanColor,
                    background: kecepatanColor.withOpacity(.12)),
              ],
              AppPill(
                label:
                    dibawahKkm ? 'Di bawah KKM' : 'Tervalidasi Otomatis',
                color: dibawahKkm ? AppColors.red : AppColors.green,
                background: dibawahKkm
                    ? AppColors.redLight
                    : AppColors.greenLight,
              ),
            ]),
            const SizedBox(height: 12),
            if (dibawahKkm)
              SizedBox(
                width: double.infinity,
                child: h.remedialSelesai
                    ? const _StaticBadge(
                        label: 'Remedial Selesai',
                        color: AppColors.green,
                        bg: AppColors.greenLight)
                    : h.remedialDitugaskan
                        ? const _StaticBadge(
                            label: 'Remedial Ditugaskan',
                            color: AppColors.red,
                            bg: AppColors.redLight)
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red),
                            onPressed: _assigning
                                ? null
                                : () => _tugaskanRemedial(context),
                            icon: _assigning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.error_outline, size: 17),
                            label: Text(
                                _assigning ? 'Menyimpan...' : 'Remedial',
                                style: const TextStyle(fontSize: 12.5)),
                          ),
              )
            else
              const _StaticBadge(
                label: 'Valid Otomatis',
                color: AppColors.green,
                bg: AppColors.greenLight,
              ),
          ],
        ),
      ),
    );
  }
}

class _StaticBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StaticBadge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check, size: 15, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ]),
    );
  }
}
