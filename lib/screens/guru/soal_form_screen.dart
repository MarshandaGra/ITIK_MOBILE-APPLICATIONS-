import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/kuis.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class SoalFormScreen extends StatefulWidget {
  final String kuisId;
  final int? index;

  const SoalFormScreen({super.key, required this.kuisId, this.index});

  @override
  State<SoalFormScreen> createState() => _SoalFormScreenState();
}

class _SoalFormScreenState extends State<SoalFormScreen> {
  static const _letters = ['A', 'B', 'C', 'D', 'E'];
  static const _maxImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _questionController;
  late final TextEditingController _weightController;
  late final List<TextEditingController> _optionControllers;
  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageUrl;
  int _answer = 0;
  String _questionType = Soal.pilihanGanda;
  bool _saving = false;

  bool get isEdit => widget.index != null;
  bool get _isEssay => _questionType == Soal.esai;

  @override
  void initState() {
    super.initState();
    final quiz = context.read<AppProvider>().kuisById(widget.kuisId);
    final existing = isEdit && quiz != null ? quiz.soal[widget.index!] : null;
    String optionAt(int index) =>
        existing != null && index < existing.opsi.length
            ? existing.opsi[index]
            : '';
    _questionController =
        TextEditingController(text: existing?.pertanyaan ?? '');
    _optionControllers = List.generate(
        5, (index) => TextEditingController(text: optionAt(index)));
    _weightController = TextEditingController(
      text: existing?.bobot.toString() ?? _defaultWeight(quiz),
    );
    _imageBytes = existing?.gambar;
    _imageName = existing?.gambarNamaFile;
    _imageUrl = existing?.gambarUrl;
    _answer = existing?.jawaban ?? 0;
    _questionType =
        existing?.jenis == Soal.esai ? Soal.esai : Soal.pilihanGanda;
  }

  String _defaultWeight(Kuis? quiz) {
    final remaining = 100 -
        (quiz?.soal
                .fold<double>(0, (total, question) => total + question.bobot) ??
            0);
    return (remaining > 0 ? remaining : 1).toStringAsFixed(2);
  }

  Future<void> _pilihGambar() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final extension = picked.name.toLowerCase().split('.').last;
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        if (mounted) {
          showAppToast(context, 'Format gambar harus JPG, PNG, atau WEBP.');
        }
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxImageBytes) {
        if (mounted) {
          showAppToast(context, 'Ukuran gambar maksimal 5 MB.');
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
        _imageUrl = null;
      });
    } on PlatformException {
      if (mounted) {
        showAppToast(context, 'Gagal mengambil gambar soal. Coba lagi.');
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _weightController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan({bool selesai = false}) async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final quiz = context.read<AppProvider>().kuisById(widget.kuisId);
    if (quiz == null) {
      showAppToast(context, 'Kuis tidak ditemukan. Muat ulang data.');
      return;
    }
    if (quiz.statusPublikasi != 'draft') {
      showAppToast(context, 'Soal pada kuis terbit tidak dapat diubah.');
      return;
    }
    if (!_isEssay && _optionControllers[_answer].text.trim().isEmpty) {
      showAppToast(context, 'Pilih opsi yang terisi sebagai jawaban benar.');
      return;
    }

    final soal = Soal(
      id: isEdit ? quiz.soal[widget.index!].id : null,
      pertanyaan: _questionController.text.trim(),
      opsi: _isEssay
          ? const []
          : _optionControllers
              .map((controller) => controller.text.trim())
              .toList(),
      jawaban: _answer,
      bobot: double.parse(_weightController.text),
      tingkatKesulitan: isEdit ? quiz.soal[widget.index!].tingkatKesulitan : '',
      gambar: _imageBytes,
      gambarNamaFile: _imageName,
      jenis: _questionType,
    );

    setState(() => _saving = true);
    try {
      final app = context.read<AppProvider>();
      if (isEdit) {
        await app.editSoal(widget.kuisId, widget.index!, soal);
      } else {
        await app.tambahSoal(widget.kuisId, soal);
      }
      if (!mounted) return;
      showAppToast(context,
          isEdit ? 'Soal berhasil diperbarui.' : 'Soal berhasil ditambahkan.');
      if (isEdit || selesai) {
        Navigator.pop(context);
      } else {
        for (final controller in _optionControllers) {
          controller.clear();
        }
        _questionController.clear();
        _formKey.currentState?.reset();
        setState(() {
          _answer = 0;
          _imageBytes = null;
          _imageName = null;
          _imageUrl = null;
          _questionType = Soal.pilihanGanda;
          _weightController.text = _defaultWeight(quiz);
        });
      }
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal menyimpan soal: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selesai() async {
    if (isEdit) {
      Navigator.pop(context);
      return;
    }

    final hasContent = _questionController.text.trim().isNotEmpty ||
        _imageBytes != null ||
        (!_isEssay &&
            _optionControllers
                .any((controller) => controller.text.trim().isNotEmpty));
    if (hasContent) {
      await _simpan(selesai: true);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<AppProvider>().kuisById(widget.kuisId);
    return Scaffold(
      appBar: simpleAppBar(isEdit ? 'Edit Soal' : 'Tambah Soal'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
                onPressed: _saving ? null : () => _simpan(),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Tambah Soal Berikutnya'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                  onPressed: _saving ? null : _selesai,
                  child: const Text('Selesai')),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (quiz != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Kuis: ${quiz.judul}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.muted)),
                ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Pertanyaan / Butir Soal *'),
                    TextFormField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Tulis pertanyaan kuis...'),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Pertanyaan wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Gambar Soal (opsional)'),
                    if (_imageBytes == null && _imageUrl == null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _pilihGambar,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Pilih gambar soal'),
                        ),
                      )
                    else ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _imageBytes != null
                            ? Image.memory(
                                _imageBytes!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                            : Image.network(
                                _imageUrl!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: Text(
                                      'Gambar gagal dimuat. Periksa URL dan akses storage publik.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _pilihGambar,
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: const Text('Ganti gambar'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_imageBytes != null)
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                        _imageBytes = null;
                                        _imageName = null;
                                      }),
                              child: const Text('Hapus'),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    _label('Jenis Soal *'),
                    Row(
                      children: [
                        Expanded(
                          child: _typeButton(
                            label: 'Pilihan Ganda',
                            type: Soal.pilihanGanda,
                            enabled: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _typeButton(
                            label: 'Esai',
                            type: Soal.esai,
                            enabled: _essayAllowed(quiz),
                          ),
                        ),
                      ],
                    ),
                    if (!_essayAllowed(quiz)) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Kategori pre-test dan post-test hanya mendukung pilihan ganda.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (!_isEssay)
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
                            const Text(
                              'Pilihan Jawaban',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Opsi A–D wajib diisi, opsi E opsional. Ketuk huruf opsi untuk memilih jawaban benar.',
                              style: TextStyle(
                                  fontSize: 10.5, color: AppColors.muted),
                            ),
                            const SizedBox(height: 12),
                            for (var index = 0;
                                index < _optionControllers.length;
                                index++) ...[
                              _opsiField(index),
                              if (index < _optionControllers.length - 1)
                                const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.green,
                                  size: 17,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kunci Jawaban: Opsi ${_letters[_answer]}',
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (_isEssay)
                      const Text(
                        'Jawaban siswa untuk soal esai akan dinilai oleh guru.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    const SizedBox(height: 14),
                    _label('Bobot (%) *'),
                    TextFormField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          hintText: 'Total bobot seluruh soal harus 100'),
                      validator: (value) {
                        final weight = double.tryParse(value ?? '');
                        if (weight == null || weight <= 0 || weight > 100) {
                          return 'Bobot harus lebih dari 0 sampai 100.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Total bobot semua soal harus tepat 100 agar kuis dapat dipublikasikan.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      );

  Widget _opsiField(int index) {
    final isCorrect = _answer == index;
    final letter = _letters[index];
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _answer = index),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.green : AppColors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _optionControllers[index],
            maxLength: 255,
            onTap: () => setState(() => _answer = index),
            decoration: InputDecoration(
              hintText:
                  'Opsi pilihan $letter${index < 4 ? ' *' : ' (opsional)'}',
              filled: true,
              fillColor: isCorrect ? AppColors.greenLight : Colors.white,
            ),
            validator: (value) => index < 4 && (value ?? '').trim().isEmpty
                ? 'Opsi $letter wajib diisi.'
                : null,
          ),
        ),
      ],
    );
  }

  bool _essayAllowed(Kuis? quiz) =>
      quiz?.kategori != 'pre-test' && quiz?.kategori != 'post-test';

  Widget _typeButton({
    required String label,
    required String type,
    required bool enabled,
  }) {
    final selected = _questionType == type;
    return OutlinedButton.icon(
      onPressed: enabled ? () => setState(() => _questionType = type) : null,
      icon: Icon(
        type == Soal.pilihanGanda
            ? Icons.checklist_rounded
            : Icons.short_text_rounded,
        size: 18,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : AppColors.blue,
        backgroundColor: selected ? AppColors.blue : Colors.white,
        side: BorderSide(
          color: selected ? AppColors.blue : AppColors.border,
        ),
      ),
      label: Text(label),
    );
  }
}
