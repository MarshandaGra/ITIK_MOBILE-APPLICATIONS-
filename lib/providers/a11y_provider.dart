import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Setara objek `A11Y` pada prototipe: ukuran teks, mode kontras tinggi,
/// dan pembaca layar (text-to-speech).
class A11yProvider extends ChangeNotifier {
  double fontScale = 1.0;
  bool highContrast = false;
  bool darkTheme = false;
  bool autoRead = false; // BARU

  final FlutterTts _tts = FlutterTts(); // BARU

  A11yProvider() {
    _tts.setLanguage('id-ID');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    unawaited(_restoreSettings());
  }

  static const List<Map<String, dynamic>> opsiUkuran = [
    {'v': 1.0, 'label': 'Normal'},
    {'v': 1.15, 'label': 'Besar'},
    {'v': 1.3, 'label': 'Lebih Besar'},
    {'v': 1.5, 'label': 'Sangat Besar'},
  ];

  void setFontScale(double v) {
    fontScale = v;
    notifyListeners();
    unawaited(_saveSettings());
  }

  void toggleContrast() {
    highContrast = !highContrast;
    notifyListeners();
    unawaited(_saveSettings());
  }

  void setDarkTheme(bool value) {
    darkTheme = value;
    notifyListeners();
    unawaited(_saveSettings());
  }

  // ---------- BARU ----------
  void toggleAutoRead() {
    autoRead = !autoRead;
    if (!autoRead) _tts.stop();
    notifyListeners();
    unawaited(_saveSettings());
  }

  Future<void> speakPage([String? text]) async {
    await _tts.setLanguage('id-ID');
    await _tts.stop();
    await _tts.speak(text ?? 'Halaman aksesibilitas');
  }

  Future<void> stopSpeaking() => _tts.stop();
  // --------------------------

  void reset() {
    fontScale = 1.0;
    highContrast = false;
    darkTheme = false;
    autoRead = false; // BARU
    _tts.stop(); // BARU
    notifyListeners();
    unawaited(_saveSettings());
  }

  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    fontScale = prefs.getDouble('a11y_font_scale') ?? 1.0;
    highContrast = prefs.getBool('a11y_high_contrast') ?? false;
    darkTheme = prefs.getBool('a11y_dark_theme') ?? false;
    autoRead = prefs.getBool('a11y_auto_read') ?? false;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('a11y_font_scale', fontScale);
    await prefs.setBool('a11y_high_contrast', highContrast);
    await prefs.setBool('a11y_dark_theme', darkTheme);
    await prefs.setBool('a11y_auto_read', autoRead);
  }
}

/// BARU: membaca otomatis saat pindah halaman jika autoRead aktif.
class A11yRouteObserver extends NavigatorObserver {
  final A11yProvider a11y;
  A11yRouteObserver(this.a11y);

  @override
  void didPush(Route route, Route? previousRoute) {
    if (a11y.autoRead) {
      a11y.speakPage('Halaman baru dibuka');
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (a11y.autoRead && newRoute != null) {
      a11y.speakPage('Halaman baru dibuka');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (a11y.autoRead && previousRoute != null) {
      a11y.speakPage('Kembali ke halaman sebelumnya');
    }
  }
}
