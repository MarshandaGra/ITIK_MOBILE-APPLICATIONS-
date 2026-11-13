import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_detail_screen.dart';

const kategoriKuisOptions = [
  'Latihan',
  'Remedial',
  'Ulangan Harian',
  'Penilaian Tengah Semester',
  'Penilaian Akhir Semester',
];

/// Form tambah/edit kuis. Jika [kuisId] diisi -> mode edit.
class KuisFormScreen extends StatefulWidget {
  final String? kuisId;
  const KuisFormScreen({super.key, this.kuisId});

  @override
  State<KuisFormScreen> createState() => _KuisFormScreenState();
}

class _KuisFormScreenState extends State<KuisFormScreen> {
  final TextEditingController judulCtrl = TextEditingController();
  final TextEditingController waktuCtrl = TextEditingController(text: '10');
  final TextEditingController kkmCtrl = TextEditingController(text: '75');
  final TextEditingController deskripsiCtrl = TextEditingController();
  final TextEditingController tahunAjaranCtrl =
      TextEditingController(text: '2026/2027');
  Uint8List? gambar;
  String? materiId;
  String level = 'Mudah';
  String? kategori;
  DateTime? tanggalTerbit;
  DateTime? tanggalSelesai;
  static const levels = ['Mudah', 'Sedang', 'Sulit'];

  bool get isEdit => widget.kuisId != null;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final existing =
        widget.kuisId != null ? app.kuisById(widget.kuisId!) : null;
    judulCtrl.text = existing?.judul ?? '';
    waktuCtrl.text = '${existing?.waktu ?? 10}';
    kkmCtrl.text = '${existing?.kkm ?? 75}';
    deskripsiCtrl.text = existing?.deskripsi ?? '';
    tahunAjaranCtrl.text = existing?.tahunAjaran ?? '2026/2027';
    final materiGuru = app.materiGuruSaatIni;
    materiId = existing?.materiId ??
        (materiGuru.isNotEmpty ? materiGuru.first.id : null);
    level = existing?.level ?? 'Mudah';
    kategori = existing?.kategori;
    gambar = existing?.gambar;
    tanggalTerbit = existing?.tanggalTerbit ?? DateTime.now();
    tanggalSelesai = existing?.tanggalSelesai;
  }

  @override
  void dispose() {
    judulCtrl.dispose();
    waktuCtrl.dispose();
    kkmCtrl.dispose();
    deskripsiCtrl.dispose();
    tahunAjaranCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    if (judulCtrl.text.trim().isEmpty) {
      showAppToast(context, 'Judul kuis wajib diisi');
      return;
    }
    final waktu = int.tryParse(waktuCtrl.text) ?? 0;
    final kkm = int.tryParse(kkmCtrl.text) ?? 0;
    if (waktu < 1) {
      showAppToast(context, 'Durasi kuis wajib diisi (minimal 1 menit)');
      return;
    }
    if (kkm < 1 || kkm > 100) {
      showAppToast(context, 'KKM wajib diisi, antara 1-100');
      return;
    }
    if (tanggalSelesai != null &&
        tanggalTerbit != null &&
        tanggalSelesai!.isBefore(tanggalTerbit!)) {
      showAppToast(context, 'Waktu selesai harus setelah waktu terbit');
      return;
    }
    tanggalTerbit ??= DateTime.now();
    final app = context.read<AppProvider>();
    if (app.materiGuruSaatIni.isEmpty) {
      showAppToast(context,
          'Tambahkan materi untuk mata pelajaran Anda terlebih dahulu');
      return;
    }
    if (isEdit) {
      app.editKuisMeta(
        widget.kuisId!,
        judul: judulCtrl.text,
        materiId: materiId ?? '',
        level: level,
        waktu: waktu,
        kkm: kkm,
        deskripsi: deskripsiCtrl.text,
        gambar: gambar,
        tahunAjaran: tahunAjaranCtrl.text,
        kategori: kategori,
        tanggalTerbit: tanggalTerbit,
        tanggalSelesai: tanggalSelesai,
      );
      showAppToast(context, 'Kuis berhasil diperbarui ✔');
      Navigator.pop(context);
    } else {
      final id = 'K${DateTime.now().millisecondsSinceEpoch}';
      app.tambahKuis(Kuis(
        id: id,
        judul: judulCtrl.text,
        materiId: materiId ?? '',
        level: level,
        oleh: app.currentUser!.nama,
        tanggal: 'Hari ini',
        waktu: waktu,
        kkm: kkm,
        deskripsi: deskripsiCtrl.text,
        gambar: gambar,
        tahunAjaran: tahunAjaranCtrl.text,
        kategori: kategori,
        tanggalTerbit: tanggalTerbit,
        tanggalSelesai: tanggalSelesai,
        soal: [],
        isPublished: false,
      ));
      showAppToast(
          context, 'Kuis disimpan sebagai draft. Silakan tambahkan soal ✔');
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => KuisDetailScreen(kuisId: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final materiGuru = app.materiGuruSaatIni;
    final selectedMateriId =
        materiGuru.any((materi) => materi.id == materiId) ? materiId : null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: const Text('Kembali'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEdit ? 'Edit Kuis' : 'Tambah Kuis Baru',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isEdit
                  ? 'Perbarui informasi kuis, alokasi waktu, kriteria kelulusan, dan jadwal pelaksanaan.'
                  : 'Atur parameter penilaian, tingkat kesulitan, alokasi waktu, dan jadwal kuis.',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Formulir Edit Kuis' : 'Formulir Kuis Baru',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tanda bintang (*) menandakan kolom wajib diisi.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _label('Judul Kuis *'),
                    TextField(
                        controller: judulCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Contoh: Kuis Perangkat Lunak')),
                    const SizedBox(height: 14),
                    _label('Deskripsi Kuis'),
                    TextField(
                      controller: deskripsiCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText:
                              'Masukkan penjelasan atau deskripsi kuis...'),
                    ),
                    const SizedBox(height: 14),
                    _label('Mata Pelajaran *'),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMateriId,
                      isExpanded: true,
                      items: materiGuru
                          .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.mataPelajaran ?? 'TIK',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => materiId = v),
                      decoration: const InputDecoration(),
                    ),
                    if (materiGuru.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Buat materi untuk mata pelajaran Anda sebelum membuat kuis.',
                          style: TextStyle(fontSize: 11, color: AppColors.red),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _label('Tahun Ajaran'),
                    TextField(controller: tahunAjaranCtrl),
                    const SizedBox(height: 4),
                    const Text('Diisi otomatis dari tahun ajaran aktif.',
                        style:
                            TextStyle(fontSize: 9.5, color: AppColors.muted)),
                    const SizedBox(height: 14),
                    _label('Tingkat Kesulitan *'),
                    DropdownButtonFormField<String>(
                      initialValue: level,
                      isExpanded: true,
                      items: levels
                          .map(
                              (l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setState(() => level = v ?? 'Mudah'),
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 14),
                    _label('Kategori Kuis *'),
                    DropdownButtonFormField<String>(
                      initialValue: kategori,
                      isExpanded: true,
                      hint: const Text('-- Pilih Kategori --'),
                      items: kategoriKuisOptions
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: (v) => setState(() => kategori = v),
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 14),
                    _label('Alokasi Waktu (menit)'),
                    TextField(
                        controller: waktuCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: 'Contoh: 60')),
                    const SizedBox(height: 14),
                    _label('KKM (Kriteria Ketuntasan Minimal)'),
                    TextField(
                        controller: kkmCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(hintText: 'Contoh: 75')),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📅 Jadwal Terbit & Selesai Otomatis',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text(
                                'Jadwal opsional. Tentukan tanggal dan jam untuk menerbitkan kuis secara otomatis.',
                                style: TextStyle(
                                    fontSize: 9.5, color: AppColors.muted)),
                            const SizedBox(height: 10),
                            _tanggalField(
                              'Tanggal & Waktu Terbit Otomatis',
                              tanggalTerbit,
                              (v) => setState(() => tanggalTerbit = v),
                              readOnly: true,
                              placeholder: 'Diisi otomatis saat kuis dibuat',
                            ),
                            const SizedBox(height: 10),
                            _tanggalField(
                              'Tanggal & Waktu Selesai',
                              tanggalSelesai,
                              (v) => setState(() => tanggalSelesai = v),
                              placeholder: 'mm/dd/yyyy --:--',
                            ),
                          ]),
                    ),
                  ]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              onPressed: _simpan,
              child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Kuis'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            const SizedBox(height: 18),
            const Text(
              'ITIK · Portal Guru — Media Pembelajaran TIK',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tanggalField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onSelected, {
    bool readOnly = false,
    String placeholder = 'mm/dd/yyyy --:--',
  }) {
    final text =
        value == null ? '' : DateFormat('dd/MM/yyyy HH:mm').format(value);

    Future<void> pickDateTime() async {
      if (!mounted) return;

      final date = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );
      if (!mounted) return;
      if (date == null) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value ?? date),
      );
      if (!mounted) return;
      if (time == null) return;

      onSelected(DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5)),
        const SizedBox(height: 4),
        InkWell(
          onTap: readOnly ? null : pickDateTime,
          child: InputDecorator(
            decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_month_outlined)),
            child: Text(
              text.isEmpty ? placeholder : text,
              style: TextStyle(
                  fontSize: 11,
                  color: text.isEmpty ? AppColors.muted : AppColors.text),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s,
            softWrap: true,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}
