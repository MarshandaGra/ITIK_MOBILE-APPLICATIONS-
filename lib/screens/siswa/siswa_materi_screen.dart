import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/materi.dart';
import '../../models/mapel_option.dart';
import '../../providers/app_provider.dart';
import '../../providers/a11y_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'materi_detail_screen.dart';

class SiswaMateriScreen extends StatefulWidget {
  const SiswaMateriScreen({super.key});

  @override
  State<SiswaMateriScreen> createState() => _SiswaMateriScreenState();
}

class _SiswaMateriScreenState extends State<SiswaMateriScreen> {
  String? _selectedMapelId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final counts = <String, int>{};
    for (final materi in app.materiList) {
      final idMapel = materi.idMapel;
      if (idMapel != null && idMapel.isNotEmpty) {
        counts.update(idMapel, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final mapelOptions = app.siswaMapelOptions
        .where((mapel) => (counts[mapel.id] ?? 0) > 0)
        .toList();
    MapelOption? selectedMapel;
    for (final mapel in mapelOptions) {
      if (mapel.id == _selectedMapelId) {
        selectedMapel = mapel;
        break;
      }
    }
    final selectedMapelValue = selectedMapel;
    final selectedMateri = selectedMapelValue == null
        ? const <Materi>[]
        : app.materiList
            .where((materi) => materi.idMapel == selectedMapelValue.id)
            .toList();

    return Scaffold(
      appBar: simpleAppBar('Materi Pembelajaran'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: app.loadRemoteData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (app.materiLoadError != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Materi gagal dimuat.'),
                      const SizedBox(height: 8),
                      Text(
                        app.materiLoadError!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                      TextButton.icon(
                        onPressed: app.materiLoading
                            ? null
                            : () => app.loadRemoteData(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              if (app.materiLoading && app.materiList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (!app.materiLoading)
                if (selectedMapel == null) ...[
                  const Text(
                    'Pilih mata pelajaran untuk melihat materi yang tersedia.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  if (app.materiList.isEmpty && app.materiLoadError == null)
                    const AppCard(
                      child: Text('Belum ada materi yang tersedia.'),
                    )
                  else if (app.materiList.isNotEmpty)
                    MapelSelectionList(
                      mapelOptions: mapelOptions,
                      counts: counts,
                      itemLabel: 'materi',
                      icon: Icons.menu_book_rounded,
                      iconColor: AppColors.blue,
                      iconBackground: AppColors.blueLight,
                      detailBuilder: (_, count) => '$count Materi Pembelajaran',
                      onSelect: (mapel) =>
                          setState(() => _selectedMapelId = mapel.id),
                    ),
                ] else ...[
                  MapelBackButton(
                    onPressed: () => setState(() => _selectedMapelId = null),
                  ),
                  const SizedBox(height: 10),
                  SubjectSummaryBanner(
                    title: selectedMapel.nama,
                    detail:
                        '${selectedMateri.length} materi pembelajaran tersedia',
                  ),
                  const SizedBox(height: 14),
                  if (selectedMateri.isEmpty)
                    const EmptyState(
                      text: 'Belum ada materi untuk mata pelajaran ini.',
                    )
                  else
                    ...selectedMateri.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MateriSelectionCard(
                          materi: m,
                          icon: Icons.menu_book_rounded,
                          footer: _materiFooter(m),
                          badges: [
                            if (app.isMateriSelesai(m.id))
                              const AppPill(
                                label: 'Selesai',
                                color: AppColors.green,
                                background: AppColors.greenLight,
                              ),
                          ],
                          footerAction: TextButton(
                            onPressed: () => _bukaMateri(context, m),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.purple,
                            ),
                            child: const Text('Buka Materi →'),
                          ),
                          onTap: () => _bukaMateri(context, m),
                        ),
                      ),
                    ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  String _materiFooter(Materi materi) {
    final details = [
      if (materi.pdfName.isNotEmpty) materi.pdfName,
      if (materi.ukuran.isNotEmpty) materi.ukuran,
    ];
    return details.isEmpty ? 'Materi pembelajaran' : details.join(' • ');
  }

  void _bukaMateri(BuildContext context, Materi materi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MateriDetailScreen(materiId: materi.id),
      ),
    );
    final a11y = context.read<A11yProvider>();
    if (a11y.autoRead) {
      a11y.speakPage('${materi.bab}. ${materi.judul}.');
    }
  }
}
