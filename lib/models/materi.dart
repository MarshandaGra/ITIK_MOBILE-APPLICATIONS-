import 'dart:typed_data';

class Materi {
  final String id;
  String bab;
  String judul;
  String kelas;
  String deskripsi;
  String isi;
  String? idMapel;
  String? linkYoutube;
  String? mataPelajaran;
  Uint8List? gambar;
  String pdfName;
  String? pdfUrl; // path/url file PDF
  String ukuran;
  String oleh;
  String tanggal;
  DateTime? createdAt; // BARU
  Materi({
    required this.id,
    required this.bab,
    required this.judul,
    required this.kelas,
    required this.deskripsi,
    required this.isi,
    this.idMapel,
    this.linkYoutube,
    this.mataPelajaran,
    this.gambar,
    required this.pdfName,
    this.pdfUrl,
    required this.ukuran,
    required this.oleh,
    required this.tanggal,
    this.createdAt, // BARU
  });
}
