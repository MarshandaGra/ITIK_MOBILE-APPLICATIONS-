import 'dart:typed_data';

/// Peran pengguna. Operator sengaja TIDAK disertakan di aplikasi mobile ini
/// (operator hanya tersedia di website admin) — sesuai kesepakatan scope.
enum UserRole { siswa, guru }

abstract final class MataPelajaranGuru {
  static const tik = 'Teknologi Informasi dan Komunikasi (TIK)';
  static const bahasaIndonesia = 'Bahasa Indonesia';
  static const pilihan = [tik, bahasaIndonesia];
}

extension UserRoleX on UserRole {
  String get label => this == UserRole.siswa ? 'Siswa' : 'Guru';

  static UserRole fromString(String v) =>
      v == 'guru' ? UserRole.guru : UserRole.siswa;

  String get value => this == UserRole.siswa ? 'siswa' : 'guru';
}

class AppUser {
  final String id;
  String nama;
  String email;
  String password;
  final UserRole role;
  final String? kelas;
  String? induk; // NISN untuk siswa, NIP untuk guru
  String? mataPelajaran;
  Uint8List? foto;
  String? fotoUrl;

  AppUser({
    required this.id,
    required this.nama,
    required this.email,
    required this.password,
    required this.role,
    this.kelas,
    this.induk,
    this.mataPelajaran,
    this.foto,
    this.fotoUrl,
  });

  String get initials {
    final parts = nama.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((e) => e.isNotEmpty ? e[0] : '').join();
    return letters.toUpperCase();
  }
}
