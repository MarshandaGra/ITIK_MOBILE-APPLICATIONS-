import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/materi.dart';
import '../../models/mapel_option.dart';
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController babCtrl;
  late final TextEditingController judulCtrl;
  late final TextEditingController kelasCtrl;
  late final TextEditingController deskripsiCtrl;
  late final TextEditingController youtubeCtrl;
  List<MapelOption> _mapelOptions = [];
  String? _idMapel;
  String? _mapelError;
  bool _loadingMapel = true;
  PlatformFile? _selectedPdf;
  bool _saving = false;

  bool get isEdit => widget.materiId != null;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final existing =
        widget.materiId != null ? app.materiById(widget.materiId!) : null;
    babCtrl = TextEditingController(text: existing?.bab ?? '');
    judulCtrl = TextEditingController(text: existing?.judul ?? '');
    kelasCtrl = TextEditingController(text: existing?.kelas ?? '');
    deskripsiCtrl = TextEditingController(text: existing?.deskripsi ?? '');
    youtubeCtrl = TextEditingController(text: existing?.linkYoutube ?? '');
    _idMapel = existing?.idMapel;
    _loadMapelOptions(existing?.idMapel);
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

  @override
  void dispose() {
    babCtrl.dispose();
    judulCtrl.dispose();
    kelasCtrl.dispose();
    deskripsiCtrl.dispose();
    youtubeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihPdf() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || file == null) return;
      if (file.extension?.toLowerCase() != 'pdf') {
        showAppToast(context, 'File materi harus berformat PDF.');
        return;
      }
      final fileSize = await file.length();
      if (!mounted) return;
      if (fileSize == null) {
        showAppToast(context, 'Ukuran file PDF tidak dapat dibaca.');
        return;
      }
      if (fileSize > 10 * 1024 * 1024) {
        showAppToast(context, 'Ukuran file PDF maksimal 10 MB.');
        return;
      }

      setState(() => _selectedPdf = file);
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal memilih PDF: $error');
    }
  }

  Future<void> _simpan() async {
    if (_saving) return;
    if (_loadingMapel || _mapelError != null) {
      showAppToast(context, 'Mata pelajaran belum berhasil dimuat.');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final app = context.read<AppProvider>();
    final existing = isEdit ? app.materiById(widget.materiId!) : null;
    if (isEdit && existing == null) {
      showAppToast(
          context, 'Materi tidak ditemukan. Muat ulang daftar materi.');
      return;
    }
    setState(() => _saving = true);
    try {
      final materi = Materi(
        id: existing?.id ?? '',
        bab: babCtrl.text.trim(),
        judul: judulCtrl.text.trim(),
        kelas: kelasCtrl.text.trim(),
        deskripsi: deskripsiCtrl.text.trim(),
        isi: existing?.isi ?? '',
        idMapel: _idMapel,
        linkYoutube:
            youtubeCtrl.text.trim().isEmpty ? null : youtubeCtrl.text.trim(),
        pdfName: existing?.pdfName ?? '',
        ukuran: existing?.ukuran ?? '',
        oleh: existing?.oleh ?? '',
        tanggal: existing?.tanggal ?? '',
      );
      final pdfBytes = await _selectedPdf?.readAsBytes();
      if (isEdit) {
        await app.editMateri(
          widget.materiId!,
          materi,
          pdfBytes: pdfBytes,
          pdfName: _selectedPdf?.name,
        );
      } else {
        await app.tambahMateri(
          materi,
          pdfBytes: pdfBytes,
          pdfName: _selectedPdf?.name,
        );
      }
      if (!mounted) return;
      showAppToast(
        context,
        isEdit ? 'Materi berhasil diperbarui ✔' : 'Materi berhasil disimpan ✔',
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal menyimpan materi: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(isEdit ? 'Edit Materi' : 'Tambah Materi Baru'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(2, 8, 2, 14),
                child: Text(
                  'Lengkapi formulir di bawah ini untuk menambahkan materi pembelajaran baru.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ),
              AppCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? 'Formulir Edit Materi'
                            : 'Formulir Materi Baru',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tanda bintang (*) menandakan kolom wajib diisi.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(height: 16),
                      _label('Judul Materi *'),
                      TextFormField(
                        controller: judulCtrl,
                        maxLength: 150,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan judul materi',
                        ),
                        validator: (value) {
                          final judul = (value ?? '').trim();
                          if (judul.isEmpty) return 'Judul materi wajib diisi.';
                          if (judul.length > 150) {
                            return 'Judul materi maksimal 150 karakter.';
                          }
                          return null;
                        },
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
                              _mapelOptions.any((mapel) => mapel.id == _idMapel)
                                  ? _idMapel
                                  : null,
                          items: _mapelOptions
                              .map((mapel) => DropdownMenuItem(
                                    value: mapel.id,
                                    child: Text(mapel.nama),
                                  ))
                              .toList(),
                          onChanged: _mapelOptions.isEmpty
                              ? null
                              : (value) => setState(() => _idMapel = value),
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
                      _label('Bab'),
                      TextFormField(
                        controller: babCtrl,
                        maxLength: 50,
                        decoration:
                            const InputDecoration(hintText: 'Contoh: Bab 1'),
                        validator: (value) {
                          if ((value ?? '').trim().length > 50) {
                            return 'Bab maksimal 50 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _label('Kelas'),
                      TextFormField(
                        controller: kelasCtrl,
                        maxLength: 50,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: X RPL 1',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length > 50) {
                            return 'Kelas maksimal 50 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _label('Deskripsi'),
                      TextFormField(
                        controller: deskripsiCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Masukkan ringkasan atau deskripsi materi...',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('File PDF Materi'),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pilihPdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(_selectedPdf == null
                            ? 'Pilih file PDF'
                            : _selectedPdf!.name),
                      ),
                      const Text(
                        'Unggah file PDF materi (maksimal 10 MB). Siswa dapat langsung membaca PDF ini di portal pembelajaran.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      if (_selectedPdf == null &&
                          isEdit &&
                          (context
                                  .watch<AppProvider>()
                                  .materiById(widget.materiId!)
                                  ?.pdfName
                                  .isNotEmpty ??
                              false))
                        Text(
                          'PDF saat ini: ${context.watch<AppProvider>().materiById(widget.materiId!)!.pdfName}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      if (_selectedPdf == null &&
                          isEdit &&
                          context
                                  .watch<AppProvider>()
                                  .materiById(widget.materiId!)
                                  ?.pdfUrl !=
                              null)
                        SelectableText(
                          context
                              .watch<AppProvider>()
                              .materiById(widget.materiId!)!
                              .pdfUrl!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted),
                        ),
                      if (_selectedPdf != null)
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _selectedPdf = null),
                          child: const Text('Hapus pilihan'),
                        ),
                      const SizedBox(height: 14),
                      _label('Link YouTube Video Pembelajaran'),
                      TextFormField(
                        controller: youtubeCtrl,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'https://www.youtube.com/watch?v=...',
                        ),
                        validator: (value) {
                          final link = (value ?? '').trim();
                          if (link.isEmpty) return null;
                          if (link.length > 255) {
                            return 'Link YouTube maksimal 255 karakter.';
                          }
                          final uri = Uri.tryParse(link);
                          if (uri == null ||
                              !uri.hasScheme ||
                              !['http', 'https'].contains(uri.scheme) ||
                              uri.host.isEmpty) {
                            return 'Masukkan URL YouTube yang valid.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Opsional: tautkan video YouTube untuk membantu penjelasan materi.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ]),
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
                    : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Materi'),
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

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(s,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}
