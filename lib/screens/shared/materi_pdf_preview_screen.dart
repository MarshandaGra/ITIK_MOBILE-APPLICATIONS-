import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../models/materi.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class MateriPdfPreviewScreen extends StatefulWidget {
  const MateriPdfPreviewScreen({
    super.key,
    required this.materi,
    required this.pdfEndpoint,
  });

  final Materi materi;
  final String pdfEndpoint;

  @override
  State<MateriPdfPreviewScreen> createState() => _MateriPdfPreviewScreenState();
}

class _MateriPdfPreviewScreenState extends State<MateriPdfPreviewScreen> {
  Uint8List? _pdfBytes;
  PdfControllerPinch? _pdfController;
  String? _loadError;
  bool _loading = false;
  bool _downloading = false;
  int _currentPage = 1;
  int? _pageCount;

  @override
  void initState() {
    super.initState();
    if (widget.materi.pdfUrl?.isNotEmpty ?? false) {
      _loadPdf();
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    final oldController = _pdfController;
    _pdfController = null;
    oldController?.dispose();

    setState(() {
      _loading = true;
      _loadError = null;
      _pdfBytes = null;
      _pageCount = null;
      _currentPage = 1;
    });

    try {
      final api = context.read<AppProvider>().api;
      final bytes = await api
          .getPdf(widget.pdfEndpoint)
          .timeout(const Duration(seconds: 30));
      final controller = PdfControllerPinch(
        document: PdfDocument.openData(Uint8List.fromList(bytes)),
      );
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _pdfBytes = bytes;
        _pdfController = controller;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat PDF: $error';
        _loading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null || _downloading) return;
    if (bytes.isEmpty) {
      showAppToast(
          context, 'Data PDF kosong. Muat ulang pratinjau terlebih dahulu.');
      return;
    }

    setState(() => _downloading = true);
    try {
      final savedFile = await FilePicker.saveFile(
        fileName: _downloadFileName(),
        bytes: bytes,
        mimeType: 'application/pdf',
        dialogTitle: 'Unduh PDF Materi',
      );
      if (!mounted) return;
      if (kIsWeb) {
        showAppToast(
          context,
          'Unduhan dimulai. Periksa folder Unduhan browser.',
        );
      } else if (savedFile != null) {
        showAppToast(context, 'PDF berhasil disimpan.');
      } else {
        showAppToast(context, 'Unduhan dibatalkan.');
      }
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal mengunduh PDF: $error');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _downloadFileName() {
    final source = widget.materi.pdfName.isNotEmpty
        ? widget.materi.pdfName
        : '${widget.materi.judul}.pdf';
    final name = source.split(RegExp(r'[/\\]')).last;
    final safeName = name.replaceAll(RegExp(r'[<>:"|?*]'), '_');
    return safeName.toLowerCase().endsWith('.pdf') ? safeName : '$safeName.pdf';
  }

  void _onDocumentLoaded(PdfDocument document) {
    if (!mounted) return;
    setState(() => _pageCount = document.pagesCount);
  }

  void _onPageChanged(int page) {
    if (!mounted || page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  void _onDocumentError(Object error) {
    if (!mounted) return;
    setState(() => _loadError = 'Gagal membuka PDF: $error');
  }

  Future<void> _previousPage() async {
    final controller = _pdfController;
    if (controller == null) return;
    await controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _nextPage() async {
    final controller = _pdfController;
    if (controller == null) return;
    await controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final materi = widget.materi;
    final controller = _pdfController;

    return Scaffold(
      appBar: simpleAppBar('Pratinjau Materi'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              materi.judul,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              materi.pdfName.isNotEmpty ? materi.pdfName : 'PDF belum tersedia',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            MateriInformationCard(materi: materi),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed:
                    _pdfBytes == null || _downloading ? null : _downloadPdf,
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: const Text('Unduh PDF'),
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Isi Dokumen Materi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _PageCountBadge(count: _pageCount),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPdfPage(controller),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller == null ||
                                  _pageCount == null ||
                                  _currentPage <= 1
                              ? null
                              : _previousPage,
                          child: const Text('Kembali'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Halaman $_currentPage dari ${_pageCount ?? '—'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller == null ||
                                  _pageCount == null ||
                                  _currentPage >= _pageCount!
                              ? null
                              : _nextPage,
                          child: const Text('Selanjutnya'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPage(PdfControllerPinch? controller) {
    if (_loading) {
      return const SizedBox(
        height: 500,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return SizedBox(
        height: 500,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 36),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _loadPdf,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller == null) {
      return const SizedBox(
        height: 500,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.muted,
                  size: 42,
                ),
                SizedBox(height: 12),
                Text(
                  'File PDF belum tersedia.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Unggah dokumen PDF pada form materi untuk membacanya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: PdfViewPinch(
        controller: controller,
        scrollDirection: Axis.vertical,
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        onPageChanged: _onPageChanged,
        onDocumentLoaded: _onDocumentLoaded,
        onDocumentError: _onDocumentError,
      ),
    );
  }
}

class MateriInformationCard extends StatelessWidget {
  const MateriInformationCard({super.key, required this.materi});

  final Materi materi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Informasi Materi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (materi.kelas.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Kelas ${materi.kelas}',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _MateriInformationRow(
            label: 'Mata Pelajaran',
            value: materi.mataPelajaran?.isNotEmpty == true
                ? materi.mataPelajaran!
                : 'Mata pelajaran belum tersedia',
          ),
          const SizedBox(height: 12),
          _MateriInformationRow(
            label: 'Bab',
            value: materi.bab.isNotEmpty ? materi.bab : 'Belum ditentukan',
          ),
          const SizedBox(height: 12),
          _MateriInformationRow(
            label: 'Kelas',
            value: materi.kelas.isNotEmpty ? materi.kelas : 'Belum ditentukan',
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          const Text(
            'Deskripsi Materi',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            materi.deskripsi.isNotEmpty
                ? materi.deskripsi
                : 'Tidak ada deskripsi.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PageCountBadge extends StatelessWidget {
  const _PageCountBadge({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count == null ? '— halaman' : '$count halaman',
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MateriInformationRow extends StatelessWidget {
  const _MateriInformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
