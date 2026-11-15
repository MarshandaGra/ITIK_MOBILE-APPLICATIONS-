import 'kuis.dart';

enum StatusValidasi { menungguValidasi, divalidasi }

extension StatusValidasiX on StatusValidasi {
  String get label => this == StatusValidasi.divalidasi ? 'Divalidasi' : 'Menunggu Validasi';
}

class HasilKuis {
  final String id;
  final String siswaId;
  final String siswa;
  final String kuisId;
  final String kuis;
  final String level;
  double nilai;
  double kkm;
  int? durasi; // detik
  int benar; // BARU: jumlah soal yang dijawab benar
  List<int> jawabanSiswa; // BARU: jawaban siswa per soal (index opsi, -1 = tidak dijawab)
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
    required this.kkm,
    required this.durasi,
    required this.benar, // BARU
    required this.jawabanSiswa, // BARU
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

String formatSkor(num value) {
  final score = value.toDouble();
  return score == score.roundToDouble()
      ? score.toInt().toString()
      : score.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
