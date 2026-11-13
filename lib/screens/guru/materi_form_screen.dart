import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/materi.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Form tambah/edit materi. Jika [materiId] diisi -> mode edit.
class MateriFormScreen extends StatefulWidget {
  final String? materiId;
  const MateriFormScreen({super.key, this.materiId});

  @override
  State<MateriFormScreen> createState() => _MateriFormScreenState();
}

class _MateriFormScreenState extends State<MateriFormScreen> {
  late final TextEditingController babCtrl;
  late final TextEditingController judulCtrl;
  late final TextEditingController deskripsiCtrl;
  late final TextEditingController kelasCtrl;
  late final TextEditingController youtubeCtrl;
  late String mataPelajaran;
  String? pdfNameTerpilih;

  bool get isEdit => widget.materiId != null;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final existing =
        widget.materiId != null ? app.materiById(widget.materiId!) : null;
    babCtrl = TextEditingController(text: existing?.bab ?? '');
    judulCtrl = TextEditingController(text: existing?.judul ?? '');
    deskripsiCtrl = TextEditingController(text: existing?.deskripsi ?? '');
    kelasCtrl = TextEditingController(text: existing?.kelas ?? 'X TKJ 1');
    youtubeCtrl = TextEditingController(text: existing?.youtubeUrl ?? '');
    mataPelajaran = app.currentUser?.mataPelajaran ??
        existing?.mataPelajaran ??
        MataPelajaranGuru.tik;
    pdfNameTerpilih = existing?.pdfName;
  }

  @override
  void dispose() {
    babCtrl.dispose();
    judulCtrl.dispose();
    deskripsiCtrl.dispose();
    kelasCtrl.dispose();
    youtubeCtrl.dispose();
    super.dispose();
  }

  void _pilihPdf() {
    // Placeholder pemilihan file — sambungkan ke paket `file_picker` saat
    // integrasi backend dilakukan.
    setState(() => pdfNameTerpilih =
        '${judulCtrl.text.isEmpty ? 'materi' : judulCtrl.text}.pdf');
    showAppToast(context, 'File PDF dipilih (contoh) ✔');
  }

  void _simpan() {
    if (judulCtrl.text.trim().isEmpty) {
      showAppToast(context, 'Judul materi wajib diisi');
      return;
    }
    final app = context.read<AppProvider>();
    if (isEdit) {
      final existing = app.materiById(widget.materiId!)!;
      app.editMateri(
        widget.materiId!,
        Materi(
          id: existing.id,
          bab: babCtrl.text,
          judul: judulCtrl.text,
          kelas: kelasCtrl.text.trim().isEmpty
              ? existing.kelas
              : kelasCtrl.text.trim(),
          deskripsi: deskripsiCtrl.text,
          isi: existing.isi,
          mataPelajaran: mataPelajaran,
          youtubeUrl: youtubeCtrl.text.trim(),
          gambar: existing.gambar,
          pdfName: pdfNameTerpilih ?? existing.pdfName,
          ukuran: existing.ukuran,
          oleh: existing.oleh,
          tanggal: existing.tanggal,
        ),
      );
      showAppToast(context, 'Materi berhasil diperbarui ✔');
    } else {
      final user = app.currentUser!;
      app.tambahMateri(Materi(
        id: 'M${DateTime.now().millisecondsSinceEpoch}',
        bab: babCtrl.text,
        judul: judulCtrl.text,
        kelas:
            kelasCtrl.text.trim().isEmpty ? 'X TKJ 1' : kelasCtrl.text.trim(),
        deskripsi: deskripsiCtrl.text,
        isi: deskripsiCtrl.text,
        mataPelajaran: mataPelajaran,
        youtubeUrl: youtubeCtrl.text.trim(),
        pdfName: pdfNameTerpilih ?? 'materi.pdf',
        ukuran: '—',
        oleh: user.nama,
        tanggal: 'Hari ini',
      ));
      showAppToast(context, 'Materi berhasil disimpan ✔');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final materi = isEdit ? app.materiById(widget.materiId!) : null;

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
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Kembali'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEdit ? 'Edit Materi' : 'Tambah Materi',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isEdit
                  ? 'Perbarui informasi dan dokumen materi pembelajaran.'
                  : 'Lengkapi formulir di bawah ini untuk menambahkan materi pembelajaran baru.',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit
                          ? 'Edit: ${materi?.judul ?? 'Materi'}'
                          : 'Formulir Materi Baru',
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
                    _label('Judul Materi *'),
                    TextField(
                        controller: judulCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Masukkan judul materi')),
                    const SizedBox(height: 14),
                    _label('Mata Pelajaran *'),
                    InputDecorator(
                      decoration: const InputDecoration(),
                      child: Text(mataPelajaran),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Bab'),
                              TextField(
                                  controller: babCtrl,
                                  decoration: const InputDecoration(
                                      hintText: 'Contoh: Bab 1')),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Kelas'),
                              TextField(
                                  controller: kelasCtrl,
                                  decoration: const InputDecoration(
                                      hintText: 'Contoh: X RPL 1')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label('Deskripsi Singkat'),
                    TextField(
                        controller: deskripsiCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            hintText: 'Ringkasan isi materi...')),
                    const SizedBox(height: 14),
                    _label('File Materi (PDF)'),
                    if (pdfNameTerpilih != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          const Icon(Icons.picture_as_pdf_rounded,
                              color: AppColors.red),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(pdfNameTerpilih!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis)),
                          IconButton(
                              onPressed: () =>
                                  setState(() => pdfNameTerpilih = null),
                              icon: const Icon(Icons.close, size: 18)),
                        ]),
                      )
                    else
                      InkWell(
                        onTap: _pilihPdf,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.border,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(children: [
                            Icon(Icons.upload_file_rounded,
                                color: AppColors.muted, size: 26),
                            SizedBox(height: 6),
                            Text('Pilih file PDF',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5)),
                            SizedBox(height: 2),
                            Text('Hanya format .pdf • maksimal 20 MB',
                                style: TextStyle(
                                    fontSize: 10.5, color: AppColors.muted)),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _label('Link YouTube Video Pembelajaran'),
                    TextField(
                      controller: youtubeCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          hintText: 'https://www.youtube.com/watch?v=...'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Opsional: tautkan video YouTube untuk penjelasan materi.',
                      style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                    ),
                  ]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _simpan,
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Materi'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
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

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}
