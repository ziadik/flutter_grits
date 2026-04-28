import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Менеджер настроек игры (синглтон)
class SettingsManager {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  // Настройки звука
  bool _musicEnabled = false;  // По умолчанию выключена
  bool _sfxEnabled = false;    // По умолчанию выключен
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _musicEnabled = prefs.getBool('music_enabled') ?? false;
      _sfxEnabled = prefs.getBool('sfx_enabled') ?? false;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.5;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.7;
      
      debugPrint('✅ Settings loaded: music=$_musicEnabled, sfx=$_sfxEnabled');
    } catch (e) {
      debugPrint('⚠️ Error loading settings: $e');
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', enabled);
    _notifyListeners();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', enabled);
    _notifyListeners();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
    _notifyListeners();
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
    _notifyListeners();
  }
}
