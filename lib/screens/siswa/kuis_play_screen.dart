import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_result_screen.dart';

const _portalPurple = Color(0xFF604CE8);

class KuisPlayScreen extends StatefulWidget {
  final Kuis kuis;
  final String? remedialOfId;
  const KuisPlayScreen({super.key, required this.kuis, this.remedialOfId});

  @override
  State<KuisPlayScreen> createState() => _KuisPlayScreenState();
}

class _KuisPlayScreenState extends State<KuisPlayScreen>
    with WidgetsBindingObserver {
  /// Waktu pengerjaan per soal (detik). Ubah sesuai kebutuhan.
  static const int _detikPerSoal = 30;

  /// Nilai jawaban untuk soal yang tidak sempat dijawab (tidak akan pernah sama dengan kunci).
  static const int _tidakDijawab = -1;

  int index = 0;
  int? selected;
  final List<int> answers = [];
  final List<String> essayAnswers = [];
  final TextEditingController essayAnswerCtrl = TextEditingController();
  late DateTime startedAt;

  Timer? _timer;
  int sisa = _detikPerSoal;
  bool _sudahSelesai = false;
  bool _modeKuisAktif = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_modeKuisAktif) _aturModeKuis(false);
    essayAnswerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _modeKuisAktif) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
  }

  void _aturModeKuis(bool aktif) {
    _modeKuisAktif = aktif;
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        aktif ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  bool _started = false;

  void _mulaiKuis() {
    startedAt = DateTime.now();
    setState(() => _started = true);
    _aturModeKuis(true);
    _mulaiTimer();
  }

  // ===== TIMER =====
  void _mulaiTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _sudahSelesai) {
        t.cancel();
        return;
      }
      if (sisa <= 1) {
        t.cancel();
        setState(() => sisa = 0);
        _waktuHabis();
      } else {
        setState(() => sisa--);
      }
    });
  }

  void _waktuHabis() {
    if (!mounted || _sudahSelesai) return;
    final soal = widget.kuis.soal[index];
    final belumDijawab = soal.jenis == Soal.esai
        ? essayAnswerCtrl.text.trim().isEmpty
        : selected == null;
    if (belumDijawab) {
      showAppToast(context, 'Waktu habis, lanjut ke soal berikutnya');
    }
    _catatDanLanjut();
  }

  void _lanjut() {
    final soal = widget.kuis.soal[index];
    if (soal.jenis == Soal.esai) {
      if (essayAnswerCtrl.text.trim().isEmpty) {
        showAppToast(context, 'Tulis jawaban esai terlebih dahulu');
        return;
      }
    } else if (selected == null) {
      showAppToast(context, 'Pilih salah satu jawaban dulu');
      return;
    }
    _catatDanLanjut();
  }

  /// Menyimpan jawaban (atau "tidak dijawab" bila waktu habis) lalu pindah soal.
  void _catatDanLanjut() {
    if (_sudahSelesai) return;
    final soal = widget.kuis.soal[index];
    if (soal.jenis == Soal.esai) {
      final response = essayAnswerCtrl.text.trim();
      essayAnswers.add(response);
      answers.add(
          _jawabanEsaiBenar(response, soal.jawabanEsai) ? 0 : _tidakDijawab);
    } else {
      essayAnswers.add('');
      answers.add(selected ?? _tidakDijawab);
    }
    if (index < widget.kuis.soal.length - 1) {
      setState(() {
        index++;
        selected = null;
        essayAnswerCtrl.clear();
        sisa = _detikPerSoal;
      });
      _mulaiTimer();
    } else {
      _selesai();
    }
  }

  void _selesai() {
    if (_sudahSelesai) return;
    _sudahSelesai = true;
    _timer?.cancel();
    _aturModeKuis(false);

    final k = widget.kuis;
    int benar = 0;
    for (var i = 0; i < k.soal.length; i++) {
      final jawab = i < answers.length ? answers[i] : _tidakDijawab;
      final soal = k.soal[i];
      final dijawabBenar = soal.jenis == Soal.esai
          ? i < essayAnswers.length &&
              _jawabanEsaiBenar(essayAnswers[i], soal.jawabanEsai)
          : jawab == soal.jawaban;
      if (dijawabBenar) benar++;
    }
    final salah = k.soal.length - benar; // BARU
    final nilai = k.soal.isEmpty ? 0 : ((benar / k.soal.length) * 100).round();
    final durasi =
        DateTime.now().difference(startedAt).inSeconds.clamp(1, 1 << 30);
    final jawabanSiswa = List<int>.from(answers); // BARU
    final app = context.read<AppProvider>();
    app.submitHasilKuis(
      kuis: k,
      nilai: nilai,
      benar: benar,
      durasiDetik: durasi,
      jawabanSiswa: jawabanSiswa, // BARU
      jawabanEsaiSiswa: List<String>.from(essayAnswers),
      remedialOfId: widget.remedialOfId,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => KuisResultScreen(
                kuis: k,
                nilai: nilai,
                benar: benar,
                salah: salah,
                jawabanSiswa: List<int>.from(answers),
                jawabanEsaiSiswa: List<String>.from(essayAnswers),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kuis;

    // Antisipasi: kuis tanpa soal
    if (k.soal.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(k.judul)),
        body: const Center(child: Text('Kuis ini belum memiliki soal.')),
      );
    }

    if (!_started) return _buildPersiapan(k);

    final s = k.soal[index];
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          // Judul + level (Mudah/Sedang/Sulit) di sampingnya
          title: Row(children: [
            Flexible(
              child:
                  Text(k.judul, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 10),
            LevelPill(level: k.level),
            const SizedBox(width: 16),
          ]),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Soal ${index + 1} dari ${k.soal.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  // Timer menggantikan posisi level
                  _TimerPill(sisa: sisa),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (index + 1) / k.soal.length,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.pertanyaan,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    if (s.gambar != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          s.gambar!,
                          width: double.infinity,
                          height: 360,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (s.jenis == Soal.esai)
                TextField(
                  controller: essayAnswerCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban Esai',
                    hintText: 'Tulis jawabanmu di sini',
                    alignLabelWithHint: true,
                  ),
                )
              else
                ...List.generate(s.opsi.length, (i) {
                  final active = selected == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => selected = i),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              active ? AppColors.purpleLight : AppColors.card,
                          border: Border.all(
                              color:
                                  active ? AppColors.purple : AppColors.border,
                              width: active ? 1.6 : 1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active ? AppColors.purple : AppColors.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                i < letters.length ? letters[i] : '${i + 1}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: active
                                        ? Colors.white
                                        : AppColors.muted)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(s.opsi[i],
                                  style: const TextStyle(fontSize: 13.5))),
                        ]),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _lanjut,
                child: Text(index < k.soal.length - 1
                    ? 'Soal Berikutnya'
                    : 'Selesai & Lihat Nilai'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersiapan(Kuis kuis) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1930),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 544),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 36,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Color(0xFFFFA23A), size: 48),
                    const SizedBox(height: 14),
                    const Text(
                      'Ujian Mode Layar Penuh (CBT)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF29264D),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${kuis.judul}\n'
                      '${kuis.soal.length} soal · ${kuis.waktu} menit · KKM ${kuis.kkm}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        border: Border.all(color: const Color(0xFFFFD6D6)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Layar penuh akan aktif selama ujian. Tetap fokus dan '
                        'jangan keluar dari halaman pengerjaan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF8A4242),
                            fontSize: 12.5,
                            height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _portalPurple,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _mulaiKuis,
                        child: const Text('Mulai Ujian & Kunci Layar Penuh'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _jawabanEsaiBenar(String jawaban, String kunci) {
    String normalize(String value) =>
        value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return normalize(jawaban) == normalize(kunci);
  }
}

/// Pill timer mm:ss. Berubah merah saat 5 detik terakhir.
class _TimerPill extends StatelessWidget {
  final int sisa;
  const _TimerPill({required this.sisa});

  @override
  Widget build(BuildContext context) {
    final mm = (sisa ~/ 60).toString().padLeft(2, '0');
    final ss = (sisa % 60).toString().padLeft(2, '0');
    final kritis = sisa <= 5;
    final fg = kritis ? AppColors.red : AppColors.purple;
    final bg = kritis ? AppColors.redLight : AppColors.purpleLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_outlined, size: 15, color: fg),
        const SizedBox(width: 4),
        Text(
          '$mm:$ss',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ]),
    );
  }
}
