import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/materi.dart';
import '../models/kuis.dart';
import '../models/hasil_kuis.dart';
import '../models/mapel_option.dart';
import '../models/tahun_ajaran_option.dart';
import '../services/api_client.dart';

class AppProvider extends ChangeNotifier {
  final List<AppUser> users = <AppUser>[];
  final List<Materi> materiList = <Materi>[];
  final List<Kuis> kuisList = <Kuis>[];
  final List<HasilKuis> hasilList = <HasilKuis>[];

  final Map<String, bool> progress = {};
  final ApiClient api;

  AppUser? currentUser;
  bool _sessionInitialized = false;
  bool materiLoading = false;
  bool kuisLoading = false;
  bool nilaiLoading = false;
  String? materiLoadError;
  String? kuisLoadError;
  String? nilaiLoadError;
  Future<void>? _kuisLoadFuture;

  bool get isLoggedIn => currentUser != null;
  bool get sessionInitialized => _sessionInitialized;

  AppProvider({ApiClient? apiClient}) : api = apiClient ?? ApiClient() {
    unawaited(restoreSession());
  }

  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', user.id.trim());
    await prefs.setString('user_role', user.role.name);
    if (api.token != null) await prefs.setString('api_token', api.token!);

    debugPrint(
        'SharedPreferences disimpan: user_id=${user.id}, user_role=${user.role.name}');
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null && token.isNotEmpty) {
        api.token = token;
        final response = await api.request('/me');
        final payload = response['data'] as Map<String, dynamic>;
        if (!_isMobileRole(payload)) {
          await clearSession();
          currentUser = null;
          return;
        }
        currentUser = _userFromApi(payload);
        unawaited(loadRemoteData());
        return;
      }
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      currentUser = null;
    } catch (error) {
      debugPrint('Gagal memulihkan sesi SharedPreferences: $error');
      await clearSession();
      currentUser = null;
    } finally {
      _sessionInitialized = true;
      notifyListeners();
    }
  }

  /// Menghapus sesi login pengguna
  Future<void> clearSession() async {
    if (api.token != null) {
      try {
        await api.request('/logout', method: 'POST');
      } catch (error) {
        debugPrint('Logout API gagal, token lokal tetap dihapus: $error');
      }
    }
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('api_token');
    api.token = null;
  }

  // ---------------- AUTH ----------------

  Future<String?> login(String identifier, String password) async {
    final input = identifier.trim();

    if (input.isEmpty || password.isEmpty) {
      return 'NISN/NIP & kata sandi wajib diisi';
    }

    try {
      final result = await api.request('/login',
          method: 'POST',
          authenticated: false,
          body: {'nomor_induk': input, 'password': password});
      api.token = result['token']?.toString();
      final payload = result['user'] as Map<String, dynamic>;
      if (!_isMobileRole(payload)) {
        await clearSession();
        currentUser = null;
        return 'Akun operator belum tersedia di aplikasi mobile.';
      }
      currentUser = _userFromApi(payload);
      await saveSession(currentUser!);
      notifyListeners();
      unawaited(loadRemoteData());
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'Tidak dapat terhubung ke server. Periksa alamat API dan koneksi.';
    }
  }

  AppUser _userFromApi(Map<String, dynamic> json) => AppUser(
      id: '${json['id_user']}',
      nama: '${json['nama_lengkap'] ?? ''}',
      email: '${json['email'] ?? ''}',
      password: '',
      role: UserRoleX.fromString('${json['role']}'),
      kelas: json['kelas']?.toString(),
      induk: json['nomor_induk']?.toString(),
      fotoUrl: _photoUrlFromApi(json['foto_url']));

  String? _photoUrlFromApi(dynamic value) {
    return _publicUrlFromApi(value);
  }

  String? _questionImageUrlFromApi(dynamic value) {
    final path = value?.toString();
    if (path == null || path.isEmpty) return null;
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    final base = Uri.parse(ApiClient.assetBaseUrl);
    if (uri.hasScheme) {
      return base
          .replace(
            path: uri.path,
            query: uri.query,
            fragment: uri.fragment,
          )
          .toString();
    }

    final normalizedPath = path.replaceFirst(RegExp(r'^/'), '');
    final imagePath = normalizedPath.startsWith('storage/')
        ? '/$normalizedPath'
        : '/storage/$normalizedPath';
    return base.replace(path: imagePath).toString();
  }

  String? _publicUrlFromApi(dynamic value) {
    final path = value?.toString();
    if (path == null || path.isEmpty) return null;

    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    final base = Uri.parse(ApiClient.assetBaseUrl);

    if (uri.hasScheme) {
      if (!{'localhost', '127.0.0.1', '::1', '[::1]'}.contains(uri.host)) {
        return uri.toString();
      }
      return base
          .replace(path: uri.path, query: uri.query, fragment: uri.fragment)
          .toString();
    }

    return base
        .resolveUri(
          uri.path.startsWith('/') ? uri : Uri.parse('/${uri.path}'),
        )
        .toString();
  }

  bool _isMobileRole(Map<String, dynamic> json) =>
      json['role'] == UserRole.siswa.value ||
      json['role'] == UserRole.guru.value;

  List<Map<String, dynamic>> _listFromResponse(Map<String, dynamic> response) {
    final payload = response['data'];
    final items = payload is List
        ? payload
        : payload is Map<String, dynamic> && payload['data'] is List
            ? payload['data'] as List
            : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> loadRemoteData() async {
    final user = currentUser;
    if (user == null) return;

    materiLoading = true;
    materiLoadError = null;
    if (user.role == UserRole.siswa || user.role == UserRole.guru) {
      kuisLoading = true;
      kuisLoadError = null;
    }
    notifyListeners();

    final requests = <Future<void>>[_loadMateri(user)];
    if (user.role == UserRole.guru || user.role == UserRole.siswa) {
      requests.add(loadKuisData());
    }
    if (user.role == UserRole.siswa) {
      requests.add(loadNilaiSiswa());
    }
    await Future.wait(requests);
    if (user.role == UserRole.guru) {
      await loadNilaiGuru();
    }
  }

  Future<void> loadKuisData() {
    final user = currentUser;
    if (user == null ||
        (user.role != UserRole.siswa && user.role != UserRole.guru)) {
      return Future<void>.value();
    }

    final activeRequest = _kuisLoadFuture;
    if (activeRequest != null) return activeRequest;

    kuisLoading = true;
    kuisLoadError = null;
    notifyListeners();

    final request = _loadKuis(user);
    _kuisLoadFuture = request;
    return request.whenComplete(() {
      if (identical(_kuisLoadFuture, request)) _kuisLoadFuture = null;
    });
  }

  Future<void> _loadMateri(AppUser user) async {
    try {
      final response = await api.request(
          user.role == UserRole.siswa ? '/siswa/materi' : '/guru/materi');
      final rawMateri = _listFromResponse(response);
      materiList
        ..clear()
        ..addAll(rawMateri.map(_materiFromApi));
      _sortMateriByNewest();
      for (final item in rawMateri) {
        final progressList = item['progress'];
        if (progressList is List &&
            progressList.isNotEmpty &&
            progressList.first is Map) {
          final status = (progressList.first as Map)['status']?.toString();
          if (status == 'selesai') {
            progress['${user.id}_${item['id_materi']}'] = true;
          }
        }
      }
    } catch (error) {
      materiLoadError = error.toString();
      debugPrint('Gagal memuat materi: $error');
    } finally {
      materiLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadKuis(AppUser user) async {
    try {
      final endpoint =
          user.role == UserRole.siswa ? '/siswa/kuis' : '/guru/kuis';
      final response = await api.request(endpoint);
      final rawKuis = _listFromResponse(response);
      kuisList
        ..clear()
        ..addAll(rawKuis.map(_kuisFromApi));
      _sortKuisByNewest();
    } catch (error) {
      kuisLoadError = error.toString();
      debugPrint('Gagal memuat kuis: $error');
    } finally {
      kuisLoading = false;
      notifyListeners();
    }
  }

  Materi _materiFromApi(Map<String, dynamic> j) => Materi(
      id: '${j['id_materi']}',
      bab: '${j['bab'] ?? ''}',
      judul: '${j['judul'] ?? ''}',
      kelas: '${j['kelas'] ?? ''}',
      deskripsi: '${j['deskripsi'] ?? ''}',
      isi: '${j['isi_materi'] ?? j['file_url'] ?? ''}',
      idMapel: j['id_mapel']?.toString(),
      linkYoutube: j['link_youtube']?.toString(),
      pdfName: '${j['isi_materi'] ?? ''}'.split('/').last,
      pdfUrl: _publicUrlFromApi(j['pdf_url'] ?? j['file_url']),
      ukuran: '',
      oleh: '${j['user'] is Map ? j['user']['nama_lengkap'] ?? '' : ''}',
      tanggal: '${j['created_at'] ?? ''}',
      createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'));

  Kuis _kuisFromApi(Map<String, dynamic> j) => Kuis(
      id: '${j['id_kuis']}',
      judul: '${j['judul'] ?? ''}',
      materiId: _firstMateriId(j),
      level: _quizDifficulty(j),
      oleh: '${j['pembuat'] is Map ? j['pembuat']['nama_lengkap'] ?? '' : ''}',
      tanggal: '${j['created_at'] ?? ''}',
      waktu: _numberFromApi(j['alokasi_waktu'])?.toInt() ?? 0,
      kkm: _numberFromApi(j['kkm'])?.round() ?? 0,
      soal: (j['soal'] is List)
          ? (j['soal'] as List)
              .whereType<Map<String, dynamic>>()
              .map(_soalFromApi)
              .toList()
          : <Soal>[],
      kategori: '${j['kategori'] ?? 'kuis harian'}',
      deskripsi: '${j['deskripsi'] ?? ''}',
      idMapel: j['id_mapel']?.toString(),
      idTahunAjaran: j['id_tahun_ajaran']?.toString(),
      idKuisAsal: j['remedial'] is Map
          ? j['remedial']['id_kuis_asal']?.toString()
          : null,
      statusPublikasi: '${j['status_publikasi'] ?? 'draft'}',
      waktuMulai: DateTime.tryParse('${j['waktu_mulai'] ?? ''}'),
      waktuSelesai: DateTime.tryParse('${j['waktu_selesai'] ?? ''}'),
      soalCount: _numberFromApi(j['soal_count'])?.toInt(),
      createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'));

  void _sortMateriByNewest() {
    materiList.sort((a, b) {
      final dateOrder = _compareCreationDates(b.createdAt, a.createdAt);
      return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
    });
  }

  void _sortKuisByNewest() {
    kuisList.sort((a, b) {
      final dateOrder = _compareCreationDates(b.createdAt, a.createdAt);
      return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
    });
  }

  int _compareCreationDates(DateTime? first, DateTime? second) {
    if (first == null && second == null) return 0;
    if (first == null) return -1;
    if (second == null) return 1;
    return first.compareTo(second);
  }

  num? _numberFromApi(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  String _quizDifficulty(Map<String, dynamic> json) {
    final quizLevel = json['tingkat_kesulitan']?.toString();
    if (quizLevel != null && quizLevel.isNotEmpty) return quizLevel;

    final questions = json['soal'];
    if (questions is List) {
      for (final question in questions.whereType<Map>()) {
        final level = question['tingkat_kesulitan']?.toString();
        if (level != null && level.isNotEmpty) return level;
      }
    }

    return 'mudah';
  }

  String _firstMateriId(Map<String, dynamic> json) {
    final materies = json['materi'];
    if (materies is List && materies.isNotEmpty && materies.first is Map) {
      return '${materies.first['id_materi'] ?? ''}';
    }
    return '';
  }

  Soal _soalFromApi(Map<String, dynamic> json) {
    const letters = ['A', 'B', 'C', 'D', 'E'];
    final answer = letters.indexOf('${json['jawaban'] ?? 'A'}');
    final apiType =
        '${json['tipe'] ?? json['tipe_soal'] ?? 'pilihan_ganda'}'.toLowerCase();
    final imageUrl = json['gambar_url']?.toString();
    final imageValue = imageUrl != null && imageUrl.trim().isNotEmpty
        ? imageUrl
        : json['gambar_path'];
    final options = [
      json['opsi_a'],
      json['opsi_b'],
      json['opsi_c'],
      json['opsi_d'],
      json['opsi_e'],
    ].map((option) => option?.toString() ?? '').toList();
    while (options.length > 4 && options.last.isEmpty) {
      options.removeLast();
    }

    return Soal(
      id: json['id_soal']?.toString(),
      pertanyaan: '${json['pertanyaan'] ?? ''}',
      opsi: options,
      jawaban: answer < 0 ? 0 : answer,
      bobot: _numberFromApi(json['bobot'])?.toDouble() ?? 0,
      tingkatKesulitan: '${json['tingkat_kesulitan'] ?? 'mudah'}',
      jenis: apiType == 'essay' || apiType == 'esai'
          ? Soal.esai
          : Soal.pilihanGanda,
      gambarUrl: _questionImageUrlFromApi(imageValue),
      jawabanEsai: '${json['jawaban_esai'] ?? json['kunci_jawaban'] ?? ''}',
    );
  }

  Future<Kuis> mulaiKuisSiswa(String id) async {
    final kuis = kuisById(id) ??
        hasilList
            .map((hasil) => hasil.kuisRemedial)
            .whereType<Kuis>()
            .where((item) => item.id == id)
            .firstOrNull;
    if (kuis == null) {
      throw StateError('Kuis tidak ditemukan. Muat ulang daftar kuis.');
    }
    if (!kuisList.any((item) => item.id == kuis.id)) {
      kuisList.add(kuis);
      _sortKuisByNewest();
    }

    final path = '/siswa/kuis/${Uri.encodeComponent(id)}';
    final startResponse = await api.request('$path/mulai', method: 'POST');
    final sessionData = startResponse['data'];
    if (sessionData is! Map<String, dynamic>) {
      throw const FormatException('Respons API mulai kuis tidak valid.');
    }

    final response = await api.request(path);
    final data = response['data'];
    if (data is! Map<String, dynamic> || data['soal'] is! List) {
      throw const FormatException('Respons API soal kuis tidak valid.');
    }

    final questions = (data['soal'] as List)
        .whereType<Map>()
        .map((item) => _soalFromApi(Map<String, dynamic>.from(item)))
        .toList();
    final drafts = data['draft_jawaban'];
    if (drafts is Map) {
      const letters = ['A', 'B', 'C', 'D', 'E'];
      for (final question in questions) {
        final draft = drafts[question.id];
        if (draft is Map) {
          final answer = letters
              .indexOf('${draft['jawaban_dipilih'] ?? ''}'.toUpperCase());
          if (answer >= 0) question.jawabanDipilih = answer;
        }
      }
    }

    kuis.soal
      ..clear()
      ..addAll(questions);
    kuis
      ..soalCount = questions.length
      ..batasWaktu = DateTime.tryParse(
        '${data['batas_waktu'] ?? sessionData['batas_waktu'] ?? ''}',
      );
    notifyListeners();
    return kuis;
  }

  Future<void> simpanJawabanSiswa(
    String kuisId,
    String soalId,
    int? jawaban,
  ) async {
    const letters = ['A', 'B', 'C', 'D', 'E'];
    if (jawaban != null && (jawaban < 0 || jawaban >= letters.length)) {
      throw RangeError.index(jawaban, letters, 'jawaban');
    }

    await api.request(
      '/siswa/kuis/${Uri.encodeComponent(kuisId)}/jawaban',
      method: 'PUT',
      body: {
        'id_soal': soalId,
        'jawaban': jawaban == null ? null : letters[jawaban],
      },
    );
  }

  Future<HasilPengumpulanKuis> kumpulkanKuisSiswa(String kuisId) async {
    final response = await api.request(
      '/siswa/kuis/${Uri.encodeComponent(kuisId)}/submit',
      method: 'POST',
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API hasil kuis tidak valid.');
    }
    if (!data.containsKey('nilai')) {
      throw const FormatException(
          'Nilai kuis tidak ditemukan pada respons API.');
    }
    final score = _numberFromApi(data['nilai']);
    final attemptId = data['id_mengerjakan']?.toString();
    if (attemptId == null || attemptId.isEmpty) {
      throw const FormatException(
          'ID pengerjaan tidak ditemukan pada respons API.');
    }
    unawaited(loadNilaiSiswa());
    return HasilPengumpulanKuis(
      idMengerjakan: attemptId,
      nilai: score?.toDouble(),
    );
  }

  Future<EvaluasiKuis> loadEvaluasiSoal(String attemptId) async {
    final response = await api.request(
      '/siswa/nilai/${Uri.encodeComponent(attemptId)}/evaluasi',
    );
    final data = response['data'];
    if (data is! Map<String, dynamic> || data['tampil_evaluasi'] is! bool) {
      throw const FormatException('Respons API evaluasi kuis tidak valid.');
    }

    final tampilEvaluasi = data['tampil_evaluasi'] as bool;
    if (!tampilEvaluasi) {
      return const EvaluasiKuis(tampilEvaluasi: false, soal: []);
    }

    final rows = data['soal'];
    if (rows is! List) {
      throw const FormatException('Daftar soal evaluasi tidak valid.');
    }
    const letters = ['A', 'B', 'C', 'D', 'E'];
    int? answerIndex(dynamic value) {
      final index = letters.indexOf('${value ?? ''}'.toUpperCase());
      return index < 0 ? null : index;
    }

    return EvaluasiKuis(
      tampilEvaluasi: true,
      soal: rows.whereType<Map>().map((row) {
        final json = Map<String, dynamic>.from(row);
        final options = [
          json['opsi_a'],
          json['opsi_b'],
          json['opsi_c'],
          json['opsi_d'],
          json['opsi_e'],
        ].map((value) => value?.toString() ?? '').toList();
        while (options.isNotEmpty && options.last.isEmpty) {
          options.removeLast();
        }

        return EvaluasiSoal(
          pertanyaan: '${json['pertanyaan'] ?? ''}',
          opsi: options,
          jawabanBenar: answerIndex(json['jawaban_benar']),
          jawabanDipilih: answerIndex(json['jawaban_dipilih']),
          jenis: '${json['tipe_soal'] ?? 'pilihan_ganda'}',
          jawabanTeks: '${json['jawaban_teks'] ?? ''}',
          bobot: _numberFromApi(json['bobot'])?.toDouble() ?? 0,
          nilaiEsai: _numberFromApi(json['nilai_essay'])?.toDouble(),
          catatanGuru: json['catatan_guru']?.toString(),
          gambarUrl: _questionImageUrlFromApi(json['gambar_url']),
        );
      }).toList(),
    );
  }

  Future<void> loadNilaiSiswa() async {
    final user = currentUser;
    if (user == null || user.role != UserRole.siswa) return;

    nilaiLoading = true;
    nilaiLoadError = null;
    notifyListeners();
    try {
      final rows = await _loadAllPages('/siswa/nilai');
      final tasks = await _loadAllPages('/siswa/remedial');
      final resultsById = <String, HasilKuis>{};
      for (final row in rows) {
        final result = _hasilKuisFromApi(row);
        resultsById[result.id] = result;
      }

      for (final task in tasks) {
        final origin = task['mengerjakan_asal'];
        if (origin is! Map) {
          throw const FormatException(
              'Data nilai asal pada tugas remedial tidak valid.');
        }
        final originData = Map<String, dynamic>.from(origin);
        originData['remedial_siswa'] = [task];
        final result = _hasilKuisFromApi(originData);
        resultsById[result.id] = result;
      }

      final results = resultsById.values.toList()
        ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
      hasilList.removeWhere((hasil) => hasil.siswaId == user.id);
      hasilList.addAll(results);
    } catch (error) {
      nilaiLoadError = error.toString();
      debugPrint('Gagal memuat nilai siswa: $error');
    } finally {
      nilaiLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> _loadAllPages(String path) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;
    do {
      final response = await api.request('$path?page=$page');
      rows.addAll(_listFromResponse(response));
      final pagination = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      lastPage = _numberFromApi(pagination['last_page'])?.toInt() ?? page;
      page++;
    } while (page <= lastPage);
    return rows;
  }

  Future<void> loadNilaiGuru() async {
    final user = currentUser;
    if (user == null || user.role != UserRole.guru || nilaiLoading) return;

    nilaiLoading = true;
    nilaiLoadError = null;
    notifyListeners();
    try {
      final rows = await _loadAllPages('/guru/nilai');
      final results = rows.map(_hasilKuisFromApi).toList();
      hasilList
        ..clear()
        ..addAll(results);
    } catch (error) {
      nilaiLoadError = error.toString();
      debugPrint('Gagal memuat nilai guru: $error');
    } finally {
      nilaiLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> remedialUntukKuis(String kuisId) async {
    final remedials = await _loadAllPages('/guru/remedial');
    return remedials.where((remedial) {
      final kuisAsal = remedial['kuis_asal'];
      return kuisAsal is Map && kuisAsal['id_kuis']?.toString() == kuisId;
    }).toList();
  }

  Future<void> tugaskanRemedial(String hasilId, String remedialId) async {
    final idMengerjakan = int.tryParse(hasilId);
    if (idMengerjakan == null) {
      throw const FormatException('ID pengerjaan siswa tidak valid.');
    }

    final response = await api.request(
      '/guru/remedial/${Uri.encodeComponent(remedialId)}/tugaskan',
      method: 'POST',
      body: {
        'id_mengerjakan': [idMengerjakan]
      },
    );
    final jumlah = _numberFromApi(response['jumlah_ditugaskan'])?.toInt();
    if (jumlah != 1) {
      throw StateError(
        'Server tidak membuat penugasan remedial. Pastikan nilai siswa di bawah KKM.',
      );
    }

    await loadNilaiGuru();
  }

  HasilKuis _hasilKuisFromApi(Map<String, dynamic> json) {
    final kuisJson = json['kuis'] is Map
        ? Map<String, dynamic>.from(json['kuis'] as Map)
        : <String, dynamic>{};
    final siswaJson = json['siswa'] is Map
        ? Map<String, dynamic>.from(json['siswa'] as Map)
        : <String, dynamic>{};
    final kuisId = '${json['id_kuis'] ?? kuisJson['id_kuis'] ?? ''}';
    final kuis = kuisById(kuisId);
    final kkm = _numberFromApi(kuisJson['kkm'] ?? json['kkm'])?.toDouble() ??
        kuis?.kkm.toDouble() ??
        0;
    final validation = '${json['status_validasi'] ?? ''}'.toLowerCase();
    final date = '${json['tanggal'] ?? ''}';
    final category = '${kuisJson['kategori'] ?? kuis?.kategori ?? ''}';
    final remedialRows = json['remedial_siswa'];
    final remedialAssignments = remedialRows is List
        ? remedialRows.whereType<Map>().map(Map<String, dynamic>.from).toList()
        : <Map<String, dynamic>>[];
    final assignment = remedialAssignments.firstWhere(
      (row) => row['status'] == 'ditugaskan',
      orElse: () => remedialAssignments.isNotEmpty
          ? remedialAssignments.first
          : <String, dynamic>{},
    );
    final remedialKuisJson = assignment['kuis_remedial'] is Map
        ? Map<String, dynamic>.from(assignment['kuis_remedial'] as Map)
        : <String, dynamic>{};
    final remedialKuis =
        remedialKuisJson.isEmpty ? null : _kuisFromApi(remedialKuisJson);
    final assignmentStatus = assignment['status']?.toString();

    return HasilKuis(
      id: '${json['id_mengerjakan'] ?? ''}',
      siswaId:
          '${json['id_user'] ?? siswaJson['id_user'] ?? currentUser?.id ?? ''}',
      siswa: '${siswaJson['nama_lengkap'] ?? currentUser?.nama ?? ''}',
      kuisId: kuisId,
      kuis: '${kuisJson['judul'] ?? kuis?.judul ?? 'Kuis'}',
      level: kuis?.level ?? 'Sedang',
      nilai: _numberFromApi(json['nilai'])?.toDouble() ?? 0,
      nilaiMenunggu: json['nilai'] == null,
      kkm: kkm,
      durasi: _numberFromApi(json['durasi_detik'])?.toInt(),
      benar: 0,
      jawabanSiswa: const [],
      remedial: category.toLowerCase() == 'remedial',
      remedialDitugaskan: assignment.isNotEmpty,
      remedialSelesai: assignmentStatus == 'selesai',
      idKuisRemedial: assignment['id_kuis_remedial']?.toString(),
      kuisRemedial: remedialKuis,
      remedialKuisTersedia: remedialKuisJson['status_publikasi'] == 'terbit' &&
          remedialKuisJson['is_aktif'] == true,
      tanggal: date.length >= 10 ? date.substring(0, 10) : date,
      status: validation.contains('divalidasi') && !validation.contains('belum')
          ? StatusValidasi.divalidasi
          : StatusValidasi.menungguValidasi,
    );
  }

  Future<void> validasiNilai(String hasilId) async {
    final response = await api.request(
      '/guru/nilai/${Uri.encodeComponent(hasilId)}/validasi',
      method: 'PATCH',
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API validasi nilai tidak valid.');
    }

    final index = hasilList.indexWhere((hasil) => hasil.id == hasilId);
    if (index < 0) {
      throw StateError('Nilai yang akan divalidasi tidak ditemukan.');
    }

    hasilList[index].status = StatusValidasi.divalidasi;
    notifyListeners();
  }

  Future<void> loadKuisDetail(String id) async {
    final response = await api.request('/guru/kuis/${Uri.encodeComponent(id)}');
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API detail kuis tidak valid.');
    }
    final kuis = _kuisFromApi(data);
    final index = kuisList.indexWhere((item) => item.id == id);
    if (index == -1) {
      kuisList.add(kuis);
    } else {
      kuisList[index] = kuis;
    }
    _sortKuisByNewest();
    notifyListeners();
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

  Future<void> updatePassword({
    required String passwordSaatIni,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Pengguna belum masuk.');
    }

    if (passwordSaatIni.isEmpty ||
        passwordBaru.isEmpty ||
        konfirmasiPassword.isEmpty) {
      throw const FormatException('Semua kolom password wajib diisi.');
    }
    if (passwordBaru.length < 6) {
      throw const FormatException('Password baru minimal 6 karakter.');
    }
    if (passwordBaru != konfirmasiPassword) {
      throw const FormatException('Konfirmasi password baru tidak cocok.');
    }

    await api.request(
      '/me/password',
      method: 'PUT',
      body: {
        'password_lama': passwordSaatIni,
        'password_baru': passwordBaru,
        'password_baru_confirmation': konfirmasiPassword,
      },
    );
    notifyListeners();
  }

  Future<void> updateFoto(Uint8List? bytes, {String? fileName}) async {
    final user = currentUser;
    if (user == null) throw StateError('Pengguna belum masuk.');

    late final Map<String, dynamic> response;
    if (bytes == null) {
      response = await api.request('/me/photo', method: 'DELETE');
    } else {
      if (fileName == null || fileName.isEmpty) {
        throw ArgumentError('Nama file foto wajib disertakan.');
      }
      response = await api.multipartRequest(
        '/me/photo',
        fields: const {},
        fileBytes: bytes,
        fileName: fileName,
        fileField: 'foto',
      );
    }
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API foto profil tidak valid.');
    }
    user.fotoUrl = _photoUrlFromApi(data['foto_url']);
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
    if (api.token != null && currentUser?.role == UserRole.siswa) {
      unawaited(api
          .request('/siswa/materi/$materiId/selesai', method: 'POST')
          .catchError((Object error) {
        progress.remove(key);
        debugPrint('Gagal menyimpan progres materi: $error');
        notifyListeners();
        return <String, dynamic>{};
      }));
    }
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
      nilai: nilai.toDouble(),
      kkm: kuis.kkm.toDouble(),
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

  // ---------------- MATERI: CRUD (GURU) ----------------

  Materi? materiById(String id) {
    final r = materiList.where((m) => m.id == id);

    return r.isEmpty ? null : r.first;
  }

  Future<List<MapelOption>> loadMapelOptions({String? currentId}) async {
    final query = currentId == null || currentId.isEmpty
        ? ''
        : '?current_id=${Uri.encodeQueryComponent(currentId)}';
    final response = await api.request('/guru/mapel$query');
    return _listFromResponse(response)
        .map(MapelOption.fromJson)
        .where((mapel) => mapel.id.isNotEmpty)
        .toList();
  }

  Future<TahunAjaranOption?> loadTahunAjaranAktif() async {
    final response = await api.request('/guru/tahun-ajaran/aktif');
    final data = response['data'];
    if (data == null) return null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
          'Respons API tahun ajaran aktif tidak valid.');
    }
    return TahunAjaranOption.fromJson(data);
  }

  Future<void> tambahMateri(
    Materi m, {
    Uint8List? pdfBytes,
    String? pdfName,
  }) async {
    final response = await api.multipartRequest(
      '/guru/materi',
      fields: _materiPayload(m),
      fileBytes: pdfBytes,
      fileName: pdfName,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API tambah materi tidak valid.');
    }
    materiList.add(_materiFromApi(data));
    _sortMateriByNewest();
    notifyListeners();
  }

  Future<void> editMateri(
    String id,
    Materi baru, {
    Uint8List? pdfBytes,
    String? pdfName,
  }) async {
    final response = await api.multipartRequest(
      '/guru/materi/${Uri.encodeComponent(id)}',
      fields: _materiPayload(baru),
      fileBytes: pdfBytes,
      fileName: pdfName,
      update: true,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API edit materi tidak valid.');
    }
    final idx = materiList.indexWhere((m) => m.id == id);
    if (idx != -1) {
      materiList[idx] = _materiFromApi(data);
      _sortMateriByNewest();
    }
    notifyListeners();
  }

  Future<void> hapusMateri(String id) async {
    await api.request(
      '/guru/materi/${Uri.encodeComponent(id)}',
      method: 'DELETE',
    );
    materiList.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Map<String, String> _materiPayload(Materi materi) {
    return {
      'judul': materi.judul,
      'bab': materi.bab,
      'kelas': materi.kelas,
      'deskripsi': materi.deskripsi,
      if (materi.idMapel?.isNotEmpty ?? false) 'id_mapel': materi.idMapel!,
      'link_youtube': materi.linkYoutube ?? '',
    };
  }

  // ---------------- KUIS: CRUD (GURU) ----------------

  Kuis? kuisById(String id) {
    final r = kuisList.where((k) => k.id == id);

    return r.isEmpty ? null : r.first;
  }

  Future<Kuis> tambahKuis(Kuis kuis) async {
    final isRemedial = kuis.kategori == 'remedial';
    final response = await api.request(
      isRemedial ? '/guru/remedial' : '/guru/kuis',
      method: 'POST',
      body: isRemedial
          ? {
              'judul': kuis.judul,
              'deskripsi': kuis.deskripsi.isEmpty ? null : kuis.deskripsi,
              'id_kuis_asal': kuis.idKuisAsal,
              'alokasi_waktu': kuis.waktu,
              'kkm': kuis.kkm,
            }
          : _kuisPayload(kuis),
    );
    final responseData = response['data'];
    if (responseData is! Map<String, dynamic>) {
      throw const FormatException('Respons API tambah kuis tidak valid.');
    }

    Map<String, dynamic> quizData = responseData;
    if (isRemedial) {
      final remedialQuiz = responseData['kuis_remedial'];
      if (remedialQuiz is! Map) {
        throw const FormatException(
            'Respons API tambah kuis remedial tidak valid.');
      }
      quizData = Map<String, dynamic>.from(remedialQuiz);
      final originQuiz = responseData['kuis_asal'];
      final originId = responseData['id_kuis_asal'] ??
          (originQuiz is Map ? originQuiz['id_kuis'] : null);
      if (originId != null) {
        quizData['remedial'] = {'id_kuis_asal': originId};
      }
    }

    final saved = _kuisFromApi(quizData);
    kuisList.add(saved);
    _sortKuisByNewest();
    notifyListeners();
    return saved;
  }

  Future<void> editKuis(String id, Kuis kuis) async {
    final response = await api.request(
      '/guru/kuis/${Uri.encodeComponent(id)}',
      method: 'PUT',
      body: _kuisPayload(kuis),
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API edit kuis tidak valid.');
    }
    final updated = _kuisFromApi(data);
    final index = kuisList.indexWhere((item) => item.id == id);
    if (index != -1) {
      kuisList[index] = updated;
      _sortKuisByNewest();
    }
    notifyListeners();
  }

  Future<void> hapusKuis(String id) async {
    await api.request(
      '/guru/kuis/${Uri.encodeComponent(id)}',
      method: 'DELETE',
    );
    kuisList.removeWhere((k) => k.id == id);
    notifyListeners();
  }

  Future<void> tambahSoal(String kuisId, Soal soal) async {
    final response = await _requestSoal(
      '/guru/kuis/${Uri.encodeComponent(kuisId)}/soal',
      method: 'POST',
      soal: soal,
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API tambah soal tidak valid.');
    }
    kuisById(kuisId)?.soal.add(_soalFromApi(data));
    final kuis = kuisById(kuisId);
    if (kuis != null) kuis.soalCount = kuis.soal.length;
    notifyListeners();
  }

  Future<void> editSoal(String kuisId, int index, Soal soal) async {
    final k = kuisById(kuisId);

    if (k != null && index >= 0 && index < k.soal.length) {
      final id = k.soal[index].id;
      if (id == null) {
        throw StateError('ID soal tidak tersedia. Muat ulang detail kuis.');
      }
      final response = await _requestSoal(
        '/guru/kuis/${Uri.encodeComponent(kuisId)}/soal/${Uri.encodeComponent(id)}',
        method: 'PUT',
        soal: soal,
      );
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Respons API edit soal tidak valid.');
      }
      k.soal[index] = _soalFromApi(data);
      notifyListeners();
    }
  }

  Future<void> hapusSoal(String kuisId, int index) async {
    final kuis = kuisById(kuisId);
    if (kuis == null || index < 0 || index >= kuis.soal.length) return;
    final id = kuis.soal[index].id;
    if (id == null) {
      throw StateError('ID soal tidak tersedia. Muat ulang detail kuis.');
    }
    await api.request(
      '/guru/kuis/${Uri.encodeComponent(kuisId)}/soal/${Uri.encodeComponent(id)}',
      method: 'DELETE',
    );
    kuis.soal.removeAt(index);
    kuis.soalCount = kuis.soal.length;
    notifyListeners();
  }

  Future<void> publishKuis(String id) async {
    final response = await api.request(
      '/guru/kuis/${Uri.encodeComponent(id)}/publish',
      method: 'POST',
    );
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons API publikasi kuis tidak valid.');
    }
    final published = _kuisFromApi(data);
    final index = kuisList.indexWhere((item) => item.id == id);
    if (index != -1) {
      published.soal
        ..clear()
        ..addAll(kuisList[index].soal);
      published.soalCount = kuisList[index].jumlahSoal;
      kuisList[index] = published;
    }
    notifyListeners();
  }

  Map<String, dynamic> _kuisPayload(Kuis kuis) => {
        'judul': kuis.judul,
        'deskripsi': kuis.deskripsi.isEmpty ? null : kuis.deskripsi,
        'kategori': kuis.kategori,
        'id_mapel': kuis.idMapel,
        'tingkat_kesulitan': kuis.level,
        'alokasi_waktu': kuis.waktu,
        'kkm': kuis.kkm,
        'materi': kuis.materiId.isEmpty ? <String>[] : [kuis.materiId],
        'id_kuis_asal': kuis.kategori == 'remedial' ? kuis.idKuisAsal : null,
        'waktu_mulai': kuis.kategori == 'ulangan'
            ? kuis.waktuMulai?.toIso8601String()
            : null,
        'waktu_selesai': kuis.kategori == 'ulangan'
            ? kuis.waktuSelesai?.toIso8601String()
            : null,
      };

  Future<Map<String, dynamic>> _requestSoal(
    String path, {
    required String method,
    required Soal soal,
  }) {
    final payload = _soalPayload(soal);
    final image = soal.gambar;
    if (image == null) {
      return api.request(path, method: method, body: payload);
    }

    final fileName = soal.gambarNamaFile;
    if (fileName == null || fileName.isEmpty) {
      throw ArgumentError('Nama file gambar soal wajib disertakan.');
    }
    final fields = <String, String>{
      for (final entry in payload.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    return api.multipartRequest(
      path,
      fields: fields,
      fileBytes: image,
      fileName: fileName,
      fileField: 'gambar',
      update: method == 'PUT',
    );
  }

  Map<String, dynamic> _soalPayload(Soal soal) {
    const letters = ['A', 'B', 'C', 'D', 'E'];
    String? optionAt(int index) => soal.jenis != Soal.esai &&
            index < soal.opsi.length &&
            soal.opsi[index].trim().isNotEmpty
        ? soal.opsi[index].trim()
        : null;

    return {
      'pertanyaan': soal.pertanyaan.trim(),
      'opsi_a': optionAt(0),
      'opsi_b': optionAt(1),
      'opsi_c': optionAt(2),
      'opsi_d': optionAt(3),
      'opsi_e': optionAt(4),
      'jawaban': soal.jenis == Soal.esai ? null : letters[soal.jawaban],
      'bobot': soal.bobot,
      'tingkat_kesulitan':
          soal.tingkatKesulitan.isEmpty ? null : soal.tingkatKesulitan,
    };
  }
}
