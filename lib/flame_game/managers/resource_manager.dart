// lib/managers/resource_manager.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart'; // Исправлен импорт

class ResourceManager {
  late PlayerAnimator playerAnimator;
  late Image _effectsImage;
  // late Image _tilesetImage;
  bool _isLoaded = false;

  Future<void> loadResources() async {
    if (_isLoaded) return;

    try {
      // Загрузка JSON данных
      final effectsJsonString = await rootBundle.loadString(
        'assets/grits_effects.json',
      );
      final effectsData = jsonDecode(effectsJsonString);

      // Загрузка изображений
      final effectsImageData = await rootBundle.load(
        'assets/grits_effects.png',
      );
      // final tilesetImageData = await rootBundle.load(
      //   'assets/images/grits_master.png',
      // );

      // Загрузка изображений
      _effectsImage = await _loadImageFromBytes(
        effectsImageData.buffer.asUint8List(),
      );
      // _tilesetImage = await _loadImageFromBytes(
      //   tilesetImageData.buffer.asUint8List(),
      // );

      // Инициализация аниматора
      playerAnimator = PlayerAnimator();
      playerAnimator.loadImages(_effectsImage);
      playerAnimator.loadFromJson(effectsData);

      _isLoaded = true;
    } catch (e) {
      // debugPrint('Error loading resources: $e');
      rethrow;
    }
  }

  Future<Image> _loadImageFromBytes(Uint8List bytes) async {
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Image get effectsImage => _effectsImage;
  // Image get tilesetImage => _tilesetImage;
  bool get isLoaded => _isLoaded;
}
