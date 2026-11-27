import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/hasil_kuis.dart';
import '../../models/kelas_guru.dart';
import '../../models/kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

enum _KelulusanFilter { semua, lulus, tidakLulus }

class GuruValidasiScreen extends StatefulWidget {
  const GuruValidasiScreen({super.key});

  @override
  State<GuruValidasiScreen> createState() => _GuruValidasiScreenState();
}

class _GuruValidasiScreenState extends State<GuruValidasiScreen> {
  String? _kelasTerpilih;
  String? _kategoriTerpilih;
  int? _percobaanTerpilih;
  _KelulusanFilter _kelulusanTerpilih = _KelulusanFilter.semua;
  DateTime? _tanggalTerpilih;

  static const _semuaFilter = '__semua__';
  static const _pilihTanggal = '__pilih_tanggal__';

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
    final semuaGuru = app.hasilList;
    final kelasUrut = List<KelasGuru>.from(app.kelasGuruList)
      ..sort((a, b) => a.namaTampilan.compareTo(b.namaTampilan));
    if (_kelasTerpilih != null &&
        !kelasUrut.any((kelas) => kelas.id == _kelasTerpilih)) {
      _kelasTerpilih = null;
    }
    final kelasDipilih = _kelasTerpilih == null
        ? null
        : kelasUrut.firstWhere((kelas) => kelas.id == _kelasTerpilih);

    final hasilKelas = _kelasTerpilih == null
        ? semuaGuru
        : semuaGuru.where((h) => h.kelasIds.contains(_kelasTerpilih)).toList();

    final kategoriKuis = <String, String>{};
    for (final kategori in [
      'remedial',
      ...app.kuisList.map((kuis) => kuis.kategori),
      ...semuaGuru.map((hasil) => hasil.kategori),
    ]) {
      final normalized = kategori.trim();
      if (normalized.isNotEmpty) {
        kategoriKuis.putIfAbsent(normalized.toLowerCase(), () => normalized);
      }
    }
    final kategoriTersedia = kategoriKuis.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (_kategoriTerpilih != null &&
        !kategoriTersedia.any(
          (kategori) => kategori.toLowerCase() == _kategoriTerpilih,
        )) {
      _kategoriTerpilih = null;
    }

    final hasilFilterAwal = hasilKelas.where((hasil) {
      final cocokKategori = _kategoriTerpilih == null ||
          hasil.kategori.trim().toLowerCase() == _kategoriTerpilih;
      final cocokPercobaan =
          _percobaanTerpilih == null || hasil.percobaanKe == _percobaanTerpilih;
      final cocokTanggal = _tanggalTerpilih == null ||
          hasil.tanggal == _tanggalKeString(_tanggalTerpilih!);
      return cocokKategori && cocokPercobaan && cocokTanggal;
    }).toList();

    final lulus = hasilFilterAwal
        .where((hasil) => !hasil.nilaiMenunggu && !hasil.dibawahKkm)
        .toList();
    final tidakLulus = hasilFilterAwal
        .where((hasil) => !hasil.nilaiMenunggu && hasil.dibawahKkm)
        .toList();
    final nilaiTerisi =
        hasilKelas.where((hasil) => !hasil.nilaiMenunggu).toList();
    final rataNilaiSemua = nilaiTerisi.isEmpty
        ? null
        : nilaiTerisi.map((hasil) => hasil.nilai).reduce((a, b) => a + b) /
            nilaiTerisi.length;

    final List<HasilKuis> tampil;
    switch (_kelulusanTerpilih) {
      case _KelulusanFilter.lulus:
        tampil = lulus;
        break;
      case _KelulusanFilter.tidakLulus:
        tampil = tidakLulus;
        break;
      case _KelulusanFilter.semua:
        tampil = hasilFilterAwal;
        break;
    }
    final tanggalFilterLabel = _tanggalTerpilih == null
        ? 'Semua'
        : _tanggalTampilan(_tanggalTerpilih!);

    return Scaffold(
      body: SafeArea(
        child: app.nilaiLoading && app.hasilList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : app.nilaiLoadError != null &&
                    app.hasilList.isEmpty &&
                    app.kelasGuruList.isEmpty
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
                : semuaGuru.isEmpty && kelasUrut.isEmpty
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
                    : RefreshIndicator(
                        onRefresh: app.loadNilaiGuru,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Daftar Nilai Siswa',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.7,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Pantau nilai siswa per kelas dan berikan remedial untuk yang belum lulus.',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    '🏫 PILIH KELAS PEMBELAJARAN',
                                    style: TextStyle(
                                      color: AppColors.purple,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final kelas in kelasUrut) ...[
                                    _MobileKelasCard(
                                      kelas: kelas,
                                      selected: _kelasTerpilih == kelas.id,
                                      onTap: () => setState(
                                        () => _kelasTerpilih =
                                            _kelasTerpilih == kelas.id
                                                ? null
                                                : kelas.id,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  _KelasTerpilihBanner(
                                    kelas: kelasDipilih?.namaTampilan,
                                    jumlahSiswa: kelasDipilih?.totalSiswa ??
                                        kelasUrut.fold<int>(
                                          0,
                                          (total, kelas) =>
                                              total + kelas.totalSiswa,
                                        ),
                                    rataNilai: kelasDipilih == null
                                        ? rataNilaiSemua
                                        : kelasDipilih.rataNilai,
                                    onShowAll: _kelasTerpilih == null
                                        ? null
                                        : () => setState(
                                            () => _kelasTerpilih = null),
                                  ),
                                ],
                              ),
                            ),
                            if (app.nilaiLoadError != null)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Gagal memperbarui nilai: ${app.nilaiLoadError}',
                                  style: const TextStyle(color: AppColors.red),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                              child: _KlasifikasiFilterPanel(
                                kategori: kategoriTersedia,
                                kategoriTerpilih: _kategoriTerpilih,
                                percobaanTerpilih: _percobaanTerpilih,
                                kelulusanTerpilih: _kelulusanTerpilih,
                                tanggalLabel: tanggalFilterLabel,
                                semuaValue: _semuaFilter,
                                pilihTanggalValue: _pilihTanggal,
                                onKategoriChanged: (value) => setState(
                                  () => _kategoriTerpilih =
                                      value == _semuaFilter ? null : value,
                                ),
                                onPercobaanChanged: (value) => setState(
                                  () => _percobaanTerpilih =
                                      value == _semuaFilter
                                          ? null
                                          : int.parse(value),
                                ),
                                onKelulusanChanged: (value) => setState(
                                  () => _kelulusanTerpilih = value,
                                ),
                                onTanggalChanged: (value) async {
                                  if (value == _semuaFilter) {
                                    setState(() => _tanggalTerpilih = null);
                                    return;
                                  }
                                  if (value != _pilihTanggal) return;

                                  final selected = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _tanggalTerpilih ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (selected != null && context.mounted) {
                                    setState(() => _tanggalTerpilih = selected);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hasil Pengerjaan Kuis Siswa',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Menampilkan ${tampil.length} dari ${hasilKelas.length} data pengerjaan kuis siswa',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _HasilNilaiTable(
                              hasil: tampil,
                              app: app,
                              kosong:
                                  _kelulusanTerpilih == _KelulusanFilter.lulus
                                      ? 'Belum ada siswa yang lulus.'
                                      : _kelulusanTerpilih ==
                                              _KelulusanFilter.tidakLulus
                                          ? 'Tidak ada siswa di bawah KKM.'
                                          : 'Belum ada nilai kuis yang masuk.',
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

String _tanggalKeString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _tanggalTampilan(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _labelKategori(String kategori) => kategori
    .split(RegExp(r'\s+'))
    .where((kata) => kata.isNotEmpty)
    .map((kata) => '${kata[0].toUpperCase()}${kata.substring(1)}')
    .join(' ');

class _KlasifikasiFilterPanel extends StatelessWidget {
  final List<String> kategori;
  final String? kategoriTerpilih;
  final int? percobaanTerpilih;
  final _KelulusanFilter kelulusanTerpilih;
  final String tanggalLabel;
  final String semuaValue;
  final String pilihTanggalValue;
  final ValueChanged<String> onKategoriChanged;
  final ValueChanged<String> onPercobaanChanged;
  final ValueChanged<_KelulusanFilter> onKelulusanChanged;
  final ValueChanged<String> onTanggalChanged;

  const _KlasifikasiFilterPanel({
    required this.kategori,
    required this.kategoriTerpilih,
    required this.percobaanTerpilih,
    required this.kelulusanTerpilih,
    required this.tanggalLabel,
    required this.semuaValue,
    required this.pilihTanggalValue,
    required this.onKategoriChanged,
    required this.onPercobaanChanged,
    required this.onKelulusanChanged,
    required this.onTanggalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.orange, size: 17),
              SizedBox(width: 7),
              Text(
                'KLASIFIKASI & FILTER CEPAT',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 360
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: width,
                    child: _DropdownFilterPill<String>(
                      icon: Icons.sell_outlined,
                      label: 'Kategori',
                      value: kategoriTerpilih == null
                          ? 'Semua'
                          : _labelKategori(kategori.firstWhere(
                              (item) => item.toLowerCase() == kategoriTerpilih,
                            )),
                      items: [
                        PopupMenuItem(
                          value: semuaValue,
                          child: const Text('Semua'),
                        ),
                        ...kategori.map(
                          (item) => PopupMenuItem(
                            value: item.toLowerCase(),
                            child: Text(_labelKategori(item)),
                          ),
                        ),
                      ],
                      onSelected: onKategoriChanged,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DropdownFilterPill<String>(
                      icon: Icons.sync_alt_rounded,
                      label: 'Percobaan',
                      value: percobaanTerpilih == null
                          ? 'Semua'
                          : 'Ke-${percobaanTerpilih!}',
                      items: [
                        PopupMenuItem(
                          value: semuaValue,
                          child: const Text('Semua'),
                        ),
                        for (var attempt = 1; attempt <= 10; attempt++)
                          PopupMenuItem(
                            value: '$attempt',
                            child: Text('Ke-$attempt'),
                          ),
                      ],
                      onSelected: onPercobaanChanged,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DropdownFilterPill<_KelulusanFilter>(
                      menuKey: const ValueKey('filter-kelulusan'),
                      icon: Icons.school_outlined,
                      label: 'Kelulusan',
                      value: switch (kelulusanTerpilih) {
                        _KelulusanFilter.semua => 'Semua',
                        _KelulusanFilter.lulus => 'Lulus',
                        _KelulusanFilter.tidakLulus => 'Tidak Lulus',
                      },
                      items: const [
                        PopupMenuItem(
                          value: _KelulusanFilter.semua,
                          child: Text('Semua'),
                        ),
                        PopupMenuItem(
                          value: _KelulusanFilter.lulus,
                          child: Text('Lulus'),
                        ),
                        PopupMenuItem(
                          value: _KelulusanFilter.tidakLulus,
                          child: Text('Tidak Lulus'),
                        ),
                      ],
                      onSelected: onKelulusanChanged,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DropdownFilterPill<String>(
                      icon: Icons.calendar_month_outlined,
                      label: 'Tanggal',
                      value: tanggalLabel,
                      items: [
                        PopupMenuItem(
                          value: semuaValue,
                          child: const Text('Semua'),
                        ),
                        PopupMenuItem(
                          value: pilihTanggalValue,
                          child: const Text('Pilih tanggal...'),
                        ),
                      ],
                      onSelected: onTanggalChanged,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DropdownFilterPill<T> extends StatelessWidget {
  final Key? menuKey;
  final IconData icon;
  final String label;
  final String value;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  const _DropdownFilterPill({
    this.menuKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      key: menuKey,
      onSelected: onSelected,
      itemBuilder: (_) => items,
      padding: EdgeInsets.zero,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.blue),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(text: '$label: '),
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 17),
          ],
        ),
      ),
    );
  }
}

class _MobileKelasCard extends StatelessWidget {
  final KelasGuru kelas;
  final bool selected;
  final VoidCallback onTap;

  const _MobileKelasCard({
    required this.kelas,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purpleLight.withValues(alpha: .72)
              : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? kCardShadow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    kelas.namaTampilan,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selected ? 'Sedang Dipilih' : 'Pilih',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KelasMetric(
                      label: 'Siswa', value: '${kelas.totalSiswa}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KelasMetric(
                      label: 'Materi', value: '${kelas.totalMateri}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _KelasMetric(
                    label: 'Kuis Aktif',
                    value: '${kelas.kuisAktif}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KelasMetric(
                    label: 'Rata-rata Nilai',
                    value: kelas.rataNilai?.toStringAsFixed(1) ?? '-',
                    valueColor: kelas.rataNilai == null
                        ? null
                        : kelas.rataNilai! < 75
                            ? AppColors.orange
                            : AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected ? '✓ Sedang Dilihat' : 'Lihat nilai kelas',
                    style: TextStyle(
                      color: selected ? AppColors.purple : AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.close : Icons.arrow_forward,
                  size: 17,
                  color: AppColors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
  final double? rataNilai;
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
                  '$jumlahSiswa Siswa • Rata-rata Nilai: ${rataNilai?.toStringAsFixed(1) ?? '-'}',
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
  final String kosong;

  const _HasilNilaiTable({
    required this.hasil,
    required this.app,
    required this.kosong,
  });

  @override
  Widget build(BuildContext context) {
    if (hasil.isEmpty) {
      return SizedBox(
        height: 300,
        child: EmptyState(text: this.kosong),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...hasil.map((h) => _ValidasiCard(
                hasil: h,
                app: app,
              )),
        ],
      ),
    );
  }
}

class _ValidasiCard extends StatefulWidget {
  final HasilKuis hasil;
  final AppProvider app;
  const _ValidasiCard({
    required this.hasil,
    required this.app,
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
              AppPill(
                label: 'Ke-${h.percobaanKe}',
                color: AppColors.blue,
                background: AppColors.blueLight,
              ),
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
                label: dibawahKkm ? 'Di bawah KKM' : 'Tervalidasi Otomatis',
                color: dibawahKkm ? AppColors.red : AppColors.green,
                background:
                    dibawahKkm ? AppColors.redLight : AppColors.greenLight,
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
