import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/hasil_kuis.dart';
import '../../models/kuis.dart';
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

  String _nomorPercobaan(AppProvider app, HasilKuis hasil) {
    final urutan = app.hasilGuruSaatIni.reversed
        .where((h) => h.siswaId == hasil.siswaId && h.kuisId == hasil.kuisId)
        .toList();
    final index = urutan.indexWhere((h) => h.id == hasil.id);
    return 'Ke-${index < 0 ? 1 : index + 1}';
  }

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
                              child: _HasilNilaiTable(
                                hasil: tampil,
                                app: app,
                                intro: intro,
                                kosong: kosong,
                                nomorPercobaan: (hasil) =>
                                    _nomorPercobaan(app, hasil),
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
  Widget build(BuildContext context) => ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: selected ? color.withValues(alpha: 0.12) : null,
        side: BorderSide(color: selected ? color : AppColors.border),
      );
}

class _KelasMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _KelasMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _KelasTerpilihBanner extends StatelessWidget {
  final String? kelas;
  final int jumlahSiswa;
  final double rataNilai;
  final VoidCallback? onShowAll;

  const _KelasTerpilihBanner({
    required this.kelas,
    required this.jumlahSiswa,
    required this.rataNilai,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.purpleLight.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purpleLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open_rounded,
              color: AppColors.purple, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kelas == null
                      ? 'Menampilkan Data Nilai: Semua Kelas'
                      : 'Menampilkan Data Nilai: Kelas $kelas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$jumlahSiswa Siswa • Rata-rata Nilai: ${rataNilai.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (onShowAll != null)
            TextButton(
              onPressed: onShowAll,
              child: const Text(
                'Semua Kelas',
                maxLines: 1,
                style: TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _HasilNilaiTable extends StatelessWidget {
  final List<HasilKuis> hasil;
  final AppProvider app;
  final String intro;
  final String kosong;
  final String Function(HasilKuis) nomorPercobaan;

  const _HasilNilaiTable({
    required this.hasil,
    required this.app,
    required this.intro,
    required this.kosong,
    required this.nomorPercobaan,
  });

  @override
  Widget build(BuildContext context) {
    if (hasil.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: EmptyState(text: this.kosong),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text(this.intro,
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        const SizedBox(height: 12),
        ...hasil.map((h) => _ValidasiCard(
              hasil: h,
              app: app,
              nomorPercobaan: nomorPercobaan(h),
            )),
      ],
    );
  }
}

class _ValidasiCard extends StatefulWidget {
  final HasilKuis hasil;
  final AppProvider app;
  final String nomorPercobaan;
  const _ValidasiCard({
    required this.hasil,
    required this.app,
    required this.nomorPercobaan,
  });

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

class _EvaluasiButirCard extends StatelessWidget {
  final int nomor;
  final Soal soal;
  final int pilihanSiswa;
  final String jawabanEsaiSiswa;
  final bool benar;
  final double bobot;

  const _EvaluasiButirCard({
    required this.nomor,
    required this.soal,
    required this.pilihanSiswa,
    required this.jawabanEsaiSiswa,
    required this.benar,
    required this.bobot,
  });

  @override
  Widget build(BuildContext context) {
    final jawabanTersedia =
        pilihanSiswa >= 0 && pilihanSiswa < soal.opsi.length;
    final borderColor = benar ? AppColors.green : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Soal #$nomor  (Bobot: ${bobot.toStringAsFixed(2)}%)',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              AppPill(
                label: soal.jenis == Soal.esai
                    ? 'Esai'
                    : benar
                        ? '✓ Benar (+${bobot.toStringAsFixed(2)}%)'
                        : '⚠ Salah',
                color: soal.jenis == Soal.esai
                    ? AppColors.blue
                    : benar
                        ? AppColors.green
                        : AppColors.orange,
                background: soal.jenis == Soal.esai
                    ? AppColors.blueLight
                    : benar
                        ? AppColors.greenLight
                        : AppColors.orangeLight,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(soal.pertanyaan),
          if (soal.jenis == Soal.esai) ...[
            const SizedBox(height: 12),
            _JawabanEsai(
              label: 'Jawaban Siswa',
              value: jawabanEsaiSiswa.isEmpty
                  ? 'Tidak ada jawaban'
                  : jawabanEsaiSiswa,
            ),
            const SizedBox(height: 8),
            _JawabanEsai(label: 'Kunci Jawaban', value: soal.jawabanEsai),
          ] else if (soal.opsi.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(soal.opsi.length, (index) {
              final isKey = index == soal.jawaban;
              final isSelected = jawabanTersedia && index == pilihanSiswa;
              final isWrongSelection = isSelected && !isKey;
              final background = isKey
                  ? AppColors.greenLight
                  : isWrongSelection
                      ? AppColors.redLight
                      : AppColors.bg;
              final outline = isKey
                  ? AppColors.green.withValues(alpha: .35)
                  : isWrongSelection
                      ? AppColors.red.withValues(alpha: .35)
                      : AppColors.border;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: outline),
                ),
                child: Row(
                  children: [
                    Text(
                      '${String.fromCharCode(65 + index)}.',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(soal.opsi[index])),
                    if (isKey)
                      const AppPill(
                        label: '✓ Kunci Jawaban',
                        color: AppColors.green,
                        background: AppColors.greenLight,
                      )
                    else if (isWrongSelection)
                      const AppPill(
                        label: '✕ Pilihan Siswa (Salah)',
                        color: AppColors.red,
                        background: AppColors.redLight,
                      ),
                  ],
                ),
              );
            }),
            if (!jawabanTersedia)
              const Text(
                'Siswa tidak memilih jawaban.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
          ],
        ],
      ),
    );
  }
}

class _JawabanEsai extends StatelessWidget {
  final String label;
  final String value;

  const _JawabanEsai({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
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
