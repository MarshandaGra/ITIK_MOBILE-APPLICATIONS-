import 'package:flutter/material.dart';
import '../../models/kuis.dart';
import '../../theme/app_theme.dart';
import 'kuis_level_screen.dart';
import 'kuis_play_screen.dart';

class KuisResultScreen extends StatelessWidget {
  final Kuis kuis;
  final int nilai;
  final int benar;
  final int salah;
  final List<int> jawabanSiswa;
  final List<String> jawabanEsaiSiswa;

  const KuisResultScreen({
    super.key,
    required this.kuis,
    required this.nilai,
    required this.benar,
    required this.salah,
    required this.jawabanSiswa,
    this.jawabanEsaiSiswa = const [],
  });

  @override
  Widget build(BuildContext context) {
    final lulus = nilai >= kuis.kkm;
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Kembali',
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const KuisLevelScreen()),
                  ),
                  child: const Text('Daftar Kuis'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                border: Border.all(color: const Color(0xFFC8EBD8)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.green, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lulus
                          ? 'Kuis berhasil dikumpulkan. Selamat, kamu lulus!'
                          : 'Kuis berhasil dikumpulkan. Pelajari evaluasi jawabanmu.',
                      style: const TextStyle(
                          color: Color(0xFF256747), fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Hasil Kuis',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(kuis.judul,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 700;
                final scoreCard = _ScoreCard(
                  nilai: nilai,
                  lulus: lulus,
                  benar: benar,
                  salah: salah,
                  jumlahSoal: kuis.soal.length,
                  kkm: kuis.kkm,
                );
                final detailCard = _DetailCard(kuis: kuis);
                if (!wide) {
                  return Column(
                    children: [
                      scoreCard,
                      const SizedBox(height: 12),
                      detailCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: scoreCard),
                    const SizedBox(width: 14),
                    Expanded(child: detailCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Evaluasi Soal',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                    'Pelajari setiap jawaban untuk mengevaluasi pemahamanmu.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(kuis.soal.length, (i) {
                    final soal = kuis.soal[i];
                    final jawaban =
                        i < jawabanSiswa.length ? jawabanSiswa[i] : -1;
                    final jawabanEsai =
                        i < jawabanEsaiSiswa.length ? jawabanEsaiSiswa[i] : '';
                    final benarSoal = soal.jenis == Soal.esai
                        ? _jawabanEsaiBenar(jawabanEsai, soal.jawabanEsai)
                        : jawaban == soal.jawaban;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: i == kuis.soal.length - 1 ? 0 : 12),
                      child: _QuestionReview(
                        nomor: i + 1,
                        bobot: kuis.soal.isEmpty ? 0 : 100 / kuis.soal.length,
                        soal: soal,
                        benar: benarSoal,
                        letters: letters,
                        jawabanSiswa: jawaban,
                        jawabanEsaiSiswa: jawabanEsai,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => KuisPlayScreen(kuis: kuis)),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kerjakan Ulang Kuis'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const KuisLevelScreen()),
              ),
              child: const Text('Lihat Daftar Kuis'),
            ),
          ],
        ),
      ),
    );
  }

  static bool _jawabanEsaiBenar(String jawaban, String kunci) {
    String normalize(String value) =>
        value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return normalize(jawaban) == normalize(kunci);
  }
}

class _ScoreCard extends StatelessWidget {
  final int nilai;
  final bool lulus;
  final int benar;
  final int salah;
  final int jumlahSoal;
  final int kkm;

  const _ScoreCard({
    required this.nilai,
    required this.lulus,
    required this.benar,
    required this.salah,
    required this.jumlahSoal,
    required this.kkm,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = lulus ? AppColors.green : AppColors.red;
    final statusBg = lulus ? AppColors.greenLight : AppColors.redLight;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Text('Nilai Akhir Kamu',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            nilai.toStringAsFixed(2),
            style: TextStyle(
              color: statusColor,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          _Badge(
            label: lulus ? 'Lulus (KKM $kkm)' : 'Belum lulus (KKM $kkm)',
            color: statusColor,
            background: statusBg,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              _ScoreMetric(
                  value: '$benar',
                  label: 'Jawaban Benar',
                  color: AppColors.green),
              _ScoreMetric(
                  value: '$salah',
                  label: 'Jawaban Salah',
                  color: AppColors.red),
              _ScoreMetric(
                  value: '$jumlahSoal',
                  label: 'Total Soal',
                  color: AppColors.purple),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Kuis kuis;

  const _DetailCard({required this.kuis});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Pengerjaan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _DetailItem(label: 'Judul Kuis', value: kuis.judul),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _DetailItem(label: 'KKM', value: kuis.kkm.toString())),
              Expanded(child: _DetailItem(label: 'Tingkat', value: kuis.level)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _DetailItem(
                      label: 'Alokasi Waktu', value: '${kuis.waktu} menit')),
              Expanded(
                  child: _DetailItem(
                      label: 'Jumlah Soal', value: '${kuis.soal.length} soal')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(value,
            style:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ScoreMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ScoreMetric(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _Badge(
      {required this.label, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _QuestionReview extends StatelessWidget {
  final int nomor;
  final double bobot;
  final Soal soal;
  final bool benar;
  final List<String> letters;
  final int jawabanSiswa;
  final String jawabanEsaiSiswa;

  const _QuestionReview({
    required this.nomor,
    required this.bobot,
    required this.soal,
    required this.benar,
    required this.letters,
    required this.jawabanSiswa,
    required this.jawabanEsaiSiswa,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = benar ? AppColors.green : AppColors.red;
    final statusBg = benar ? AppColors.greenLight : AppColors.redLight;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Soal #$nomor  (Bobot: ${bobot.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
              _Badge(
                label: benar ? '✓ Jawaban Benar' : '× Jawaban Salah',
                color: statusColor,
                background: statusBg,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(soal.pertanyaan,
              style: const TextStyle(fontSize: 13, height: 1.45)),
          if (soal.gambar != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                soal.gambar!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (soal.jenis == Soal.esai)
            _EssayReview(
              jawabanSiswa: jawabanEsaiSiswa,
              kunci: soal.jawabanEsai,
            )
          else
            ...List.generate(soal.opsi.length, (i) {
              final isCorrect = i == soal.jawaban;
              final isSelected = i == jawabanSiswa;
              final color = isCorrect
                  ? AppColors.green
                  : isSelected
                      ? AppColors.red
                      : AppColors.border;
              final background = isCorrect
                  ? AppColors.greenLight
                  : isSelected
                      ? AppColors.redLight
                      : AppColors.bg;
              final badge = isCorrect
                  ? '✓ Kunci Jawaban'
                  : isSelected
                      ? '× Pilihan Kamu'
                      : null;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: background,
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      '${i < letters.length ? letters[i] : i + 1}.',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(soal.opsi[i],
                          style: const TextStyle(fontSize: 12)),
                    ),
                    if (badge != null) const SizedBox(width: 6),
                    if (badge != null)
                      Text(
                        badge,
                        style: TextStyle(
                            fontSize: 9.5,
                            color: isCorrect ? AppColors.green : AppColors.red,
                            fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _EssayReview extends StatelessWidget {
  final String jawabanSiswa;
  final String kunci;

  const _EssayReview({required this.jawabanSiswa, required this.kunci});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jawabanSiswa.isEmpty
              ? 'Jawabanmu: Tidak dijawab'
              : 'Jawabanmu: $jawabanSiswa',
          style: const TextStyle(fontSize: 12.5, color: AppColors.red),
        ),
        const SizedBox(height: 4),
        Text('Kunci jawaban: $kunci',
            style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.green,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
