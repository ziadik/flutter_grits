import 'dart:ui';

/// Модель данных спрайта из TexturePacker JSON
class SpriteData {
  final String name;
  final Rect frame;
  final Rect spriteSourceSize;
  final Size sourceSize;
  final bool trimmed;
  final bool rotated;

  const SpriteData({
    required this.name,
    required this.frame,
    required this.spriteSourceSize,
    required this.sourceSize,
    required this.trimmed,
    required this.rotated,
  });
}
