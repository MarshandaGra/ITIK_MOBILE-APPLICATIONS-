import 'dart:typed_data';

class Soal {
  static const String pilihanGanda = 'pilihanGanda';
  static const String esai = 'esai';

  String? id;
  String pertanyaan;
  List<String> opsi; // A..E
  int jawaban; // index opsi yang benar
  int? jawabanDipilih;
  double bobot;
  String tingkatKesulitan;
  Uint8List? gambar;
  String? gambarNamaFile;
  String? gambarUrl;
  String jenis;
  String jawabanEsai;

  Soal({
    this.id,
    required this.pertanyaan,
    required this.opsi,
    required this.jawaban,
    this.jawabanDipilih,
    this.bobot = 100,
    this.tingkatKesulitan = 'mudah',
    this.gambar,
    this.gambarNamaFile,
    this.gambarUrl,
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
  Uint8List? gambar;
  String? tahunAjaran;
  String kategori;
  String deskripsi;
  String? idMapel;
  String? idTahunAjaran;
  String? idKuisAsal;
  String statusPublikasi;
  DateTime? waktuMulai;
  DateTime? waktuSelesai;
  List<Soal> soal;
  int? soalCount;
  DateTime? createdAt; // BARU
  DateTime? batasWaktu;
  DateTime? tanggalTerbit;
  DateTime? tanggalSelesai;

  bool get isPublished => statusPublikasi == 'terbit';

  Kuis({
    required this.id,
    required this.judul,
    required this.materiId,
    required this.level,
    required this.oleh,
    required this.tanggal,
    required this.waktu,
    required this.kkm,
    required this.soal,
    this.deskripsi = '',
    this.gambar,
    this.tahunAjaran,
    this.kategori = 'kuis harian',
    this.tanggalTerbit,
    this.tanggalSelesai,
    this.idMapel,
    this.idTahunAjaran,
    this.idKuisAsal,
    this.statusPublikasi = 'draft',
    this.waktuMulai,
    this.waktuSelesai,
    this.soalCount,
    this.createdAt, // BARU
    this.batasWaktu,
  });

  int get jumlahSoal => soalCount ?? soal.length;
}
