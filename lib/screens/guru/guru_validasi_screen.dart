import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/hasil_kuis.dart';
import '../../models/kuis.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

enum _Filter { semua, lulus, tidakLulus }

class GuruValidasiScreen extends StatefulWidget {
  const GuruValidasiScreen({super.key});

  @override
  State<GuruValidasiScreen> createState() => _GuruValidasiScreenState();
}

class _GuruValidasiScreenState extends State<GuruValidasiScreen> {
  final _Filter _filter = _Filter.semua;
  String? _kelasTerpilih;
  bool _tampilkanSemuaKelas = false;
  String _kategori = 'Semua';
  String _percobaan = 'Semua';
  String _kelulusan = 'Semua';
  String _tanggal = 'Semua';

  List<String> _tanggalList(AppProvider app) {
    return ['Semua', ...app.hasilGuruSaatIni.map((h) => h.tanggal).toSet()];
  }

  List<HasilKuis> _filterData(AppProvider app, {String? kelas}) {
    final hasil = app.hasilGuruSaatIni;
    var list = switch (_filter) {
      _Filter.semua => [...hasil],
      _Filter.lulus => hasil.where((h) => !h.dibawahKkm).toList(),
      _Filter.tidakLulus => hasil.where((h) => h.dibawahKkm).toList(),
    };

    if (kelas != null) {
      final siswaIds = app.users
          .where((user) => user.role == UserRole.siswa && user.kelas == kelas)
          .map((user) => user.id)
          .toSet();
      list = list.where((hasil) => siswaIds.contains(hasil.siswaId)).toList();
    }
    if (_kategori != 'Semua') {
      list = list
          .where((h) => (h.remedial ? 'Remedial' : 'Kuis Harian') == _kategori)
          .toList();
    }
    if (_kelulusan != 'Semua') {
      list = list
          .where((h) => _kelulusan == 'Lulus' ? !h.dibawahKkm : h.dibawahKkm)
          .toList();
    }
    if (_tanggal != 'Semua') {
      list = list.where((h) => h.tanggal == _tanggal).toList();
    }
    if (_percobaan != 'Semua') {
      list = list.where((h) => _nomorPercobaan(app, h) == _percobaan).toList();
    }
    return list;
  }

  String _nomorPercobaan(AppProvider app, HasilKuis hasil) {
    final urutan = app.hasilGuruSaatIni.reversed
        .where((h) => h.siswaId == hasil.siswaId && h.kuisId == hasil.kuisId)
        .toList();
    final index = urutan.indexWhere((h) => h.id == hasil.id);
    return 'Ke-${index < 0 ? 1 : index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final hasilGuru = app.hasilGuruSaatIni;
    final kelasList = app.users
        .where((user) => user.role == UserRole.siswa && user.kelas != null)
        .map((user) => user.kelas!)
        .toSet()
        .toList()
      ..sort();
    final kelasTerpilih = _tampilkanSemuaKelas
        ? null
        : kelasList.contains(_kelasTerpilih)
            ? _kelasTerpilih
            : kelasList.isEmpty
                ? null
                : kelasList.first;
    final tampil = _filterData(app, kelas: kelasTerpilih);
    final percobaanList = {
      'Semua',
      ...hasilGuru.map((h) => _nomorPercobaan(app, h)),
    }.toList();
    final hasilKelas = kelasTerpilih == null
        ? hasilGuru
        : hasilGuru.where((hasil) {
            return app.users.any((user) =>
                user.id == hasil.siswaId && user.kelas == kelasTerpilih);
          }).toList();
    final kuisAktif =
        app.kuisGuruSaatIni.where((kuis) => kuis.isPublished).length;
    final rataKelas = hasilKelas.isEmpty
        ? 0.0
        : hasilKelas.fold<int>(0, (total, hasil) => total + hasil.nilai) /
            hasilKelas.length;

    return Scaffold(
      body: SafeArea(
        child: hasilGuru.isEmpty
            ? const EmptyState(text: 'Belum ada nilai kuis yang masuk.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                      if (app.currentUser != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            app.currentUser!.nama,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Daftar Nilai Siswa',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Pantau hasil pengerjaan kuis siswa per kelas dan berikan tugas remedial bagi yang belum lulus ulangan.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  if (kelasList.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      '🏫 PILIH KELAS PEMBELAJARAN',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 640;
                        final cards = List.generate(kelasList.length, (index) {
                          final kelas = kelasList[index];
                          final hasilKartu = hasilGuru.where((hasil) {
                            return app.users.any((user) =>
                                user.id == hasil.siswaId &&
                                user.kelas == kelas);
                          }).toList();
                          final avg = hasilKartu.isEmpty
                              ? 0.0
                              : hasilKartu.fold<int>(0,
                                      (total, hasil) => total + hasil.nilai) /
                                  hasilKartu.length;
                          return _KelasNilaiCard(
                            width: compact ? constraints.maxWidth : 246,
                            kelas: kelas,
                            siswa: app.users
                                .where((user) =>
                                    user.role == UserRole.siswa &&
                                    user.kelas == kelas)
                                .length,
                            materi: app.materiGuruSaatIni.where((materi) {
                              return materi.kelas
                                  .startsWith(kelas.split(' ').first);
                            }).length,
                            kuis: kuisAktif,
                            rataNilai: avg,
                            selected: kelas == kelasTerpilih,
                            onTap: () => setState(() {
                              _kelasTerpilih = kelas;
                              _tampilkanSemuaKelas = false;
                            }),
                          );
                        });

                        if (compact) {
                          return Column(
                            children: [
                              for (var index = 0; index < cards.length; index++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == cards.length - 1 ? 0 : 10,
                                  ),
                                  child: cards[index],
                                ),
                            ],
                          );
                        }

                        return SizedBox(
                          height: 240,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cards.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) => cards[index],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  _KelasTerpilihBanner(
                    kelas: kelasTerpilih,
                    jumlahSiswa: kelasTerpilih == null
                        ? app.users
                            .where((user) => user.role == UserRole.siswa)
                            .length
                        : app.users
                            .where((user) =>
                                user.role == UserRole.siswa &&
                                user.kelas == kelasTerpilih)
                            .length,
                    rataNilai: rataKelas,
                    onShowAll: kelasTerpilih == null
                        ? null
                        : () => setState(() {
                              _kelasTerpilih = null;
                              _tampilkanSemuaKelas = true;
                            }),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded,
                                size: 16, color: Color(0xFFF59E0B)),
                            SizedBox(width: 6),
                            Text(
                              'KLASIFIKASI & FILTER CEPAT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .6,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterCepat(
                              icon: Icons.sell_outlined,
                              label: 'Kategori',
                              value: _kategori,
                              values: const [
                                'Semua',
                                'Kuis Harian',
                                'Remedial'
                              ],
                              color: AppColors.blue,
                              onChanged: (v) => setState(() => _kategori = v),
                            ),
                            _FilterCepat(
                              icon: Icons.repeat_rounded,
                              label: 'Percobaan',
                              value: _percobaan,
                              values: percobaanList,
                              color: AppColors.blue,
                              onChanged: (v) => setState(() => _percobaan = v),
                            ),
                            _FilterCepat(
                              icon: Icons.school_outlined,
                              label: 'Kelulusan',
                              value: _kelulusan,
                              values: const ['Semua', 'Lulus', 'Tidak Lulus'],
                              color: AppColors.blue,
                              onChanged: (v) => setState(() => _kelulusan = v),
                            ),
                            _FilterCepat(
                              icon: Icons.calendar_month_outlined,
                              label: 'Tanggal',
                              value: _tanggal,
                              values: _tanggalList(app),
                              color: AppColors.blue,
                              onChanged: (v) => setState(() => _tanggal = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hasil Pengerjaan Kuis Siswa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Menampilkan ${tampil.length} dari ${hasilKelas.length} data pengerjaan kuis siswa',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  if (tampil.isEmpty)
                    const EmptyState(
                        text: 'Tidak ada hasil yang sesuai filter.')
                  else if (MediaQuery.sizeOf(context).width >= 1000)
                    _HasilNilaiTable(
                      hasil: tampil,
                      app: app,
                      nomorPercobaan: (hasil) => _nomorPercobaan(app, hasil),
                    )
                  else
                    ...tampil.map((h) => _ValidasiCard(
                          hasil: h,
                          app: app,
                          nomorPercobaan: _nomorPercobaan(app, h),
                        )),
                  const SizedBox(height: 20),
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

class _FilterCepat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> values;
  final Color color;
  final ValueChanged<String> onChanged;

  const _FilterCepat({
    required this.icon,
    required this.label,
    required this.value,
    required this.values,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: values.contains(value) ? value : values.first,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: values
              .map((v) => DropdownMenuItem<String>(
                    value: v,
                    child: Text(v),
                  ))
              .toList(),
          selectedItemBuilder: (context) => values.map((v) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text('$label:', style: const TextStyle(fontSize: 11.5)),
                const SizedBox(width: 4),
                Text(v,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _KelasNilaiCard extends StatelessWidget {
  final double width;
  final String kelas;
  final int siswa;
  final int materi;
  final int kuis;
  final double rataNilai;
  final bool selected;
  final VoidCallback onTap;

  const _KelasNilaiCard({
    required this.width,
    required this.kelas,
    required this.siswa,
    required this.materi,
    required this.kuis,
    required this.rataNilai,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        borderColor: selected ? AppColors.purple : null,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    kelas,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AppPill(
                  label: 'Tingkat ${kelas.split(' ').first}',
                  color: AppColors.purple,
                  background: AppColors.purpleLight,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _KelasMetric(label: 'Siswa', value: '$siswa')),
                const SizedBox(width: 8),
                Expanded(
                    child: _KelasMetric(label: 'Materi', value: '$materi')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _KelasMetric(label: 'Kuis Aktif', value: '$kuis')),
                const SizedBox(width: 8),
                Expanded(
                  child: _KelasMetric(
                    label: 'Rata Nilai',
                    value: rataNilai.toStringAsFixed(1),
                    valueColor: rataNilai > 0 && rataNilai < 75
                        ? AppColors.orange
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 5),
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
                  selected ? Icons.close_rounded : Icons.arrow_forward_rounded,
                  size: 15,
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
  final String Function(HasilKuis) nomorPercobaan;

  const _HasilNilaiTable({
    required this.hasil,
    required this.app,
    required this.nomorPercobaan,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
              AppColors.purpleLight.withValues(alpha: .4)),
          columns: const [
            DataColumn(label: Text('NO')),
            DataColumn(label: Text('SISWA')),
            DataColumn(label: Text('KUIS')),
            DataColumn(label: Text('KATEGORI')),
            DataColumn(label: Text('PERCOBAAN')),
            DataColumn(label: Text('NILAI')),
            DataColumn(label: Text('KKM')),
            DataColumn(label: Text('KELULUSAN')),
            DataColumn(label: Text('TANGGAL')),
            DataColumn(label: Text('AKSI')),
          ],
          rows: List.generate(hasil.length, (index) {
            final item = hasil[index];
            final siswa =
                app.users.where((user) => user.id == item.siswaId).firstOrNull;
            return DataRow(
              cells: [
                DataCell(Text('${index + 1}')),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.siswa,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'NISN: ${siswa?.induk ?? '-'}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      item.kuis,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  AppPill(
                    label: item.remedial ? 'Remedial' : 'Kuis Harian',
                    color: item.remedial ? AppColors.orange : AppColors.blue,
                    background: item.remedial
                        ? AppColors.orangeLight
                        : AppColors.blueLight,
                  ),
                ),
                DataCell(Text(nomorPercobaan(item))),
                DataCell(
                  Text(
                    '${item.nilai}',
                    style: TextStyle(
                      color: item.dibawahKkm ? AppColors.red : AppColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                DataCell(Text('${item.kkm}')),
                DataCell(
                  AppPill(
                    label: item.dibawahKkm ? '⚠ Tidak Lulus' : '✓ Lulus',
                    color: item.dibawahKkm ? AppColors.orange : AppColors.green,
                    background: item.dibawahKkm
                        ? AppColors.orangeLight
                        : AppColors.greenLight,
                  ),
                ),
                DataCell(Text(item.tanggal)),
                DataCell(
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _HasilDetailScreen(
                          hasil: item,
                          nomorPercobaan: nomorPercobaan(item),
                        ),
                      ),
                    ),
                    child: const Text('Lihat Detail'),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ValidasiCard extends StatelessWidget {
  final HasilKuis hasil;
  final AppProvider app;
  final String nomorPercobaan;
  const _ValidasiCard({
    required this.hasil,
    required this.app,
    required this.nomorPercobaan,
  });

  Future<void> _tugaskanRemedial(BuildContext context) async {
    final ok = await confirmDialog(context,
        'Tugaskan kuis remedial "${hasil.kuis}" untuk ${hasil.siswa}?\n\nSiswa akan melihat notifikasi di Beranda untuk mengerjakan ulang.');
    if (ok) {
      app.tugaskanRemedial(hasil.id);
      if (context.mounted) {
        showAppToast(context, 'Remedial ditugaskan ke ${hasil.siswa} ✔');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = hasil;
    final dibawahKkm = h.dibawahKkm;
    final kuisRef = app.kuisById(h.kuisId);
    final alokasi = kuisRef?.waktu ?? 10;
    final rasio = h.durasi / (alokasi * 60);
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
                Text('${h.nilai}',
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
                      label: '↓ KKM ${h.kkm}',
                      color: AppColors.red,
                      background: AppColors.redLight)
                  : AppPill(
                      label: '✔ KKM ${h.kkm}',
                      color: AppColors.green,
                      background: AppColors.greenLight),
              Text('⏱ ${fmtWaktu(h.durasi)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              AppPill(
                  label: kecepatanLabel,
                  color: kecepatanColor,
                  background: kecepatanColor.withValues(alpha: .12)),
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
                        ? OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.red,
                                side: const BorderSide(
                                    color: AppColors.redLight)),
                            onPressed: () {
                              app.batalkanRemedial(h.id);
                              showAppToast(
                                  context, 'Penugasan remedial dibatalkan');
                            },
                            icon: const Icon(Icons.close_rounded, size: 17),
                            label: const Text('Batalkan Remedial',
                                style: TextStyle(fontSize: 12.5)),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red),
                            onPressed: () => _tugaskanRemedial(context),
                            icon: const Icon(Icons.trending_up, size: 17),
                            label: const Text('Tugaskan Remedial',
                                style: TextStyle(fontSize: 12.5)),
                          ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _HasilDetailScreen(
                      hasil: h,
                      nomorPercobaan: nomorPercobaan,
                    ),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Lihat Detail'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HasilDetailScreen extends StatelessWidget {
  final HasilKuis hasil;
  final String nomorPercobaan;

  const _HasilDetailScreen({
    required this.hasil,
    required this.nomorPercobaan,
  });

  Future<void> _tugaskanRemedial(
    BuildContext context,
    AppProvider app,
  ) async {
    final ok = await confirmDialog(
      context,
      'Tugaskan kuis remedial "${hasil.kuis}" untuk ${hasil.siswa}?',
    );
    if (ok) {
      app.tugaskanRemedial(hasil.id);
      if (context.mounted) {
        showAppToast(context, 'Remedial ditugaskan ke ${hasil.siswa} ✔');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final h = hasil;
    final kuis = app.kuisById(h.kuisId);
    final siswa = app.users.where((user) => user.id == h.siswaId).firstOrNull;
    final soal = kuis?.soal ?? const <Soal>[];
    final benar = h.benar.clamp(0, soal.length);
    final salah = (soal.length - benar).clamp(0, soal.length);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 15),
                  label: const Text('Kembali'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Detail Nilai Siswa',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Detail hasil pengerjaan kuis siswa dan evaluasi butir soal.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final dataSiswa = _InfoHasilCard(
                  title: 'Data Siswa',
                  items: [
                    ('Nama Lengkap', h.siswa),
                    ('NISN', siswa?.induk ?? '-'),
                    ('Kelas', siswa?.kelas ?? '-'),
                  ],
                );
                final dataKuis = AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Data Kuis',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          AppPill(
                            label: h.remedial
                                ? 'Remedial'
                                : kuis?.kategori ?? 'Kuis Harian',
                            color:
                                h.remedial ? AppColors.orange : AppColors.blue,
                            background: h.remedial
                                ? AppColors.orangeLight
                                : AppColors.blueLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoHasilItem(label: 'Judul Kuis', value: h.kuis),
                      const SizedBox(height: 12),
                      _InfoHasilItem(
                        label: 'Percobaan',
                        value: nomorPercobaan,
                      ),
                      const SizedBox(height: 12),
                      _InfoHasilItem(
                        label: 'Nilai Akhir',
                        value: '${h.nilai}',
                        valueColor: AppColors.purple,
                        valueSize: 22,
                      ),
                      const SizedBox(height: 12),
                      _InfoHasilItem(label: 'KKM Kuis', value: '${h.kkm}'),
                      const SizedBox(height: 12),
                      _InfoHasilItem(
                        label: 'Status Kelulusan',
                        value: h.dibawahKkm ? '⚠ Tidak Lulus' : '✓ Lulus',
                        valueColor:
                            h.dibawahKkm ? AppColors.orange : AppColors.green,
                      ),
                      if (h.dibawahKkm) ...[
                        const SizedBox(height: 12),
                        if (h.remedialSelesai)
                          const _StaticBadge(
                            label: 'Remedial Selesai',
                            color: AppColors.green,
                            bg: AppColors.greenLight,
                          )
                        else if (h.remedialDitugaskan)
                          const _StaticBadge(
                            label: 'Remedial Ditugaskan',
                            color: AppColors.green,
                            bg: AppColors.greenLight,
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                              ),
                              onPressed: () => _tugaskanRemedial(context, app),
                              icon: const Icon(
                                Icons.trending_up_rounded,
                                size: 16,
                              ),
                              label: const Text('Tugaskan Remedial'),
                            ),
                          ),
                      ],
                    ],
                  ),
                );

                if (constraints.maxWidth >= 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: dataSiswa),
                      const SizedBox(width: 16),
                      Expanded(child: dataKuis),
                    ],
                  );
                }
                return Column(
                  children: [
                    dataSiswa,
                    const SizedBox(height: 12),
                    dataKuis,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Evaluasi Jawaban Siswa per Butir Soal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daftar butir soal, jawaban yang dipilih siswa, serta kunci jawaban sistem.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _NilaiStat(
                        value: '$benar',
                        label: 'Jawaban Benar',
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 8),
                      _NilaiStat(
                        value: '$salah',
                        label: 'Jawaban Salah',
                        color: AppColors.red,
                      ),
                      const SizedBox(width: 8),
                      _NilaiStat(
                        value: '${soal.length}',
                        label: 'Total Butir Soal',
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (soal.isEmpty)
              const EmptyState(text: 'Data butir soal tidak tersedia.')
            else
              ...List.generate(soal.length, (index) {
                final butir = soal[index];
                final pilihan =
                    index < h.jawabanSiswa.length ? h.jawabanSiswa[index] : -1;
                final isCorrect = butir.jenis == Soal.pilihanGanda &&
                    pilihan == butir.jawaban;
                final bobot = 100 / soal.length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EvaluasiButirCard(
                    nomor: index + 1,
                    soal: butir,
                    pilihanSiswa: pilihan,
                    jawabanEsaiSiswa: index < h.jawabanEsaiSiswa.length
                        ? h.jawabanEsaiSiswa[index]
                        : '',
                    benar: isCorrect,
                    bobot: bobot,
                  ),
                );
              }),
            const SizedBox(height: 16),
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

class _InfoHasilCard extends StatelessWidget {
  final String title;
  final List<(String, String)> items;

  const _InfoHasilCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          ...items.indexed.expand((entry) => [
                _InfoHasilItem(label: entry.$2.$1, value: entry.$2.$2),
                if (entry.$1 < items.length - 1) const SizedBox(height: 12),
              ]),
        ],
      ),
    );
  }
}

class _InfoHasilItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double valueSize;

  const _InfoHasilItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.text,
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NilaiStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _NilaiStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.purpleLight.withValues(alpha: .28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
              ),
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
