import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_grits/painters/environment_painter.dart';
import 'package:flutter_grits/painters/tile_layer_painter.dart';
import 'package:flutter_grits/sprites/sprite_sheet.dart';

/// Виджет для отображения тайловой карты с объектами environment
class TileMapViewerWithEffects extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final ImageProvider tileSetImage;
  final ImageProvider effectsImage;
  final Map<String, dynamic> effectsJson;
  final bool showEffects;
  final bool showLabels;
  final bool showDebug;

  const TileMapViewerWithEffects({
    super.key,
    required this.mapData,
    required this.tileSetImage,
    required this.effectsImage,
    required this.effectsJson,
    this.showEffects = true,
    this.showLabels = true,
    this.showDebug = false,
  });

  @override
  State<TileMapViewerWithEffects> createState() => _TileMapViewerWithEffectsState();
}

class _TileMapViewerWithEffectsState extends State<TileMapViewerWithEffects> {
  ImageInfo? _tileSetInfo;
  ImageInfo? _effectsInfo;
  SpriteSheet? _spriteSheet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      // Загружаем основной tileset
      final tileSetCompleter = Completer<ImageInfo>();
      final tileStream = widget.tileSetImage.resolve(ImageConfiguration.empty);
      tileStream.addListener(
        ImageStreamListener(
          (info, _) => tileSetCompleter.complete(info),
          onError: (e, _) => tileSetCompleter.completeError(e),
        ),
      );

      // Загружаем эффекты
      final effectsCompleter = Completer<ImageInfo>();
      final effectsStream = widget.effectsImage.resolve(ImageConfiguration.empty);
      effectsStream.addListener(
        ImageStreamListener(
          (info, _) => effectsCompleter.complete(info),
          onError: (e, _) => effectsCompleter.completeError(e),
        ),
      );

      final results = await Future.wait([
        tileSetCompleter.future,
        effectsCompleter.future,
      ]);

      final tileInfo = results[0];
      final effectsInfo = results[1];

      // Парсим спрайт-лист
      final spriteSheet = SpriteSheet.fromJson(widget.effectsJson, widget.effectsImage);

      if (mounted) {
        setState(() {
          _tileSetInfo = tileInfo;
          _effectsInfo = effectsInfo;
          _spriteSheet = spriteSheet;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки ресурсов: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tileSetInfo == null) {
      return const Center(child: Text('Не удалось загрузить ресурсы'));
    }

    final tileWidth = widget.mapData['tilewidth'] ?? 64;
    final tileHeight = widget.mapData['tileheight'] ?? 64;
    final mapWidth = widget.mapData['width'] ?? 64;
    final mapHeight = widget.mapData['height'] ?? 48;

    return SizedBox(
      width: (mapWidth * tileWidth).toDouble(),
      height: (mapHeight * tileHeight).toDouble(),
      child: Stack(
        children: [
          // Основные слои тайлов
          ..._buildTileLayers(),

          // Объекты environment
          if (widget.showEffects && _effectsInfo != null && _spriteSheet != null)
            _buildEnvironmentLayer(),
        ],
      ),
    );
  }

  List<Widget> _buildTileLayers() {
    final layers = widget.mapData['layers'] as List<dynamic>? ?? [];

    return layers
        .where((layer) => layer['visible'] == true && layer['type'] == 'tilelayer')
        .map((layer) {
      final data = layer['data'] as List<dynamic>? ?? [];

      return CustomPaint(
        painter: TileLayerPainter(
          imageInfo: _tileSetInfo!,
          tileIds: data.cast<int>(),
          mapWidth: widget.mapData['width'] ?? 64,
          mapHeight: widget.mapData['height'] ?? 48,
          tileWidth: widget.mapData['tilewidth'] ?? 64,
          tileHeight: widget.mapData['tileheight'] ?? 64,
          opacity: (layer['opacity'] ?? 1.0).toDouble(),
        ),
      );
    }).toList();
  }

  Widget _buildEnvironmentLayer() {
    final layers = widget.mapData['layers'] as List<dynamic>? ?? [];
    final envLayer = layers.firstWhere(
      (layer) => layer['name'] == 'environment',
      orElse: () => null,
    );

    if (envLayer == null) return const SizedBox();

    final objects = envLayer['objects'] as List<dynamic>? ?? [];

    return CustomPaint(
      painter: EnvironmentPainter(
        imageInfo: _effectsInfo!,
        spriteSheet: _spriteSheet!,
        objects: objects,
        showLabels: widget.showLabels,
        showDebug: widget.showDebug,
      ),
    );
  }
}
