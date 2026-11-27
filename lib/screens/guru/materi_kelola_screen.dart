import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/materi.dart';
import '../../models/mapel_option.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'materi_form_screen.dart';
import 'materi_view_screen.dart';

class MateriKelolaScreen extends StatefulWidget {
  const MateriKelolaScreen({super.key});

  @override
  State<MateriKelolaScreen> createState() => _MateriKelolaScreenState();
}

class _MateriKelolaScreenState extends State<MateriKelolaScreen> {
  List<MapelOption> _mapelOptions = [];
  String? _selectedMapelId;
  String? _mapelError;
  bool _loadingMapel = true;

  @override
  void initState() {
    super.initState();
    _loadMapelOptions();
  }

  Future<void> _loadMapelOptions() async {
    setState(() {
      _loadingMapel = true;
      _mapelError = null;
    });
    try {
      final options = await context.read<AppProvider>().loadMapelOptions();
      if (!mounted) return;
      setState(() {
        _mapelOptions = options;
        if (!options.any((mapel) => mapel.id == _selectedMapelId)) {
          _selectedMapelId = null;
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
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final selectedMapel = _mapelOptions
        .where((mapel) => mapel.id == _selectedMapelId)
        .firstOrNull;
    final materi = selectedMapel == null
        ? <Materi>[]
        : app.materiList
            .where((item) => item.idMapel == selectedMapel.id)
            .toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMapelOptions,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              if (selectedMapel == null)
                _buildMapelPicker(app)
              else
                _buildMateriList(selectedMapel, materi, app),
              const SizedBox(height: 12),
              const Text(
                'ITIK · Portal Guru — Media Pembelajaran TIK',
                style: TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: selectedMapel == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.purple,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MateriFormScreen(initialMapelId: selectedMapel.id),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Tambahkan Materi'),
            ),
    );
  }

  Widget _buildMapelPicker(AppProvider app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Materi Pembelajaran',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Muat ulang mata pelajaran',
              onPressed: _loadingMapel ? null : _loadMapelOptions,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih mata pelajaran untuk melihat dan mengelola materi pembelajaran siswa.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (_loadingMapel) const LinearProgressIndicator(),
        if (_mapelError != null) ...[
          Text(
            _mapelError!,
            style: const TextStyle(color: AppColors.red, fontSize: 13),
          ),
          TextButton(
            onPressed: _loadingMapel ? null : _loadMapelOptions,
            child: const Text('Coba lagi'),
          ),
        ],
        if (!_loadingMapel && _mapelOptions.isEmpty && _mapelError == null)
          const EmptyState(text: 'Belum ada mata pelajaran yang tersedia.'),
        if (_mapelOptions.isNotEmpty) ...[
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                runSpacing: 14,
                children: _mapelOptions.map((mapel) {
                  final count = app.materiList
                      .where((item) => item.idMapel == mapel.id)
                      .length;
                  return SizedBox(
                    width: constraints.maxWidth,
                    child: SubjectSelectionCard(
                      mapel: mapel,
                      detail: '$count Materi Pembelajaran',
                      icon: Icons.auto_stories_rounded,
                      onTap: () => setState(() => _selectedMapelId = mapel.id),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMateriList(
    MapelOption mapel,
    List<Materi> materi,
    AppProvider app,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MapelBackButton(
          onPressed: () => setState(() => _selectedMapelId = null),
        ),
        const SizedBox(height: 10),
        SubjectSummaryBanner(
          title: mapel.nama,
          detail: '${materi.length} materi pembelajaran tersedia',
        ),
        const SizedBox(height: 14),
        SectionTitle('Materi Pembelajaran (${materi.length})'),
        if (materi.isEmpty)
          const EmptyState(
            text:
                'Belum ada materi untuk mata pelajaran ini.\nTekan tombol di bawah untuk menambahkan.',
          )
        else
          ...materi.indexed.map(
            (entry) => _MateriManageCard(
              materi: entry.$2,
              app: app,
            ),
          ),
      ],
    );
  }
}

class _MateriManageCard extends StatelessWidget {
  final Materi materi;
  final AppProvider app;
  const _MateriManageCard({
    required this.materi,
    required this.app,
  });

  Future<void> _hapus(BuildContext context) async {
    final ok = await confirmDialog(context,
        'Hapus "${materi.judul}"?\n\nTindakan ini tidak dapat dibatalkan.');
    if (ok) {
      try {
        await app.hapusMateri(materi.id);
        if (context.mounted) showAppToast(context, 'Materi telah dihapus');
      } catch (error) {
        if (context.mounted) {
          showAppToast(context, 'Gagal menghapus materi: $error');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = materi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MateriSelectionCard(
        materi: m,
        icon: Icons.menu_book_rounded,
        footer: [
          if (m.kelas.isNotEmpty) 'Kelas ${m.kelas}',
          if (m.pdfName.isNotEmpty) 'PDF: ${m.pdfName}',
        ].join(' • '),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MateriViewScreen(materiId: m.id)),
        ),
        actions: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MateriViewScreen(materiId: m.id),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Lihat', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MateriFormScreen(materiId: m.id),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.redLight),
                ),
                onPressed: () => _hapus(context),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Hapus', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
