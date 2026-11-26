import 'kuis.dart';

enum StatusValidasi { menungguValidasi, divalidasi }

extension StatusValidasiX on StatusValidasi {
  String get label =>
      this == StatusValidasi.divalidasi ? 'Divalidasi' : 'Menunggu Validasi';
}

class HasilKuis {
  final String id;
  final String siswaId;
  final String siswa;
  final String kuisId;
  final String kuis;
  final String level;
  double nilai;
  bool nilaiMenunggu;
  double kkm;
  int? durasi; // detik
  int benar; // BARU: jumlah soal yang dijawab benar
  List<int>
      jawabanSiswa; // BARU: jawaban siswa per soal (index opsi, -1 = tidak dijawab)
  List<String> jawabanEsaiSiswa;
  bool remedial; // apakah pengerjaan ini adalah pengerjaan remedial
  bool remedialDitugaskan;
  bool remedialSelesai;
  String? idKuisRemedial;
  Kuis? kuisRemedial;
  bool remedialKuisTersedia;
  final String tanggal;
  StatusValidasi status;

  HasilKuis({
    required this.id,
    required this.siswaId,
    required this.siswa,
    required this.kuisId,
    required this.kuis,
    required this.level,
    required this.nilai,
    this.nilaiMenunggu = false,
    required this.kkm,
    required this.durasi,
    required this.benar, // BARU
    required this.jawabanSiswa, // BARU
    this.jawabanEsaiSiswa = const [],
    this.remedial = false,
    this.remedialDitugaskan = false,
    this.remedialSelesai = false,
    this.idKuisRemedial,
    this.kuisRemedial,
    this.remedialKuisTersedia = false,
    required this.tanggal,
    this.status = StatusValidasi.menungguValidasi,
  });

  bool get dibawahKkm => nilai < kkm;
  String get statusLabel =>
      kkm > 0 && nilai >= kkm ? 'Lulus Otomatis' : status.label;
}

class HasilPengumpulanKuis {
  final String idMengerjakan;
  final double? nilai;

  const HasilPengumpulanKuis({
    required this.idMengerjakan,
    required this.nilai,
  });
}

class EvaluasiKuis {
  final bool tampilEvaluasi;
  final List<EvaluasiSoal> soal;

  const EvaluasiKuis({
    required this.tampilEvaluasi,
    required this.soal,
  });
}

class EvaluasiSoal {
  final String pertanyaan;
  final List<String> opsi;
  final int? jawabanBenar;
  final int? jawabanDipilih;
  final String jenis;
  final String jawabanTeks;
  final double bobot;
  final double? nilaiEsai;
  final String? catatanGuru;
  final String? gambarUrl;

  const EvaluasiSoal({
    required this.pertanyaan,
    required this.opsi,
    required this.jawabanBenar,
    required this.jawabanDipilih,
    required this.jenis,
    required this.jawabanTeks,
    required this.bobot,
    required this.nilaiEsai,
    required this.catatanGuru,
    required this.gambarUrl,
  });
}

String formatSkor(num value) {
  final score = value.toDouble();
  return score == score.roundToDouble()
      ? score.toInt().toString()
      : score
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
}
