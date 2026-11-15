import 'package:flutter/material.dart';
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
  static const _difficultyLevels = ['mudah', 'sedang', 'sulit'];
  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _weightController;
  late final List<TextEditingController> _optionControllers;
  int _answer = 0;
  String? _difficulty;
  bool _saving = false;

  bool get isEdit => widget.index != null;

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
    _answer = existing?.jawaban ?? 0;
    _difficulty = _difficultyLevels.contains(existing?.tingkatKesulitan)
        ? existing!.tingkatKesulitan
        : null;
  }

  String _defaultWeight(Kuis? quiz) {
    final remaining = 100 -
        (quiz?.soal
                .fold<double>(0, (total, question) => total + question.bobot) ??
            0);
    return (remaining > 0 ? remaining : 1).toStringAsFixed(2);
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

  Future<void> _simpan() async {
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

    final soal = Soal(
      id: isEdit ? quiz.soal[widget.index!].id : null,
      pertanyaan: _questionController.text.trim(),
      opsi: _optionControllers
          .map((controller) => controller.text.trim())
          .toList(),
      jawaban: _answer,
      bobot: double.parse(_weightController.text),
      tingkatKesulitan: _difficulty ?? '',
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
      Navigator.pop(context);
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal menyimpan soal: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<AppProvider>().kuisById(widget.kuisId);
    return Scaffold(
      appBar: simpleAppBar(isEdit ? 'Edit Soal' : 'Tambah Soal'),
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
                    _label('Pertanyaan *'),
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
                    for (var index = 0;
                        index < _optionControllers.length;
                        index++) ...[
                      _label('Opsi ${_letters[index]}${index < 4 ? ' *' : ''}'),
                      TextFormField(
                        controller: _optionControllers[index],
                        maxLength: 255,
                        validator: (value) =>
                            index < 4 && (value ?? '').trim().isEmpty
                                ? 'Opsi ${_letters[index]} wajib diisi.'
                                : null,
                      ),
                      if (index < _optionControllers.length - 1)
                        const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    _label('Jawaban Benar *'),
                    DropdownButtonFormField<int>(
                      initialValue: _answer,
                      items: List.generate(
                        5,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: Text('Opsi ${_letters[index]}'),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _answer = value ?? 0),
                      validator: (value) => value == 4 &&
                              _optionControllers[4].text.trim().isEmpty
                          ? 'Isi opsi E atau pilih jawaban A–D.'
                          : null,
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
                    const SizedBox(height: 14),
                    _label('Tingkat Kesulitan'),
                    DropdownButtonFormField<String?>(
                      initialValue: _difficulty,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('-- Sesuai Kuis / Bebas --'),
                        ),
                        ..._difficultyLevels.map(
                          (level) => DropdownMenuItem<String?>(
                            value: level,
                            child: Text(level),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _difficulty = value),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Opsi A–D wajib diisi, opsi E opsional. Total bobot soal harus tepat 100 agar kuis dapat dipublikasikan.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
                onPressed: _saving ? null : _simpan,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Soal'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal')),
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
}
