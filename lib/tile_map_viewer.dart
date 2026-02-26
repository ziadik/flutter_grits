import 'dart:math';

import 'package:flutter/material.dart';

class ScrollableTileMapViewer extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final ImageProvider tileSetImage;
  final bool showGrid;
  final bool showCollisions;
  final bool showSpawnPoints;

  const ScrollableTileMapViewer({super.key, required this.mapData, required this.tileSetImage, this.showGrid = false, this.showCollisions = false, this.showSpawnPoints = false});

  @override
  _ScrollableTileMapViewerState createState() => _ScrollableTileMapViewerState();
}

class _ScrollableTileMapViewerState extends State<ScrollableTileMapViewer> {
  late TransformationController _transformationController;
  late ImageProvider _tileSetImage;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  bool _isLoading = true;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _tileSetImage = widget.tileSetImage;
    _loadTileSet();
  }

  void _loadTileSet() {
    final ImageStream stream = _tileSetImage.resolve(ImageConfiguration.empty);
    _imageStream = stream;
    stream.addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          setState(() {
            _imageInfo = info;
            _isLoading = false;
          });
        },
        onError: (Object error, StackTrace? stackTrace) {
          print('Ошибка загрузки tileset: $error');
          setState(() {
            _isLoading = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener((_, _) {}));
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _scale = 1.0;
    });
  }

  void _zoomIn() {
    _transformationController.value = Matrix4.identity()..scale(_scale * 1.2);
    setState(() {
      _scale *= 1.2;
    });
  }

  void _zoomOut() {
    _transformationController.value = Matrix4.identity()..scale(_scale / 1.2);
    setState(() {
      _scale /= 1.2;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_imageInfo == null) {
      return Center(child: Text('Не удалось загрузить tileset'));
    }

    final tileWidth = widget.mapData['tilewidth'] ?? 64;
    final tileHeight = widget.mapData['tileheight'] ?? 64;
    final mapWidth = widget.mapData['width'] ?? 64;
    final mapHeight = widget.mapData['height'] ?? 48;
    final layers = widget.mapData['layers'] as List<dynamic>? ?? [];

    final totalWidth = mapWidth * tileWidth;
    final totalHeight = mapHeight * tileHeight;

    return Stack(
      children: [
        // Основная карта с зумом и скроллом
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 5.0,
          boundaryMargin: EdgeInsets.all(20),
          constrained: false,
          child: Container(
            width: totalWidth.toDouble(),
            height: totalHeight.toDouble(),
            child: Stack(
              children: [
                // Слои тайлов
                ...layers.where((layer) => layer['visible'] == true).map((layer) {
                  final data = layer['data'] as List<dynamic>? ?? [];

                  return CustomPaint(
                    painter: TileLayerPainter(
                      imageInfo: _imageInfo!,
                      tileIds: data.cast<int>(),
                      mapWidth: mapWidth,
                      mapHeight: mapHeight,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      opacity: (layer['opacity'] ?? 1.0).toDouble(),
                    ),
                  );
                }).toList(),

                // Сетка для отладки
                if (widget.showGrid)
                  CustomPaint(
                    painter: GridPainter(tileWidth: tileWidth, tileHeight: tileHeight, mapWidth: mapWidth, mapHeight: mapHeight),
                  ),

                // Коллизии
                if (widget.showCollisions) _buildCollisionsLayer(widget.mapData),

                // Точки спавна
                if (widget.showSpawnPoints) _buildSpawnPointsLayer(widget.mapData),
              ],
            ),
          ),
        ),

        // Кнопки управления в правом нижнем углу
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(heroTag: 'zoom_in', onPressed: _zoomIn, tooltip: 'Увеличить', child: Icon(Icons.add)),
              SizedBox(height: 8),
              FloatingActionButton.small(heroTag: 'zoom_out', onPressed: _zoomOut, tooltip: 'Уменьшить', child: Icon(Icons.remove)),
              SizedBox(height: 8),
              FloatingActionButton.small(heroTag: 'reset', onPressed: _resetView, tooltip: 'Сбросить вид', child: Icon(Icons.refresh)),
            ],
          ),
        ),

        // Индикатор масштаба
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
            child: Text('Масштаб: ${(_scale * 100).toStringAsFixed(0)}%', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildCollisionsLayer(Map<String, dynamic> mapData) {
    final layers = mapData['layers'] as List<dynamic>? ?? [];
    final collisionLayer = layers.firstWhere((layer) => layer['name'] == 'collision', orElse: () => null);

    if (collisionLayer == null) return SizedBox();

    final objects = collisionLayer['objects'] as List<dynamic>? ?? [];

    return CustomPaint(painter: CollisionPainter(objects: objects));
  }

  Widget _buildSpawnPointsLayer(Map<String, dynamic> mapData) {
    final layers = mapData['layers'] as List<dynamic>? ?? [];
    final envLayer = layers.firstWhere((layer) => layer['name'] == 'environment', orElse: () => null);

    if (envLayer == null) return SizedBox();

    final objects = envLayer['objects'] as List<dynamic>? ?? [];

    return CustomPaint(painter: SpawnPointsPainter(objects: objects));
  }
}

// Альтернативная версия с двойным скроллом (горизонтальный + вертикальный)
class DoubleScrollableTileMapViewer extends StatelessWidget {
  final Map<String, dynamic> mapData;
  final ImageProvider tileSetImage;

  const DoubleScrollableTileMapViewer({super.key, required this.mapData, required this.tileSetImage});

  @override
  Widget build(BuildContext context) {
    final tileWidth = mapData['tilewidth'] ?? 64;
    final tileHeight = mapData['tileheight'] ?? 64;
    final mapWidth = mapData['width'] ?? 64;
    final mapHeight = mapData['height'] ?? 48;

    final totalWidth = mapWidth * tileWidth;
    final totalHeight = mapHeight * tileHeight;

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth.toDouble(),
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                height: totalHeight.toDouble(),
                child: ScrollableTileMapViewer(mapData: mapData, tileSetImage: tileSetImage),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Продолжение painter классов...
class TileLayerPainter extends CustomPainter {
  final ImageInfo imageInfo;
  final List<int> tileIds;
  final int mapWidth;
  final int mapHeight;
  final int tileWidth;
  final int tileHeight;
  final double opacity;

  TileLayerPainter({required this.imageInfo, required this.tileIds, required this.mapWidth, required this.mapHeight, required this.tileWidth, required this.tileHeight, required this.opacity});

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
        Rect.fromLTWH(x * tileWidth.toDouble(), y * tileHeight.toDouble(), tileWidth.toDouble(), tileHeight.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TileLayerPainter oldDelegate) {
    return oldDelegate.imageInfo != imageInfo || oldDelegate.tileIds != tileIds || oldDelegate.opacity != opacity;
  }
}

class GridPainter extends CustomPainter {
  final int tileWidth;
  final int tileHeight;
  final int mapWidth;
  final int mapHeight;

  GridPainter({required this.tileWidth, required this.tileHeight, required this.mapWidth, required this.mapHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(100)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Вертикальные линии
    for (int x = 0; x <= mapWidth; x++) {
      canvas.drawLine(Offset(x * tileWidth.toDouble(), 0), Offset(x * tileWidth.toDouble(), mapHeight * tileHeight.toDouble()), paint);
    }

    // Горизонтальные линии
    for (int y = 0; y <= mapHeight; y++) {
      canvas.drawLine(Offset(0, y * tileHeight.toDouble()), Offset(mapWidth * tileWidth.toDouble(), y * tileHeight.toDouble()), paint);
    }

    // Номера тайлов

    for (int y = 0; y < mapHeight; y++) {
      for (int x = 0; x < mapWidth; x++) {
        final text = '($x,$y)';
        final span = TextSpan(
          text: text,
          style: TextStyle(fontSize: 10, color: Colors.blue.withOpacity(0.7)),
        );
        final tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();

        tp.paint(canvas, Offset(x * tileWidth.toDouble() + 2, y * tileHeight.toDouble() + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CollisionPainter extends CustomPainter {
  final List<dynamic> objects;

  CollisionPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final obj in objects) {
      final x = (obj['x'] ?? 0).toDouble();
      final y = (obj['y'] ?? 0).toDouble();
      final width = (obj['width'] ?? 0).toDouble();
      final height = (obj['height'] ?? 0).toDouble();

      final rect = Rect.fromLTWH(x, y, width, height);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // Подпись коллизии
      final text = '${width.toInt()}x${height.toInt()}';
      final span = TextSpan(
        text: text,
        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();

      tp.paint(canvas, Offset(x + width / 2 - tp.width / 2, y + height / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpawnPointsPainter extends CustomPainter {
  final List<dynamic> objects;

  SpawnPointsPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in objects) {
      final x = (obj['x'] ?? 0).toDouble();
      final y = (obj['y'] ?? 0).toDouble();
      final width = (obj['width'] ?? 0).toDouble();
      final height = (obj['height'] ?? 0).toDouble();
      final name = (obj['name'] ?? '').toString();
      final type = (obj['type'] ?? '').toString();

      Color color;
      if (name.contains('Team0')) {
        color = Colors.blue;
      } else if (name.contains('Team1')) {
        color = Colors.red;
      } else if (type == 'Spawner') {
        color = Colors.green;
      } else {
        color = Colors.purple;
      }

      final paint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromLTWH(x, y, width, height);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // Иконка спавна
      final iconPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x + width / 2, y + height / 2), min(width, height) / 3, iconPaint);

      // Название точки
      final span = TextSpan(
        text: name.isNotEmpty ? name : type,
        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();

      tp.paint(canvas, Offset(x + width / 2 - tp.width / 2, y - tp.height - 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Экран с настройками и картой
class MapViewerScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final ImageProvider tileSetImage;

  const MapViewerScreen({super.key, required this.mapData, required this.tileSetImage});

  @override
  _MapViewerScreenState createState() => _MapViewerScreenState();
}

class _MapViewerScreenState extends State<MapViewerScreen> {
  bool _showGrid = false;
  bool _showCollisions = false;
  bool _showSpawnPoints = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Просмотр карты'),
        actions: [
          // Кнопки настройки
          IconButton(icon: Icon(Icons.grid_on), color: _showGrid ? Colors.blue : null, onPressed: () => setState(() => _showGrid = !_showGrid), tooltip: 'Сетка'),
          IconButton(icon: Icon(Icons.border_all), color: _showCollisions ? Colors.red : null, onPressed: () => setState(() => _showCollisions = !_showCollisions), tooltip: 'Коллизии'),
          IconButton(icon: Icon(Icons.person_pin), color: _showSpawnPoints ? Colors.green : null, onPressed: () => setState(() => _showSpawnPoints = !_showSpawnPoints), tooltip: 'Точки спавна'),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Экспорт в PNG'),
                onTap: () {
                  // Экспорт карты
                },
              ),
              PopupMenuItem(
                child: Text('Информация о карте'),
                onTap: () {
                  _showMapInfo();
                },
              ),
            ],
          ),
        ],
      ),
      body: ScrollableTileMapViewer(mapData: widget.mapData, tileSetImage: widget.tileSetImage, showGrid: _showGrid, showCollisions: _showCollisions, showSpawnPoints: _showSpawnPoints),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Быстрая навигация к важным точкам
          _showNavigationMenu();
        },
        tooltip: 'Навигация',
        child: Icon(Icons.explore),
      ),
    );
  }

  void _showMapInfo() {
    final tileWidth = widget.mapData['tilewidth'] ?? 64;
    final tileHeight = widget.mapData['tileheight'] ?? 64;
    final mapWidth = widget.mapData['width'] ?? 64;
    final mapHeight = widget.mapData['height'] ?? 48;
    final layers = widget.mapData['layers'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Информация о карте'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Размер: ${mapWidth}x$mapHeight тайлов'),
              Text('Размер тайла: ${tileWidth}x${tileHeight}px'),
              Text('Общий размер: ${mapWidth * tileWidth}x${mapHeight * tileHeight}px'),
              SizedBox(height: 10),
              Text('Слои (${layers.length}):'),
              for (final layer in layers) Text('  • ${layer['name']}: ${layer['type']}, видимый: ${layer['visible']}'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }

  void _showNavigationMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Быстрая навигация', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildNavButton('Команда 1', Colors.blue, 1244, 950),
                _buildNavButton('Команда 2', Colors.red, 2906, 2094),
                _buildNavButton('Квад урон', Colors.orange, 2748, 1022),
                _buildNavButton('Здоровье', Colors.green, 1905, 854),
                _buildNavButton('Энергия', Colors.purple, 1917, 1053),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String text, Color color, double x, double y) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        // Здесь можно добавить навигацию к точке
      },
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(text),
    );
  }
}
