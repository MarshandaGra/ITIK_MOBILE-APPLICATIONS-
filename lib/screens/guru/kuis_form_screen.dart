import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/kuis.dart';
import '../../models/mapel_option.dart';
import '../../models/tahun_ajaran_option.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_detail_screen.dart';

class KuisFormScreen extends StatefulWidget {
  final String? kuisId;
  final String? initialMapelId;
  final String? initialMateriId;

  const KuisFormScreen({
    super.key,
    this.kuisId,
    this.initialMapelId,
    this.initialMateriId,
  });

  @override
  State<KuisFormScreen> createState() => _KuisFormScreenState();
}

class _KuisFormScreenState extends State<KuisFormScreen> {
  static const _difficultyLevels = ['mudah', 'sedang', 'sulit'];
  static const _categories = {
    'post-test': 'Post Test',
    'pre-test': 'Pre-Test',
    'kuis harian': 'Kuis Harian',
    'ulangan': 'Ulangan',
    'remedial': 'Remedial',
  };
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _waktuController;
  late final TextEditingController _kkmController;
  List<MapelOption> _mapelOptions = [];
  TahunAjaranOption? _tahunAjaranAktif;
  String? _idMapel;
  String? _tingkatKesulitan;
  String? _mapelError;
  String? _tahunAjaranError;
  bool _loadingMapel = true;
  bool _loadingTahunAjaran = true;
  String? _materiId;
  String? _idKuisAsal;
  String _kategori = 'kuis harian';
  DateTime? _waktuMulai;
  DateTime? _waktuSelesai;
  bool _saving = false;

  bool get isEdit => widget.kuisId != null;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final existing = isEdit ? app.kuisById(widget.kuisId!) : null;
    _judulController = TextEditingController(text: existing?.judul ?? '');
    _deskripsiController =
        TextEditingController(text: existing?.deskripsi ?? '');
    _waktuController = TextEditingController(
        text: '${existing?.waktu == 0 ? 10 : existing?.waktu ?? 10}');
    _kkmController = TextEditingController(
        text: '${existing?.kkm == 0 ? 75 : existing?.kkm ?? 75}');
    _idMapel = existing?.idMapel ?? widget.initialMapelId;
    final existingDifficulty = existing?.level.trim().toLowerCase();
    _tingkatKesulitan = _difficultyLevels.contains(existingDifficulty)
        ? existingDifficulty
        : 'mudah';
    _materiId = existing?.materiId ?? widget.initialMateriId;
    _idKuisAsal = existing?.idKuisAsal;
    final existingCategory = existing?.kategori.trim().toLowerCase();
    _kategori = _categories.containsKey(existingCategory)
        ? existingCategory!
        : 'kuis harian';
    _waktuMulai = existing?.waktuMulai;
    _waktuSelesai = existing?.waktuSelesai;
    _loadMapelOptions(_idMapel);
    _loadTahunAjaranAktif();
  }

  Future<void> _loadMapelOptions(String? currentId) async {
    setState(() {
      _loadingMapel = true;
      _mapelError = null;
    });
    try {
      final options = await context
          .read<AppProvider>()
          .loadMapelOptions(currentId: currentId);
      if (!mounted) return;
      setState(() {
        _mapelOptions = options;
        if (!options.any((mapel) => mapel.id == _idMapel)) {
          _idMapel = null;
        }
        _loadingMapel = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mapelError = 'Gagal memuat mata pelajaran: $error';
        _loadingMapel = false;
      });
    }
  }

  Future<void> _loadTahunAjaranAktif() async {
    setState(() {
      _loadingTahunAjaran = true;
      _tahunAjaranError = null;
    });
    try {
      final tahunAjaran =
          await context.read<AppProvider>().loadTahunAjaranAktif();
      if (!mounted) return;
      if (tahunAjaran == null ||
          tahunAjaran.id.isEmpty ||
          tahunAjaran.nama.isEmpty) {
        setState(() {
          _tahunAjaranError = 'Tahun ajaran aktif belum tersedia.';
          _loadingTahunAjaran = false;
        });
        return;
      }
      setState(() {
        _tahunAjaranAktif = tahunAjaran;
        _loadingTahunAjaran = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _tahunAjaranError = 'Gagal memuat tahun ajaran aktif: $error';
        _loadingTahunAjaran = false;
      });
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _waktuController.dispose();
    _kkmController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pilihTanggalWaktu(DateTime? current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 8, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Pilih tanggal dan waktu';
    final local = value.toLocal();
    final date = '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date • $time';
  }

  Future<void> _simpan() async {
    if (_saving) return;
    if (_loadingMapel ||
        _mapelError != null ||
        _loadingTahunAjaran ||
        _tahunAjaranError != null ||
        _tahunAjaranAktif == null) {
      showAppToast(
        context,
        'Data mata pelajaran atau tahun ajaran belum siap.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final app = context.read<AppProvider>();
    final waktu = int.tryParse(_waktuController.text) ?? 0;
    final kkm = int.tryParse(_kkmController.text) ?? 0;
    if (_kategori == 'ulangan' &&
        (_waktuMulai == null ||
            _waktuSelesai == null ||
            !_waktuSelesai!.isAfter(_waktuMulai!))) {
      showAppToast(context, 'Jadwal ulangan tidak valid.');
      return;
    }
    if (_kategori == 'remedial' && _idKuisAsal == null) {
      showAppToast(context, 'Kuis asal remedial wajib dipilih.');
      return;
    }

    final existing = isEdit ? app.kuisById(widget.kuisId!) : null;
    if (isEdit && existing == null) {
      showAppToast(context, 'Kuis tidak ditemukan. Muat ulang daftar kuis.');
      return;
    }
    if (existing?.statusPublikasi == 'terbit') {
      showAppToast(context, 'Kuis yang sudah terbit tidak dapat diedit.');
      return;
    }

    setState(() => _saving = true);
    try {
      final quiz = Kuis(
        id: existing?.id ?? '',
        judul: _judulController.text.trim(),
        materiId: _materiId ?? '',
        level: _tingkatKesulitan!,
        oleh: existing?.oleh ?? app.currentUser?.nama ?? '',
        tanggal: existing?.tanggal ?? '',
        waktu: waktu,
        kkm: kkm,
        soal: existing?.soal ?? <Soal>[],
        soalCount: existing?.soalCount,
        kategori: _kategori,
        deskripsi: _deskripsiController.text.trim(),
        idMapel: _idMapel,
        idTahunAjaran: existing?.idTahunAjaran ?? _tahunAjaranAktif!.id,
        idKuisAsal: _kategori == 'remedial' ? _idKuisAsal : null,
        statusPublikasi: existing?.statusPublikasi ?? 'draft',
        waktuMulai: _kategori == 'ulangan' ? _waktuMulai : null,
        waktuSelesai: _kategori == 'ulangan' ? _waktuSelesai : null,
      );

      if (isEdit) {
        await app.editKuis(widget.kuisId!, quiz);
        if (!mounted) return;
        showAppToast(context, 'Kuis berhasil diperbarui.');
        Navigator.pop(context);
      } else {
        final saved = await app.tambahKuis(quiz);
        if (!mounted) return;
        showAppToast(context, 'Kuis dibuat sebagai draft.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => KuisDetailScreen(kuisId: saved.id)),
        );
      }
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal menyimpan kuis: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final materiOptions =
        app.materiList.where((materi) => materi.idMapel == _idMapel).toList();
    final originQuizzes = app.kuisList
        .where((quiz) =>
            quiz.id != widget.kuisId &&
            quiz.kategori != 'remedial' &&
            quiz.statusPublikasi == 'terbit')
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Kembali'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isEdit ? 'Edit Kuis' : 'Tambah Kuis',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEdit
                    ? 'Perbarui informasi kuis, alokasi waktu, kriteria kelulusan, dan jadwal pelaksanaan.'
                    : 'Lengkapi informasi kuis, alokasi waktu, kriteria kelulusan, dan jadwal pelaksanaan.',
                style: const TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Formulir Edit Kuis' : 'Formulir Kuis',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tanda bintang (*) menandakan kolom wajib diisi.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    _label('Judul Kuis *'),
                    TextFormField(
                      controller: _judulController,
                      maxLength: 150,
                      decoration: const InputDecoration(
                          hintText: 'Contoh: Kuis Perangkat Lunak'),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Judul kuis wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _label('Deskripsi'),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Deskripsi singkat (opsional)'),
                    ),
                    const SizedBox(height: 14),
                    _label('Mata Pelajaran *'),
                    if (_loadingMapel)
                      const LinearProgressIndicator()
                    else if (_mapelError != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mapelError!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.red),
                          ),
                          TextButton(
                            onPressed: () => _loadMapelOptions(_idMapel),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      )
                    else
                      DropdownButtonFormField<String>(
                        initialValue:
                            _mapelOptions.any((item) => item.id == _idMapel)
                                ? _idMapel
                                : null,
                        items: _mapelOptions
                            .map((item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.nama),
                                ))
                            .toList(),
                        onChanged: _mapelOptions.isEmpty
                            ? null
                            : (value) => setState(() {
                                  _idMapel = value;
                                  if (_materiId != null &&
                                      app.materiById(_materiId!)?.idMapel !=
                                          value) {
                                    _materiId = null;
                                  }
                                }),
                        decoration: InputDecoration(
                          hintText: _mapelOptions.isEmpty
                              ? 'Mata pelajaran belum tersedia'
                              : 'Pilih mata pelajaran',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Mata pelajaran wajib dipilih.'
                            : null,
                      ),
                    const SizedBox(height: 14),
                    _label('Tahun Ajaran Aktif'),
                    if (_loadingTahunAjaran)
                      const LinearProgressIndicator()
                    else if (_tahunAjaranError != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tahunAjaranError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.red,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadTahunAjaranAktif,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      )
                    else
                      TextFormField(
                        key: ValueKey(_tahunAjaranAktif!.id),
                        initialValue: _tahunAjaranAktif!.nama,
                        enabled: false,
                        decoration: const InputDecoration(
                          hintText: 'Tahun ajaran aktif',
                        ),
                      ),
                    const SizedBox(height: 14),
                    _label('Tingkat Kesulitan *'),
                    DropdownButtonFormField<String>(
                      initialValue: _tingkatKesulitan,
                      items: _difficultyLevels
                          .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(
                                    '${level[0].toUpperCase()}${level.substring(1)}'),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _tingkatKesulitan = value),
                      decoration: const InputDecoration(
                        hintText: 'Pilih tingkat kesulitan',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Tingkat kesulitan wajib dipilih.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Materi Terkait *'),
                    DropdownButtonFormField<String>(
                      initialValue:
                          materiOptions.any((item) => item.id == _materiId)
                              ? _materiId
                              : null,
                      items: materiOptions
                          .map((item) => DropdownMenuItem(
                              value: item.id,
                              child: Text('${item.bab} — ${item.judul}',
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) => setState(() => _materiId = value),
                      decoration: InputDecoration(
                        hintText: materiOptions.isEmpty
                            ? 'Belum ada materi untuk mata pelajaran ini'
                            : 'Pilih materi terkait',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Materi terkait wajib dipilih.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _label('Kategori *'),
                    DropdownButtonFormField<String>(
                      initialValue: _kategori,
                      items: _categories.entries
                          .map((category) => DropdownMenuItem(
                              value: category.key, child: Text(category.value)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _kategori = value ?? 'kuis harian';
                        if (_kategori != 'remedial') _idKuisAsal = null;
                      }),
                      decoration: const InputDecoration(),
                    ),
                    if (_kategori == 'remedial') ...[
                      const SizedBox(height: 14),
                      _label('Kuis Asal *'),
                      DropdownButtonFormField<String>(
                        initialValue:
                            originQuizzes.any((item) => item.id == _idKuisAsal)
                                ? _idKuisAsal
                                : null,
                        items: originQuizzes
                            .map((item) => DropdownMenuItem(
                                value: item.id, child: Text(item.judul)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _idKuisAsal = value),
                        decoration: const InputDecoration(
                            hintText: 'Pilih kuis asal yang sudah terbit'),
                        validator: (value) => _kategori == 'remedial' &&
                                (value == null || value.isEmpty)
                            ? 'Kuis asal remedial wajib dipilih.'
                            : null,
                      ),
                    ],
                    if (_kategori == 'ulangan') ...[
                      const SizedBox(height: 14),
                      _label('Jadwal Ulangan *'),
                      OutlinedButton(
                        onPressed: () async {
                          final value = await _pilihTanggalWaktu(_waktuMulai);
                          if (value != null && mounted) {
                            setState(() => _waktuMulai = value);
                          }
                        },
                        child: Text('Mulai: ${_formatDateTime(_waktuMulai)}'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final value = await _pilihTanggalWaktu(_waktuSelesai);
                          if (value != null && mounted) {
                            setState(() => _waktuSelesai = value);
                          }
                        },
                        child:
                            Text('Selesai: ${_formatDateTime(_waktuSelesai)}'),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Alokasi Waktu (menit)'),
                              TextFormField(
                                controller: _waktuController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final number = int.tryParse(value ?? '');
                                  if (number == null ||
                                      number < 1 ||
                                      number > 300) {
                                    return 'Isi 1–300 menit.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('KKM (0–100)'),
                              TextFormField(
                                controller: _kkmController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  final number = num.tryParse(value ?? '');
                                  if (number == null ||
                                      number < 0 ||
                                      number > 100) {
                                    return 'Isi nilai 0–100.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kuis disimpan sebagai draft. Total bobot soal harus tepat 100 sebelum dapat dipublikasikan.',
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
                    : Text(isEdit
                        ? 'Simpan Perubahan'
                        : 'Buat Kuis & Tambah Soal'),
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
