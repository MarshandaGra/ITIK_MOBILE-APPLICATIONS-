class MapelOption {
  const MapelOption({
    required this.id,
    required this.nama,
    this.kode = '',
  });

  final String id;
  final String nama;
  final String kode;

  factory MapelOption.fromJson(Map<String, dynamic> json) => MapelOption(
        id: '${json['id_mapel'] ?? ''}',
        nama: '${json['nama_mapel'] ?? ''}',
        kode: '${json['kode_mapel'] ?? ''}',
      );
}
