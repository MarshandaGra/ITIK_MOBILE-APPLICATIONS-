import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/hasil_kuis.dart';
import '../../models/kuis.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_level_screen.dart';

class KuisResultScreen extends StatefulWidget {
  const KuisResultScreen({
    super.key,
    required this.kuis,
    required this.nilai,
    required this.benar,
    required this.salah,
    required this.jawabanSiswa,
    this.jawabanEsaiSiswa = const [],
    this.attemptId,
    this.serverGraded = false,
    this.resultStatusLabel,
  });

  final Kuis kuis;
  final double? nilai;
  final int benar;
  final int salah;
  final List<int> jawabanSiswa;
  final List<String> jawabanEsaiSiswa;
  final String? attemptId;
  final bool serverGraded;
  final String? resultStatusLabel;

  @override
  State<KuisResultScreen> createState() => _KuisResultScreenState();
}

class _KuisResultScreenState extends State<KuisResultScreen> {
  late Future<EvaluasiKuis>? _evaluasiFuture;

  @override
  void initState() {
    super.initState();
    _evaluasiFuture = widget.attemptId == null
        ? null
        : context.read<AppProvider>().loadEvaluasiSoal(widget.attemptId!);
  }

  void _cobaMuatUlangEvaluasi() {
    setState(() {
      _evaluasiFuture =
          context.read<AppProvider>().loadEvaluasiSoal(widget.attemptId!);
    });
  }

  EvaluasiKuis _evaluasiLokal() {
    return EvaluasiKuis(
      tampilEvaluasi: true,
      soal: [
        for (var index = 0; index < widget.kuis.soal.length; index++)
          EvaluasiSoal(
            pertanyaan: widget.kuis.soal[index].pertanyaan,
            opsi: widget.kuis.soal[index].opsi,
            jawabanBenar: widget.kuis.soal[index].jenis == Soal.esai
                ? null
                : widget.kuis.soal[index].jawaban,
            jawabanDipilih: index < widget.jawabanSiswa.length &&
                    widget.jawabanSiswa[index] >= 0
                ? widget.jawabanSiswa[index]
                : null,
            jenis: widget.kuis.soal[index].jenis,
            jawabanTeks: index < widget.jawabanEsaiSiswa.length
                ? widget.jawabanEsaiSiswa[index]
                : '',
            bobot: widget.kuis.soal[index].bobot,
            nilaiEsai: null,
            catatanGuru: null,
            gambarUrl: widget.kuis.soal[index].gambarUrl,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lulus = widget.nilai != null &&
        widget.kuis.kkm > 0 &&
        widget.nilai! >= widget.kuis.kkm;

    return Scaffold(
      appBar: simpleAppBar('Hasil Kuis'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              widget.kuis.judul,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nilai == null
                  ? 'Jawaban esai sedang dinilai.'
                  : lulus
                      ? 'Kerja bagus!'
                      : 'Terus berlatih!',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  Text(
                    widget.nilai == null
                        ? 'Menunggu Penilaian'
                        : formatSkor(widget.nilai!),
                    style: TextStyle(
                      fontSize: widget.nilai == null ? 20 : 36,
                      fontWeight: FontWeight.w800,
                      color: lulus ? AppColors.green : AppColors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppPill(
                    label: lulus
                        ? 'Lulus'
                        : widget.resultStatusLabel ??
                            (widget.nilai == null
                                ? 'Menunggu Penilaian'
                                : 'Menunggu Validasi'),
                    color: lulus ? AppColors.green : AppColors.orange,
                    background:
                        lulus ? AppColors.greenLight : AppColors.orangeLight,
                  ),
                  const Divider(height: 28),
                  _metric('KKM', formatSkor(widget.kuis.kkm)),
                  if (!widget.serverGraded) ...[
                    const Divider(height: 24),
                    _metric('Jawaban benar', '${widget.benar}'),
                    const Divider(height: 24),
                    _metric('Jawaban salah', '${widget.salah}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEvaluasi(),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const KuisLevelScreen()),
              ),
              child: const Text('Lihat daftar kuis'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Kembali ke beranda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluasi() {
    final future = _evaluasiFuture;
    if (future == null) return _evaluasiContent(_evaluasiLokal());

    return FutureBuilder<EvaluasiKuis>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Evaluasi soal gagal dimuat.'),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                TextButton.icon(
                  onPressed: _cobaMuatUlangEvaluasi,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }

        final evaluasi = snapshot.data;
        if (evaluasi == null) {
          return const AppCard(child: Text('Evaluasi soal belum tersedia.'));
        }
        return _evaluasiContent(evaluasi);
      },
    );
  }

  Widget _evaluasiContent(EvaluasiKuis evaluasi) {
    if (!evaluasi.tampilEvaluasi) {
      return const AppCard(
        child: Text(
          'Evaluasi soal belum ditampilkan sesuai pengaturan kuis.',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evaluasi Soal',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pelajari setiap jawaban untuk mengevaluasi pemahamanmu.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (evaluasi.soal.isEmpty)
          const AppCard(child: Text('Belum ada detail soal untuk ditampilkan.'))
        else
          ...evaluasi.soal.indexed.map(
            (entry) => _EvaluasiSoalCard(
              nomor: entry.$1 + 1,
              soal: entry.$2,
            ),
          ),
      ],
    );
  }

  Widget _metric(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}

class _EvaluasiSoalCard extends StatelessWidget {
  const _EvaluasiSoalCard({
    required this.nomor,
    required this.soal,
  });

  final int nomor;
  final EvaluasiSoal soal;

  @override
  Widget build(BuildContext context) {
    final isEssay = soal.jenis == Soal.esai || soal.jenis == 'esai';
    final isCorrect = !isEssay &&
        soal.jawabanBenar != null &&
        soal.jawabanDipilih == soal.jawabanBenar;
    const letters = ['A', 'B', 'C', 'D', 'E'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Soal #$nomor (Bobot: ${formatSkor(soal.bobot)}%)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                AppPill(
                  label: isEssay
                      ? (soal.nilaiEsai == null
                          ? 'Menunggu Penilaian'
                          : 'Sudah Dinilai')
                      : isCorrect
                          ? 'Jawaban Benar'
                          : 'Jawaban Salah',
                  color: isEssay
                      ? AppColors.orange
                      : isCorrect
                          ? AppColors.green
                          : AppColors.red,
                  background: isEssay
                      ? AppColors.orangeLight
                      : isCorrect
                          ? AppColors.greenLight
                          : AppColors.redLight,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(soal.pertanyaan),
            if (soal.gambarUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  soal.gambarUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text(
                    'Gambar soal gagal dimuat.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (isEssay)
              _buildEssayAnswer()
            else
              ...List.generate(soal.opsi.length, (index) {
                final correct = index == soal.jawabanBenar;
                final selectedIncorrect =
                    index == soal.jawabanDipilih && !correct;
                final color = correct
                    ? AppColors.green
                    : selectedIncorrect
                        ? AppColors.red
                        : AppColors.border;
                final background = correct
                    ? AppColors.greenLight
                    : selectedIncorrect
                        ? AppColors.redLight
                        : AppColors.bg;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${letters[index]}.',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(soal.opsi[index])),
                      if (correct)
                        const Text(
                          'Kunci Jawaban',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (selectedIncorrect)
                        const Text(
                          'Pilihan Kamu',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            if (!isEssay && soal.jawabanDipilih == null)
              const Text(
                'Kamu tidak menjawab soal ini.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEssayAnswer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jawabanmu',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(soal.jawabanTeks.isEmpty ? 'Tidak dijawab' : soal.jawabanTeks),
        if (soal.nilaiEsai != null) ...[
          const SizedBox(height: 8),
          Text(
            'Nilai: ${formatSkor(soal.nilaiEsai!)} / ${formatSkor(soal.bobot)}',
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (soal.catatanGuru?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Text('Catatan guru: ${soal.catatanGuru}'),
        ],
      ],
    );
  }
}
