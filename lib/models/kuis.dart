class Soal {
  String? id;
  String pertanyaan;
  List<String> opsi; // A..E
  int jawaban; // index opsi yang benar
  int? jawabanDipilih;
  double bobot;
  String tingkatKesulitan;
  String? gambar; // path gambar lokal, opsional

  Soal({
    this.id,
    required this.pertanyaan,
    required this.opsi,
    required this.jawaban,
    this.jawabanDipilih,
    this.bobot = 100,
    this.tingkatKesulitan = 'mudah',
    this.gambar,
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
    this.kategori = 'kuis harian',
    this.deskripsi = '',
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
