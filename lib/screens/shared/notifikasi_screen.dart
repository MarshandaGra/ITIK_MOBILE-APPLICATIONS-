import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user.dart';
import '../../models/hasil_kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../siswa/kuis_play_screen.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;

    // Antisipasi: user belum ter-load / sudah logout
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isSiswa = user.role == UserRole.siswa;
    final List<HasilKuis> items = isSiswa
        ? app.hasilList
            .where((h) =>
                app.milikSiswaIni(h) &&
                h.remedialDitugaskan &&
                !h.remedialSelesai)
            .toList()
        // Guru: nilai di bawah KKM yang belum mendapat penugasan remedial.
        : app.hasilGuruSaatIni
            .where((h) =>
                h.dibawahKkm && !h.remedialDitugaskan && !h.remedialSelesai)
            .toList();

    return Scaffold(
      appBar: simpleAppBar('Notifikasi'),
      body: SafeArea(
        child: items.isEmpty
            ? const EmptyState(text: 'Belum ada notifikasi baru.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.blueLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: AppColors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Aktivitas Terbaru',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${items.length} notifikasi perlu ditinjau',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final h = items[i - 1];
                  if (isSiswa) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NoticeBox(
                        title: 'Remedial Ditugaskan Guru',
                        color: AppColors.red,
                        background: AppColors.redLight,
                        borderColor: const Color(0xFFF6C6C8),
                        message:
                            'Nilai kamu (${h.nilai}) pada ${h.kuis} belum mencapai KKM (${h.kkm}). Gurumu menugaskan kamu mengerjakan ulang kuis ini.',
                        action: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.red),
                            onPressed: () {
                              final kuis = app.kuisById(h.kuisId);
                              if (kuis != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KuisPlayScreen(
                                        kuis: kuis, remedialOfId: h.id),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.trending_up, size: 18),
                            label: const Text('Kerjakan Remedial Sekarang'),
                          ),
                        ),
                      ),
                    );
                  }
                  return _GuruNotifikasiCard(h: h, app: app);
                },
              ),
      ),
    );
  }
}

class _GuruNotifikasiCard extends StatelessWidget {
  final HasilKuis h;
  final AppProvider app;

  const _GuruNotifikasiCard({required this.h, required this.app});

  Future<void> _tugaskanRemedial(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      'Tugaskan remedial "${h.kuis}" untuk ${h.siswa}?',
    );
    if (ok) {
      app.tugaskanRemedial(h.id);
      if (context.mounted) {
        showAppToast(context, 'Remedial ditugaskan ke ${h.siswa}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D3557).withValues(alpha: .05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_late_outlined,
                  color: AppColors.red,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.siswa,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${h.tanggal}  •  ${h.kuis}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 58),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${h.nilai}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => _tugaskanRemedial(context),
              icon: const Icon(Icons.trending_up, size: 19),
              label: const Text(
                'Tugaskan Remedial',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
