import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';
import '../models/user.dart';
import '../models/materi.dart';
import '../models/kuis.dart';
import '../models/hasil_kuis.dart';

class AppProvider extends ChangeNotifier {
  final List<AppUser> users = DummyData.users();
  final List<Materi> materiList = DummyData.materi();
  final List<Kuis> kuisList = DummyData.kuis();
  final List<HasilKuis> hasilList = DummyData.hasil();

  final Map<String, bool> progress = {};

  AppUser? currentUser;
  bool _sessionInitialized = false;

  bool get isLoggedIn => currentUser != null;
  bool get sessionInitialized => _sessionInitialized;

  AppProvider() {
    unawaited(restoreSession());
  }

  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', user.id.trim());
    await prefs.setString('user_role', user.role.name);

    debugPrint(
        'SharedPreferences disimpan: user_id=${user.id}, user_role=${user.role.name}');
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id')?.trim();
      final userRole = prefs.getString('user_role')?.trim();
      debugPrint(
          'SharedPreferences dibaca: user_id=$userId, user_role=$userRole');

      if (userId == null ||
          userId.isEmpty ||
          (userRole != UserRole.siswa.name && userRole != UserRole.guru.name)) {
        currentUser = null;
        return;
      }

      UserRole? role;
      if (userRole == UserRole.siswa.name) role = UserRole.siswa;
      if (userRole == UserRole.guru.name) role = UserRole.guru;

      currentUser = users
          .where(
            (user) => user.id == userId && user.role == role,
          )
          .firstOrNull;

      if (currentUser == null) {
        await clearSession();
      }
    } catch (error) {
      debugPrint('Gagal memulihkan sesi SharedPreferences: $error');
      currentUser = null;
    } finally {
      _sessionInitialized = true;
      notifyListeners();
    }
  }

  /// Menghapus sesi login pengguna
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_id');
    await prefs.remove('user_role');
  }

  // ---------------- AUTH ----------------

  String? login(String identifier, String password, UserRole role) {
    final input = identifier.trim();

    if (input.isEmpty || password.isEmpty) {
      return 'NISN/NIP & kata sandi wajib diisi';
    }

    final match = users.where((u) =>
        u.role == role &&
        (u.induk ?? '').trim().toLowerCase() == input.toLowerCase() &&
        u.password == password);

    if (match.isEmpty) {
      return 'NISN/NIP atau kata sandi salah';
    }

    currentUser = match.first;
    debugPrint(
        'Login berhasil: user_id=${match.first.id}, role=${match.first.role.name}, nama=${match.first.nama}');

    // Simpan sesi login menggunakan Shared Preferences
    unawaited(saveSession(match.first));

    notifyListeners();
    return null;
  }

  String? register({
    required String nama,
    required String password,
    required String konfirmasi,
    required UserRole role,
    String? kelas,
    String? induk,
    String? mataPelajaran,
  }) {
    if (nama.trim().isEmpty || induk == null || induk.trim().isEmpty) {
      return role == UserRole.siswa
          ? 'Nama & NISN wajib diisi'
          : 'Nama & NIP wajib diisi';
    }

    if (password.length < 6) {
      return 'Kata sandi wajib diisi, minimal 6 karakter';
    }

    if (password != konfirmasi) {
      return 'Konfirmasi kata sandi tidak cocok';
    }

    final identifier = induk.trim();

    final dipakai = users.any((u) =>
        u.role == role &&
        (u.induk ?? '').trim().toLowerCase() == identifier.toLowerCase());

    if (dipakai) {
      return role == UserRole.siswa
          ? 'NISN sudah terdaftar, silakan masuk'
          : 'NIP sudah terdaftar, silakan masuk';
    }

    if (role == UserRole.siswa && (kelas == null || kelas.trim().isEmpty)) {
      return 'Kelas wajib diisi';
    }
    if (role == UserRole.guru &&
        !MataPelajaranGuru.pilihan.contains(mataPelajaran)) {
      return 'Mata pelajaran guru wajib dipilih';
    }

    final u = AppUser(
      id: 'U${DateTime.now().millisecondsSinceEpoch}',
      nama: nama,
      email: '$identifier@sekolah.sch.id',
      password: password,
      role: role,
      kelas: role == UserRole.siswa ? kelas : null,
      induk: identifier,
      mataPelajaran: role == UserRole.guru ? mataPelajaran : null,
    );

    users.add(u);
    currentUser = u;

    // Simpan sesi pengguna setelah registrasi
    unawaited(saveSession(u));

    notifyListeners();
    return null;
  }

  String? updateAccount({
    required String passwordSaatIni,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) {
    final user = currentUser;

    if (user == null) return 'Pengguna belum masuk';
    final inginUbahPassword = passwordSaatIni.isNotEmpty ||
        passwordBaru.isNotEmpty ||
        konfirmasiPassword.isNotEmpty;

    if (inginUbahPassword) {
      if (passwordSaatIni != user.password) {
        return 'Kata sandi saat ini salah';
      }

      if (passwordBaru.length < 6) {
        return 'Kata sandi baru minimal 6 karakter';
      }

      if (passwordBaru != konfirmasiPassword) {
        return 'Konfirmasi kata sandi baru tidak cocok';
      }
    }
    if (passwordBaru.isNotEmpty) {
      user.password = passwordBaru;
    }

    notifyListeners();
    return null;
  }

  /// Ganti / hapus foto profil pengguna yang sedang login.
  /// Kirim null untuk menghapus foto.
  void updateFoto(Uint8List? bytes) {
    final user = currentUser;

    if (user == null) return;

    user.foto = bytes;
    notifyListeners();
  }

  /// Logout dan hapus sesi dari Shared Preferences
  Future<void> logout() async {
    await clearSession();

    currentUser = null;
    debugPrint('SharedPreferences dihapus: sesi logout berhasil');
    notifyListeners();
  }

  // ---------------- PROGRES MATERI (SISWA) ----------------

  bool isMateriSelesai(String materiId) {
    final key = '${currentUser?.id}_$materiId';
    return progress[key] == true;
  }

  void submitProgresMateri(String materiId) {
    final key = '${currentUser?.id}_$materiId';

    progress[key] = true;
    notifyListeners();
  }

  // ---------------- HASIL / NILAI SISWA ----------------

  bool milikSiswaIni(HasilKuis h) => h.siswaId == currentUser?.id;

  List<HasilKuis> get riwayatSiswaSaatIni =>
      hasilList.where(milikSiswaIni).toList();

  String _normalisasiMataPelajaran(String? mataPelajaran) {
    final value = (mataPelajaran ?? '').trim().toLowerCase();
    if (value.contains('tik') || value.contains('teknologi informasi')) {
      return 'tik';
    }
    if (value.contains('bahasa indonesia')) return 'bahasa indonesia';
    return value;
  }

  bool _sesuaiMataPelajaranGuru(String? mataPelajaran) {
    final guru = currentUser;
    return guru?.role == UserRole.guru &&
        _normalisasiMataPelajaran(mataPelajaran) ==
            _normalisasiMataPelajaran(
                guru!.mataPelajaran ?? MataPelajaranGuru.tik);
  }

  List<Materi> get materiGuruSaatIni => materiList
      .where((materi) => _sesuaiMataPelajaranGuru(materi.mataPelajaran))
      .toList();

  List<Kuis> get kuisGuruSaatIni {
    final materiIds = materiGuruSaatIni.map((materi) => materi.id).toSet();
    return kuisList.where((kuis) => materiIds.contains(kuis.materiId)).toList();
  }

  List<HasilKuis> get hasilGuruSaatIni {
    final kuisIds = kuisGuruSaatIni.map((kuis) => kuis.id).toSet();
    return hasilList.where((hasil) => kuisIds.contains(hasil.kuisId)).toList();
  }

  HasilKuis? get remedialAktifUntukSiswa {
    try {
      return hasilList.firstWhere((h) =>
          milikSiswaIni(h) && h.remedialDitugaskan && !h.remedialSelesai);
    } catch (_) {
      return null;
    }
  }

  HasilKuis submitHasilKuis({
    required Kuis kuis,
    required int nilai,
    required int benar,
    required int durasiDetik,
    required List<int> jawabanSiswa,
    List<String> jawabanEsaiSiswa = const [],
    String? remedialOfId,
  }) {
    final h = HasilKuis(
      id: 'H${DateTime.now().millisecondsSinceEpoch}',
      siswaId: currentUser!.id,
      siswa: currentUser!.nama,
      kuisId: kuis.id,
      kuis: kuis.judul,
      level: kuis.level,
      nilai: nilai,
      kkm: kuis.kkm,
      durasi: durasiDetik,
      benar: benar,
      jawabanSiswa: jawabanSiswa,
      jawabanEsaiSiswa: jawabanEsaiSiswa,
      remedial: remedialOfId != null,
      tanggal: 'Hari ini',
    );

    hasilList.insert(0, h);

    if (remedialOfId != null) {
      final asal = hasilList.where((x) => x.id == remedialOfId);

      if (asal.isNotEmpty) {
        asal.first.remedialSelesai = true;
      }
    }

    notifyListeners();
    return h;
  }

  // ---------------- GURU: REMEDIAL ----------------

  void tugaskanRemedial(String hasilId) {
    final h = hasilList.firstWhere((x) => x.id == hasilId);

    h.remedialDitugaskan = true;
    notifyListeners();
  }

  void batalkanRemedial(String hasilId) {
    final h = hasilList.firstWhere((x) => x.id == hasilId);

    h.remedialDitugaskan = false;
    notifyListeners();
  }

  // ---------------- MATERI: CRUD (GURU) ----------------

  Materi? materiById(String id) {
    final r = materiList.where((m) => m.id == id);

    return r.isEmpty ? null : r.first;
  }

  void tambahMateri(Materi m) {
    m.createdAt ??= DateTime.now();

    materiList.add(m);
    notifyListeners();
  }

  void editMateri(String id, Materi baru) {
    final idx = materiList.indexWhere((m) => m.id == id);

    if (idx != -1) {
      baru.createdAt ??= materiList[idx].createdAt;
      materiList[idx] = baru;
    }

    notifyListeners();
  }

  void hapusMateri(String id) {
    materiList.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ---------------- KUIS: CRUD (GURU) ----------------

  Kuis? kuisById(String id) {
    final r = kuisList.where((k) => k.id == id);

    return r.isEmpty ? null : r.first;
  }

  void tambahKuis(Kuis k) {
    k.createdAt ??= DateTime.now();

    kuisList.add(k);
    notifyListeners();
  }

  void setKuisPublished(String id, bool isPublished) {
    final kuis = kuisById(id);
    if (kuis == null) return;

    kuis.isPublished = isPublished;
    notifyListeners();
  }

  void editKuisMeta(
    String id, {
    required String judul,
    required String materiId,
    required String level,
    required int waktu,
    required int kkm,
    String? deskripsi,
    Uint8List? gambar,
    String? tahunAjaran,
    String? kategori,
    DateTime? tanggalTerbit,
    DateTime? tanggalSelesai,
  }) {
    final k = kuisById(id);

    if (k == null) return;

    k.judul = judul;
    k.materiId = materiId;
    k.level = level;
    k.waktu = waktu;
    k.kkm = kkm;
    k.deskripsi = deskripsi;
    k.gambar = gambar;
    k.tahunAjaran = tahunAjaran;
    k.kategori = kategori;
    k.tanggalTerbit = tanggalTerbit;
    k.tanggalSelesai = tanggalSelesai;

    notifyListeners();
  }

  void hapusKuis(String id) {
    kuisList.removeWhere((k) => k.id == id);
    notifyListeners();
  }

  void tambahSoal(String kuisId, Soal soal) {
    kuisById(kuisId)?.soal.add(soal);
    notifyListeners();
  }

  void editSoal(String kuisId, int index, Soal soal) {
    final k = kuisById(kuisId);

    if (k != null && index >= 0 && index < k.soal.length) {
      k.soal[index] = soal;
      notifyListeners();
    }
  }

  void hapusSoal(String kuisId, int index) {
    kuisById(kuisId)?.soal.removeAt(index);
    notifyListeners();
  }
}
