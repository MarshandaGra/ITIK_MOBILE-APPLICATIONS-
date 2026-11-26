import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_play_screen.dart';

class KuisLevelScreen extends StatefulWidget {
  const KuisLevelScreen({super.key});

  @override
  State<KuisLevelScreen> createState() => _KuisLevelScreenState();
}

class _KuisLevelScreenState extends State<KuisLevelScreen> {
  String? _startingKuisId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppProvider>().loadKuisData();
    });
  }

  Future<void> _mulaiKuis(AppProvider app, String kuisId) async {
    if (_startingKuisId != null) return;
    setState(() => _startingKuisId = kuisId);
    try {
      final kuis = await app.mulaiKuisSiswa(kuisId);
      if (!mounted) return;
      if (kuis.soal.isEmpty) {
        showAppToast(context, 'Kuis ini belum memiliki soal.');
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KuisPlayScreen(kuis: kuis, serverManaged: true),
        ),
      );
    } catch (error) {
      if (mounted) showAppToast(context, 'Gagal membuka kuis: $error');
    } finally {
      if (mounted) setState(() => _startingKuisId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final riwayat = app.riwayatSiswaSaatIni;

    return Scaffold(
      appBar: simpleAppBar('Daftar Kuis'),
      body: SafeArea(
        child: RefreshIndicator(
            onRefresh: app.loadKuisData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                const Text(
                    'Pilih kuis sesuai bab materi yang telah kamu pelajari.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                const SizedBox(height: 14),
                if (app.kuisLoadError != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kuis gagal dimuat.'),
                        const SizedBox(height: 8),
                        Text(
                          app.kuisLoadError!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                        TextButton.icon(
                          onPressed:
                              app.kuisLoading ? null : () => app.loadKuisData(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                if (app.kuisLoading && app.kuisList.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!app.kuisLoading &&
                    app.kuisLoadError == null &&
                    app.kuisList.isEmpty)
                  const AppCard(
                    child: Text(
                      'Belum ada kuis yang diterbitkan guru. Kuis draft belum tampil untuk siswa.',
                    ),
                  ),
                ...app.kuisList.map((k) {
                  final m = app.materiById(k.materiId);

                  // Semua percobaan siswa ini pada kuis tersebut
                  final percobaan =
                      riwayat.where((h) => h.kuisId == k.id).toList();
                  final sudahDikerjakan = percobaan.isNotEmpty;
                  final nilaiTerbaik = sudahDikerjakan
                      ? percobaan
                          .map((h) => h.nilai)
                          .reduce((a, b) => a > b ? a : b)
                      : 0;
                  final lulus = sudahDikerjakan && nilaiTerbaik >= k.kkm;

                  final subtitle =
                      '${m?.judul ?? 'Tanpa materi terkait'} • ${k.jumlahSoal} soal • KKM ${k.kkm}'
                      '${sudahDikerjakan ? ' • Nilai $nilaiTerbaik' : ''}';

                  return AppListItem(
                    icon: Icons.quiz_rounded,
                    iconColor: AppColors.orange,
                    iconBg: AppColors.orangeLight,
                    title: k.judul,
                    subtitle: subtitle,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_startingKuisId == k.id) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (sudahDikerjakan) ...[
                          Icon(
                            lulus
                                ? Icons.check_circle
                                : Icons.error_outline_rounded,
                            color: lulus ? AppColors.green : AppColors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                        ],
                        LevelPill(level: k.level),
                      ],
                    ),
                    onTap: () {
                      _mulaiKuis(app, k.id);
                    },
                  );
                }),
              ],
            )),
      ),
    );
  }
}
