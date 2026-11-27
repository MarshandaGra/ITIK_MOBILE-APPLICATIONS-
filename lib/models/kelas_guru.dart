class KelasGuru {
  final String id;
  final String namaKelas;
  final String tingkat;
  final int totalSiswa;
  final int totalMateri;
  final int kuisAktif;
  final int jumlahNilai;
  final double? rataNilai;

  const KelasGuru({
    required this.id,
    required this.namaKelas,
    required this.tingkat,
    required this.totalSiswa,
    required this.totalMateri,
    required this.kuisAktif,
    required this.jumlahNilai,
    required this.rataNilai,
  });

  factory KelasGuru.fromJson(Map<String, dynamic> json) {
    int number(String key) {
      final value = json[key];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final score = json['rata_nilai'];
    return KelasGuru(
      id: json['id_kelas']?.toString() ?? '',
      namaKelas: json['nama_kelas']?.toString() ?? '',
      tingkat: json['tingkat']?.toString() ?? '',
      totalSiswa: number('total_siswa'),
      totalMateri: number('total_materi'),
      kuisAktif: number('kuis_aktif'),
      jumlahNilai: number('jumlah_nilai'),
      rataNilai: score is num
          ? score.toDouble()
          : double.tryParse(score?.toString() ?? ''),
    );
  }

  String get namaTampilan {
    final nama = namaKelas.trim();
    final level = tingkat.trim();
    if (level.isEmpty ||
        nama.toLowerCase() == level.toLowerCase() ||
        nama.toLowerCase().startsWith('${level.toLowerCase()} ')) {
      return nama;
    }
    return '$level $nama';
  }
}
