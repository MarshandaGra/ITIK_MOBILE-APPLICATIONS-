import 'package:flutter/material.dart';
import '../../models/kuis.dart';
import '../../models/hasil_kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_level_screen.dart';

class KuisResultScreen extends StatelessWidget {
  final Kuis kuis;
  final double nilai;
  final int benar;
  final int salah; //baru
  final List<int> jawabanSiswa; //baru
  final bool serverGraded;
  final String? resultStatusLabel;

  const KuisResultScreen({
    super.key,
    required this.kuis,
    required this.nilai,
    required this.benar,
    required this.salah,
    required this.jawabanSiswa,
    this.serverGraded = false,
    this.resultStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final good = kuis.kkm > 0 && nilai >= kuis.kkm;
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: good ? AppColors.greenLight : AppColors.orangeLight,
                  shape: BoxShape.circle,
                ),
                child: Text(formatSkor(nilai),
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: good ? AppColors.green : AppColors.orange)),
              ),
            ),
            const SizedBox(height: 18),
            Text(good ? 'Kerja Bagus!' : 'Terus Berlatih!',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
                serverGraded
                    ? 'Nilai kuis ${kuis.judul} dihitung dan disimpan oleh server.'
                    : 'Kamu menjawab benar $benar dari ${kuis.soal.length} soal pada ${kuis.judul}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 18),
            AppCard(
              child: Column(children: [
                _row(
                    'Kuis',
                    Text(kuis.judul,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700))),
                const Divider(height: 22),
                _row('Tingkat Kesulitan', LevelPill(level: kuis.level)),
                const Divider(height: 22),
                _row(
                    'KKM',
                    Text('${kuis.kkm}',
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700))),
                const Divider(height: 22),
                if (!serverGraded) ...[
                  _row(
                      'Soal Benar',
                      Text('$benar',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700))),
                  const Divider(height: 22),
                  _row(
                      'Soal Salah',
                      Text('$salah',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700))),
                  const Divider(height: 22),
                ],
                _row(
                    'Status',
                    serverGraded
                        ? AppPill(
                            label: good
                                ? 'Lulus Otomatis'
                                : resultStatusLabel ?? 'Menunggu Validasi',
                            color: good
                                ? AppColors.green
                                : const Color(0xFFB9701C),
                            background: good
                                ? AppColors.greenLight
                                : const Color(0xFFFFF1E2))
                        : good
                            ? const AppPill(
                                label: 'Lulus Otomatis',
                                color: AppColors.green,
                                background: AppColors.greenLight)
                            : const AppPill(
                                label: 'Menunggu Validasi',
                                color: Color(0xFFB9701C),
                                background: Color(0xFFFFF1E2))),
              ]),
            ),
            if (!good) ...[
              const SizedBox(height: 14),
              NoticeBox(
                title: 'Nilai di Bawah KKM',
                message:
                    'Nilai kamu (${formatSkor(nilai)}) belum mencapai KKM (${kuis.kkm}). Pelajari kembali materinya — gurumu akan meninjau nilai ini dan menugaskan kuis remedial jika diperlukan. Pantau notifikasi di Beranda.',
              ),
            ],

            // ---------- Daftar Soal Salah ----------
            if (!serverGraded && salah > 0) ...[
              const SizedBox(height: 18),
              const Text('Pembahasan Soal yang Salah',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...List.generate(kuis.soal.length, (i) {
                final s = kuis.soal[i];
                final jawabUser =
                    i < jawabanSiswa.length ? jawabanSiswa[i] : -1;
                final salahSoalIni = jawabUser != s.jawaban;
                if (!salahSoalIni) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Soal ${i + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text(s.pertanyaan,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          jawabUser == -1
                              ? 'Kamu tidak menjawab soal ini.'
                              : 'Jawabanmu: ${letters[jawabUser]}. ${s.opsi[jawabUser]}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.red),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Jawaban benar: ${letters[s.jawaban]}. ${s.opsi[s.jawaban]}',
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.green,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const KuisLevelScreen())),
              child: const Text('Kerjakan Kuis Lain'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, Widget value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          value
        ],
      );
}
