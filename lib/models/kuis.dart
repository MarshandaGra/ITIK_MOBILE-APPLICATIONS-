import 'dart:typed_data';

class Soal {
  static const pilihanGanda = 'Pilihan Ganda';
  static const esai = 'Esai';

  String pertanyaan;
  List<String> opsi; // A..D
  int jawaban; // index opsi yang benar
  Uint8List? gambar;
  String jenis;
  String jawabanEsai;

  Soal({
    required this.pertanyaan,
    required this.opsi,
    required this.jawaban,
    this.gambar,
    this.jenis = pilihanGanda,
    this.jawabanEsai = '',
  });
}

class Kuis {
  final String id;
  String judul;
  String materiId;
  String level; // Mudah | Sedang | Sulit
  String oleh;
  String tanggal;
  int waktu; // alokasi waktu (menit)
  int kkm;
  String? deskripsi;
  Uint8List? gambar;
  String? tahunAjaran;
  String? kategori;
  DateTime? tanggalTerbit;
  DateTime? tanggalSelesai;
  List<Soal> soal;
  DateTime? createdAt; // BARU
  bool isPublished;

  Kuis({
    required this.id,
    required this.judul,
    required this.materiId,
    required this.level,
    required this.oleh,
    required this.tanggal,
    required this.waktu,
    required this.kkm,
    this.deskripsi,
    this.gambar,
    this.tahunAjaran,
    this.kategori,
    this.tanggalTerbit,
    this.tanggalSelesai,
    required this.soal,
    this.createdAt, // BARU
    this.isPublished = true,
  });
}
