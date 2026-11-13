import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

/// Form tambah/edit soal. Jika [index] diisi -> mode edit soal ke-[index]
/// pada kuis [kuisId].
class SoalFormScreen extends StatefulWidget {
  final String kuisId;
  final int? index;
  const SoalFormScreen({super.key, required this.kuisId, this.index});

  @override
  State<SoalFormScreen> createState() => _SoalFormScreenState();
}

class _SoalFormScreenState extends State<SoalFormScreen> {
  late final TextEditingController pertanyaanCtrl;
  final TextEditingController aCtrl = TextEditingController();
  final TextEditingController bCtrl = TextEditingController();
  final TextEditingController cCtrl = TextEditingController();
  final TextEditingController dCtrl = TextEditingController();
  final TextEditingController eCtrl = TextEditingController();
  final TextEditingController jawabanEsaiCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  int jawaban = 0;
  Uint8List? gambar;
  String jenisSoal = Soal.pilihanGanda;

  bool get isEdit => widget.index != null;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final k = app.kuisById(widget.kuisId);
    final existing = (isEdit && k != null) ? k.soal[widget.index!] : null;
    String opsiAt(int i) =>
        (existing != null && i < existing.opsi.length) ? existing.opsi[i] : '';
    pertanyaanCtrl = TextEditingController(text: existing?.pertanyaan ?? '');
    aCtrl.text = opsiAt(0);
    bCtrl.text = opsiAt(1);
    cCtrl.text = opsiAt(2);
    dCtrl.text = opsiAt(3);
    eCtrl.text = opsiAt(4);
    jawaban = existing?.jawaban ?? 0;
    gambar = existing?.gambar;
    jenisSoal = existing?.jenis ?? Soal.pilihanGanda;
    jawabanEsaiCtrl.text = existing?.jawabanEsai ?? '';
  }

  @override
  void dispose() {
    pertanyaanCtrl.dispose();
    aCtrl.dispose();
    bCtrl.dispose();
    cCtrl.dispose();
    dCtrl.dispose();
    eCtrl.dispose();
    jawabanEsaiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => gambar = bytes);
    } on PlatformException {
      if (!mounted) return;
      showAppToast(context, 'Gagal mengambil gambar soal. Coba lagi.');
    }
  }

  void _simpan({bool selesai = false}) {
    if (pertanyaanCtrl.text.trim().isEmpty) {
      showAppToast(context, 'Pertanyaan wajib diisi');
      return;
    }
    if (jenisSoal == Soal.pilihanGanda &&
        (aCtrl.text.trim().isEmpty || bCtrl.text.trim().isEmpty)) {
      showAppToast(context, 'Opsi A & B wajib diisi');
      return;
    }
    if (jenisSoal == Soal.esai && jawabanEsaiCtrl.text.trim().isEmpty) {
      showAppToast(context, 'Kunci jawaban esai wajib diisi');
      return;
    }
    final soal = Soal(
      pertanyaan: pertanyaanCtrl.text,
      opsi: jenisSoal == Soal.pilihanGanda
          ? [
              aCtrl.text,
              bCtrl.text,
              cCtrl.text,
              dCtrl.text,
              if (eCtrl.text.trim().isNotEmpty) eCtrl.text,
            ]
          : const [],
      jawaban: jawaban,
      gambar: gambar,
      jenis: jenisSoal,
      jawabanEsai: jawabanEsaiCtrl.text.trim(),
    );
    final app = context.read<AppProvider>();
    if (isEdit) {
      app.editSoal(widget.kuisId, widget.index!, soal);
      showAppToast(context, 'Soal berhasil diperbarui ✔');
      Navigator.pop(context);
    } else {
      app.tambahSoal(widget.kuisId, soal);
      showAppToast(context, 'Soal berhasil ditambahkan ✔');
      if (selesai) {
        Navigator.pop(context);
        return;
      }
      pertanyaanCtrl.clear();
      aCtrl.clear();
      bCtrl.clear();
      cCtrl.clear();
      dCtrl.clear();
      eCtrl.clear();
      jawabanEsaiCtrl.clear();
      setState(() {
        jawaban = 0;
        gambar = null;
        jenisSoal = Soal.pilihanGanda;
      });
    }
  }

  void _selesai() {
    final adaIsianAktif = pertanyaanCtrl.text.trim().isNotEmpty ||
        (jenisSoal == Soal.esai
            ? jawabanEsaiCtrl.text.trim().isNotEmpty
            : [
                aCtrl,
                bCtrl,
                cCtrl,
                dCtrl,
                eCtrl,
              ].any((controller) => controller.text.trim().isNotEmpty));

    if (!isEdit && (adaIsianAktif || gambar != null)) {
      _simpan(selesai: true);
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final k = app.kuisById(widget.kuisId);

    return Scaffold(
      appBar: simpleAppBar(isEdit ? 'Edit Soal' : 'Tambah Soal'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple),
                onPressed: _simpan,
                child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Soal Berikutnya'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                  onPressed: _selesai, child: const Text('Selesai')),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (k != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text.rich(TextSpan(
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  children: [
                    const TextSpan(text: 'Kuis: '),
                    TextSpan(
                        text: k.judul,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700)),
                  ],
                )),
              ),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Pertanyaan / Butir Soal *'),
                    TextField(
                        controller: pertanyaanCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            hintText: 'Tulis pertanyaan kuis...')),
                    const SizedBox(height: 14),
                    _label('Gambar Soal (opsional)'),
                    if (gambar == null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pilihGambar,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Pilih gambar soal'),
                        ),
                      )
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          gambar!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pilihGambar,
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: const Text('Ganti gambar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => setState(() => gambar = null),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    _label('Jenis Soal'),
                    Row(
                      children: [
                        Expanded(
                          child: _jenisSoalButton(
                            label: Soal.pilihanGanda,
                            icon: Icons.checklist_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _jenisSoalButton(
                            label: Soal.esai,
                            icon: Icons.short_text_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (jenisSoal == Soal.pilihanGanda)
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
                            const Text('Pilihan Jawaban',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text(
                                'Tuliskan alternatif jawaban untuk opsi A hingga D (dan opsi E jika diperlukan). Klik opsi untuk menjadikannya jawaban benar.',
                                style: TextStyle(
                                    fontSize: 10.5, color: AppColors.muted)),
                            const SizedBox(height: 12),
                            _opsiField('A', 'Opsi pilihan A *', aCtrl, 0),
                            const SizedBox(height: 10),
                            _opsiField('B', 'Opsi pilihan B *', bCtrl, 1),
                            const SizedBox(height: 10),
                            _opsiField('C', 'Opsi pilihan C *', cCtrl, 2),
                            const SizedBox(height: 10),
                            _opsiField('D', 'Opsi pilihan D *', dCtrl, 3),
                            const SizedBox(height: 10),
                            _opsiField(
                                'E', 'Opsi pilihan E (opsional)', eCtrl, 4),
                            const SizedBox(height: 8),
                            Text(
                                '☀ Klik pada baris opsi untuk menjadikannya jawaban yang benar.',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade700)),
                          ]),
                    )
                    else
                      TextField(
                        controller: jawabanEsaiCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Kunci Jawaban Esai *',
                          hintText: 'Masukkan jawaban yang benar',
                        ),
                      ),
                  ]),
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

  Widget _jenisSoalButton({required String label, required IconData icon}) {
    final selected = jenisSoal == label;
    return OutlinedButton.icon(
      onPressed: () => setState(() => jenisSoal = label),
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : AppColors.blue,
        backgroundColor: selected ? AppColors.blue : Colors.white,
        side: BorderSide(color: selected ? AppColors.blue : AppColors.border),
      ),
    );
  }

  Widget _opsiField(
      String huruf, String hint, TextEditingController controller, int index) {
    final benar = jawaban == index;
    return GestureDetector(
      onTap: () => setState(() => jawaban = index),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: benar ? AppColors.green : AppColors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(huruf,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: benar ? AppColors.greenLight : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
