import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_grits/models/sprite_data.dart';

/// Утилита для работы со спрайт-листами в формате TexturePacker
class SpriteSheet {
  final ImageProvider image;
  final Map<String, SpriteData> sprites;
  final String imagePath;
  final Size sourceSize;

  const SpriteSheet({required this.image, required this.sprites, required this.imagePath, required this.sourceSize});

  /// Создаёт SpriteSheet из JSON данных
  factory SpriteSheet.fromJson(Map<String, dynamic> json, ImageProvider imageProvider) {
    final frames = json['frames'] as Map<String, dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    final metaSize = meta['size'] as Map<String, dynamic>;

    final sprites = <String, SpriteData>{};

    frames.forEach((key, value) {
      final frame = value['frame'] as Map<String, dynamic>;
      final spriteSourceSize = value['spriteSourceSize'] as Map<String, dynamic>;
      final sourceSize = value['sourceSize'] as Map<String, dynamic>;

      sprites[key] = SpriteData(
        name: key,
        frame: Rect.fromLTWH((frame['x'] as num).toDouble(), (frame['y'] as num).toDouble(), (frame['w'] as num).toDouble(), (frame['h'] as num).toDouble()),
        spriteSourceSize: Rect.fromLTWH(
          (spriteSourceSize['x'] as num).toDouble(),
          (spriteSourceSize['y'] as num).toDouble(),
          (spriteSourceSize['w'] as num).toDouble(),
          (spriteSourceSize['h'] as num).toDouble(),
        ),
        sourceSize: Size((sourceSize['w'] as num).toDouble(), (sourceSize['h'] as num).toDouble()),
        trimmed: value['trimmed'] as bool,
        rotated: value['rotated'] as bool,
      );
    });

    return SpriteSheet(image: imageProvider, sprites: sprites, imagePath: meta['image'] as String, sourceSize: Size((metaSize['w'] as num).toDouble(), (metaSize['h'] as num).toDouble()));
  }

  /// Ищет спрайт по имени
  SpriteData? findSprite(String name) {
    if (sprites.containsKey(name)) {
      return sprites[name];
    }

    final normalizedKey = name.toLowerCase().replaceAll('.png', '');
    final matches = sprites.keys.where((key) {
      final keyWithoutExt = key.toLowerCase().replaceAll('.png', '');
      return keyWithoutExt.contains(normalizedKey) || normalizedKey.contains(keyWithoutExt);
    }).toList();

    if (matches.isNotEmpty) {
      return sprites[matches.first];
    }

    return null;
  }
}
