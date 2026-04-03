import 'dart:ui';

import 'package:flutter/material.dart';

/// Painter для отрисовки слоя тайлов карты
class TileLayerPainter extends CustomPainter {
  final ImageInfo imageInfo;
  final List<int> tileIds;
  final int mapWidth;
  final int mapHeight;
  final int tileWidth;
  final int tileHeight;
  final double opacity;

  TileLayerPainter({
    required this.imageInfo,
    required this.tileIds,
    required this.mapWidth,
    required this.mapHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    if (opacity < 1.0) {
      paint.colorFilter = ColorFilter.mode(Colors.white.withOpacity(opacity), BlendMode.modulate);
    }

    final imageWidth = imageInfo.image.width;
    final tilesPerRow = imageWidth ~/ tileWidth;

    for (int i = 0; i < tileIds.length; i++) {
      final tileId = tileIds[i];
      if (tileId == 0) continue;

      final x = i % mapWidth;
      final y = i ~/ mapWidth;

      final tileIndex = tileId - 1;
      final srcX = (tileIndex % tilesPerRow) * tileWidth;
      final srcY = (tileIndex ~/ tilesPerRow) * tileHeight;

      canvas.drawImageRect(
        imageInfo.image,
        Rect.fromLTWH(srcX.toDouble(), srcY.toDouble(), tileWidth.toDouble(), tileHeight.toDouble()),
        Rect.fromLTWH(
          x * tileWidth.toDouble(),
          y * tileHeight.toDouble(),
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TileLayerPainter oldDelegate) {
    return oldDelegate.imageInfo != imageInfo ||
        oldDelegate.tileIds != tileIds ||
        oldDelegate.opacity != opacity;
  }
}
