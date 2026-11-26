class TahunAjaranOption {
  const TahunAjaranOption({
    required this.id,
    required this.nama,
  });

  final String id;
  final String nama;

  factory TahunAjaranOption.fromJson(Map<String, dynamic> json) =>
      TahunAjaranOption(
        id: '${json['id_tahun_ajaran'] ?? ''}',
        nama: '${json['nama'] ?? ''}',
      );
}
