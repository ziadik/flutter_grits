// lib/managers/sound_manager.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Менеджер звуков для игры Grits
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _sfxPlayers = {};

  bool _isMuted = false;
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;

  String? _currentBgMusic;

  /// Инициализация (вызывать при старте игры)
  Future<void> init() async {
    await _bgPlayer.setVolume(_musicVolume);
  }

  /// Фоновая музыка
  Future<void> playBackgroundMusic(String filename, {bool loop = true}) async {
    if (_isMuted) return;

    if (_currentBgMusic == filename) return;

    await _bgPlayer.stop();
    _currentBgMusic = filename;

    await _bgPlayer.play(AssetSource('sounds/$filename'));
    if (loop) {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
    }
  }

  /// Остановить фоновую музыку
  Future<void> stopBackgroundMusic() async {
    await _bgPlayer.stop();
    _currentBgMusic = null;
  }

  /// Пауза фоновой музыки
  Future<void> pauseBackgroundMusic() async {
    await _bgPlayer.pause();
  }

  /// Возобновить фоновую музыку
  Future<void> resumeBackgroundMusic() async {
    if (!_isMuted && _currentBgMusic != null) {
      await _bgPlayer.resume();
    }
  }

  /// Воспроизвести звуковой эффект
  Future<void> playSfx(String filename, {double volume = 1.0}) async {
    if (_isMuted) return;

    try {
      final player = AudioPlayer();
      await player.setVolume(_sfxVolume * volume);
      await player.play(AssetSource('sounds/$filename'));

      // Удаляем игрока после завершения
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing sound $filename: $e');
    }
  }

  /// Воспроизвести звук выстрела с учетом панорамирования
  Future<void> playShootSound(String filename, {double pan = 0.0}) async {
    if (_isMuted) return;

    try {
      final player = AudioPlayer();
      await player.setVolume(_sfxVolume);
      // setPan недоступен в новой версии audioplayers
      await player.play(AssetSource('sounds/$filename'));

      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('Error playing shoot sound $filename: $e');
    }
  }

  /// Установить громкость музыки (0.0 - 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _bgPlayer.setVolume(_musicVolume);
  }

  /// Установить громкость эффектов (0.0 - 1.0)
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Включить/выключить звук
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await _bgPlayer.pause();
    } else {
      await _bgPlayer.resume();
    }
  }

  bool get isMuted => _isMuted;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  /// Освободить ресурсы
  Future<void> dispose() async {
    await _bgPlayer.dispose();
    for (final player in _sfxPlayers.values) {
      await player.dispose();
    }
    _sfxPlayers.clear();
  }
}

/// Константы с именами звуковых файлов
class SoundAssets {
  static const String bgGame = 'bg_game.ogg';
  static const String bgMenu = 'bg_menu.ogg';
  static const String energyPickup = 'energy_pickup.ogg';
  static const String explode0 = 'explode0.ogg';
  static const String grenadeShoot0 = 'grenade_shoot0.ogg';
  static const String itemPickup0 = 'item_pickup0.ogg';
  static const String machineShoot0 = 'machine_shoot0.ogg';
  static const String menuBump = 'menu_bump.ogg';
  static const String menuSelect = 'menu_select.ogg';
  static const String quadPickup = 'quad_pickup.ogg';
  static const String rocketShoot0 = 'rocket_shoot0.ogg';
  static const String shieldActivate = 'shield_activate.ogg';
  static const String shotgunShoot0 = 'shotgun_shoot0.ogg';
  static const String spawn0 = 'spawn0.ogg';
  static const String swordActivate = 'sword_activate.ogg';
  static const String bounce0 = 'bounce0.ogg';
}
