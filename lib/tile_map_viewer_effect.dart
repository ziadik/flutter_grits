import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_grits/tile_map_viewer.dart';

// Класс для загрузки и парсинга спрайт-листа
class SpriteSheet {
  final ImageProvider image;
  final Map<String, SpriteData> sprites;
  final String imagePath;
  final Size sourceSize;

  SpriteSheet({required this.image, required this.sprites, required this.imagePath, required this.sourceSize});

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

  // Поиск спрайта по имени с поддержкой паттернов
  SpriteData? findSprite(String name) {
    // Прямой поиск
    if (sprites.containsKey(name)) {
      return sprites[name];
    }

    // Поиск по паттерну (например, "energy" в имени файла)
    final matches = sprites.keys.where((key) {
      final normalizedKey = key.toLowerCase().replaceAll('.png', '');
      final normalizedName = name.toLowerCase();
      return normalizedKey.contains(normalizedName) || normalizedName.contains(normalizedKey);
    }).toList();

    if (matches.isNotEmpty) {
      return sprites[matches.first];
    }

    return null;
  }

  // Поиск спрайтов для объектов environment
  Map<String, SpriteData> findSpritesForEnvironment(List<dynamic> objects) {
    final result = <String, SpriteData>{};

    for (final obj in objects) {
      final name = (obj['name'] ?? '').toString().toLowerCase();
      final type = (obj['type'] ?? '').toString().toLowerCase();

      String spriteName = '';

      // Маппинг объектов на спрайты
      if (name.contains('quad')) {
        spriteName = 'powerup'; // или конкретное имя спрайта
      } else if (name.contains('energy') || type.contains('energy')) {
        spriteName = 'energy';
      } else if (name.contains('health') || type.contains('health')) {
        spriteName = 'health';
      } else if (name.contains('spawn') && name.contains('team')) {
        spriteName = 'spawn';
      }

      if (spriteName.isNotEmpty) {
        final sprite = findSprite(spriteName);
        if (sprite != null) {
          result[obj['name']] = sprite;
        }
      }
    }

    return result;
  }
}

class SpriteData {
  final String name;
  final Rect frame;
  final Rect spriteSourceSize;
  final Size sourceSize;
  final bool trimmed;
  final bool rotated;

  SpriteData({required this.name, required this.frame, required this.spriteSourceSize, required this.sourceSize, required this.trimmed, required this.rotated});
}

// Основной виджет с эффектами
class TileMapViewerWithEffects extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final ImageProvider tileSetImage;
  final ImageProvider effectsImage;
  final Map<String, dynamic>? effectsJson;

  const TileMapViewerWithEffects({super.key, required this.mapData, required this.tileSetImage, required this.effectsImage, this.effectsJson});

  @override
  _TileMapViewerWithEffectsState createState() => _TileMapViewerWithEffectsState();
}

class _TileMapViewerWithEffectsState extends State<TileMapViewerWithEffects> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  ImageInfo? _tileSetInfo;
  ImageInfo? _effectsInfo;
  SpriteSheet? _spriteSheet;
  bool _isLoading = true;
  late AnimationController _animationController;

  final Map<String, SpriteAnimation> _animations = {};

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 2000))..repeat();

    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      // Загружаем основной tileset
      final tileSetCompleter = Completer<ImageInfo>();
      final tileStream = widget.tileSetImage.resolve(ImageConfiguration.empty);
      tileStream.addListener(ImageStreamListener((info, _) => tileSetCompleter.complete(info), onError: (e, _) => tileSetCompleter.completeError(e)));

      // Загружаем эффекты
      final effectsCompleter = Completer<ImageInfo>();
      final effectsStream = widget.effectsImage.resolve(ImageConfiguration.empty);
      effectsStream.addListener(ImageStreamListener((info, _) => effectsCompleter.complete(info), onError: (e, _) => effectsCompleter.completeError(e)));

      final [tileInfo, effectsInfo] = await Future.wait([tileSetCompleter.future, effectsCompleter.future]);

      // Парсим спрайт-лист
      SpriteSheet? spriteSheet;
      if (widget.effectsJson != null) {
        spriteSheet = SpriteSheet.fromJson(widget.effectsJson!, widget.effectsImage);

        // Создаем анимации для объектов
        _createAnimations(spriteSheet);
      }

      setState(() {
        _tileSetInfo = tileInfo;
        _effectsInfo = effectsInfo;
        _spriteSheet = spriteSheet;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки ресурсов: $e');
      setState(() => _isLoading = false);
    }
  }

  void _createAnimations(SpriteSheet spriteSheet) {
    // Анимация для энергетических канистр
    final energySprites = spriteSheet.sprites.keys
        .where((key) => key.toLowerCase().contains('energy_canister_red') /*|| key.toLowerCase().contains('canister')*/)
        .map((key) => spriteSheet.sprites[key]!)
        .toList();

    if (energySprites.isNotEmpty) {
      _animations['EnergyCanister'] = SpriteAnimation(sprites: energySprites, frameDuration: Duration(milliseconds: 100));
    }

    // Анимация для аптечек
    final healthSprites = spriteSheet.sprites.keys
        .where((key) => key.toLowerCase().contains('health_canister_blue') /*|| key.toLowerCase().contains('medkit')*/)
        .map((key) => spriteSheet.sprites[key]!)
        .toList();

    if (healthSprites.isNotEmpty) {
      _animations['HealthCanister'] = SpriteAnimation(sprites: healthSprites, frameDuration: Duration(milliseconds: 150));
    }

    // Анимация для QuadDamage
    final quadSprites = spriteSheet.sprites.keys
        .where((key) => key.toLowerCase().contains('quad_damage') /*|| key.toLowerCase().contains('quad') || key.toLowerCase().contains('damage')*/)
        .map((key) => spriteSheet.sprites[key]!)
        .toList();

    if (quadSprites.isNotEmpty) {
      _animations['QuadDamage'] = SpriteAnimation(sprites: quadSprites, frameDuration: Duration(milliseconds: 80));
    }

    // Анимация для спавн-точек
    final spawnSprites = spriteSheet.sprites.keys
        .where((key) => key.toLowerCase().contains('spawner_white_activate') /*|| key.toLowerCase().contains('flag')*/)
        .map((key) => spriteSheet.sprites[key]!)
        .toList();

    if (spawnSprites.isNotEmpty) {
      _animations['SpawnPoint'] = SpriteAnimation(sprites: spawnSprites, frameDuration: Duration(milliseconds: 200));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_tileSetInfo == null) {
      return Center(child: Text('Не удалось загрузить ресурсы'));
    }

    final tileWidth = widget.mapData['tilewidth'] ?? 64;
    final tileHeight = widget.mapData['tileheight'] ?? 64;
    final mapWidth = widget.mapData['width'] ?? 64;
    final mapHeight = widget.mapData['height'] ?? 48;

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      maxScale: 5.0,
      constrained: false,
      child: SizedBox(
        width: (mapWidth * tileWidth).toDouble(),
        height: (mapHeight * tileHeight).toDouble(),
        child: Stack(
          children: [
            // Основные слои тайлов
            ..._buildTileLayers(),

            // Объекты environment с анимациями
            if (_effectsInfo != null && _spriteSheet != null) _buildEnvironmentLayer(),

            // Дебаг-информация
            _buildDebugInfo(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTileLayers() {
    final layers = widget.mapData['layers'] as List<dynamic>? ?? [];

    return layers.where((layer) => layer['visible'] == true && layer['type'] == 'tilelayer').map((layer) {
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
    final envLayer = layers.firstWhere((layer) => layer['name'] == 'environment', orElse: () => null);

    if (envLayer == null) return SizedBox();

    final objects = envLayer['objects'] as List<dynamic>? ?? [];

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: EnvironmentPainter(imageInfo: _effectsInfo!, spriteSheet: _spriteSheet!, objects: objects, animations: _animations, animationValue: _animationController.value),
        );
      },
    );
  }

  Widget _buildDebugInfo() {
    final layers = widget.mapData['layers'] as List<dynamic>? ?? [];
    final envLayer = layers.firstWhere((layer) => layer['name'] == 'environment', orElse: () => null);

    if (envLayer == null) return SizedBox();

    final objects = envLayer['objects'] as List<dynamic>? ?? [];

    return CustomPaint(painter: EnvironmentDebugPainter(objects: objects));
  }
}

// Painter для объектов environment с анимациями
class EnvironmentPainter extends CustomPainter {
  final ImageInfo imageInfo;
  final SpriteSheet spriteSheet;
  final List<dynamic> objects;
  final Map<String, SpriteAnimation> animations;
  final double animationValue;

  EnvironmentPainter({required this.imageInfo, required this.spriteSheet, required this.objects, required this.animations, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in objects) {
      final x = (obj['x'] ?? 0).toDouble();
      final y = (obj['y'] ?? 0).toDouble();
      final width = (obj['width'] ?? 32).toDouble();
      final height = (obj['height'] ?? 32).toDouble();
      final name = (obj['name'] ?? '').toString();
      final type = (obj['type'] ?? '').toString();
      final properties = obj['properties'] as Map<String, dynamic>? ?? {};

      // Определяем тип объекта и соответствующую анимацию
      String animationKey = '';

      if (type == 'Spawner') {
        final spawnItem = properties['SpawnItem']?.toString() ?? '';
        if (spawnItem.contains('QuadDamage')) {
          animationKey = 'QuadDamage';
        } else if (spawnItem.contains('Energy')) {
          animationKey = 'EnergyCanister';
        } else if (spawnItem.contains('Health')) {
          animationKey = 'HealthCanister';
        }
      } else if (type == 'SpawnPoint') {
        animationKey = 'SpawnPoint';
      }

      // Получаем текущий кадр анимации
      SpriteData? sprite;
      if (animationKey.isNotEmpty && animations.containsKey(animationKey)) {
        final animation = animations[animationKey]!;
        final frameIndex = (animationValue * animation.sprites.length).floor() % animation.sprites.length;
        sprite = animation.sprites[frameIndex];
      }

      // Если анимация не найдена, ищем статичный спрайт
      if (sprite == null) {
        final spriteName = _getSpriteNameForObject(name, type, properties);
        sprite = spriteSheet.findSprite(spriteName);
      }

      // Рисуем объект
      if (sprite != null) {
        _drawSprite(canvas, sprite, x, y, width, height, animationValue);
      } else {
        // Запасной вариант: рисуем цветной прямоугольник
        _drawFallback(canvas, name, type, x, y, width, height);
      }

      // Подпись объекта
      _drawLabel(canvas, name, x, y, width);
    }
  }

  String _getSpriteNameForObject(String name, String type, Map<String, dynamic> properties) {
    name = name.toLowerCase();
    type = type.toLowerCase();

    if (name.contains('quad') || type.contains('quad')) {
      return 'powerup';
    } else if (name.contains('energy') || type.contains('energy')) {
      return 'energy';
    } else if (name.contains('health') || type.contains('health')) {
      return 'health';
    } else if (name.contains('spawn') && name.contains('team')) {
      return 'spawn';
    }

    return type.isNotEmpty ? type : name;
  }

  void _drawSprite(Canvas canvas, SpriteData sprite, double x, double y, double width, double height, double animationValue) {
    // Эффект пульсации
    final pulse = 1.0 + 0.1 * math.sin(animationValue * 2 * math.pi);
    final scale = pulse;

    final centerX = x + width / 2;
    final centerY = y + height / 2;

    // Сохраняем состояние канваса
    canvas.save();

    // Применяем трансформации
    canvas.translate(centerX, centerY);
    canvas.scale(scale);
    canvas.translate(-centerX, -centerY);

    // Рисуем спрайт
    final srcRect = sprite.frame;
    final dstRect = Rect.fromLTWH(x, y, width, height);

    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    canvas.drawImageRect(imageInfo.image, srcRect, dstRect, paint);

    // Восстанавливаем состояние канваса
    canvas.restore();

    // Эффект свечения
    if (sprite.name.toLowerCase().contains('powerup')) {
      _drawGlowEffect(canvas, x, y, width, height, animationValue);
    }
  }

  void _drawGlowEffect(Canvas canvas, double x, double y, double width, double height, double animationValue) {
    final glowRadius = width * 0.8 * (1.0 + 0.2 * math.sin(animationValue * 3 * math.pi));

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [Colors.yellow.withOpacity(0.3), Colors.transparent],
        stops: [0.1, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x + width / 2, y + height / 2), radius: glowRadius))
      ..blendMode = BlendMode.plus;

    canvas.drawCircle(Offset(x + width / 2, y + height / 2), glowRadius, paint);
  }

  void _drawFallback(Canvas canvas, String name, String type, double x, double y, double width, double height) {
    Color color;
    if (type == 'Spawner') {
      if (name.contains('Quad')) {
        color = Colors.orange;
      } else if (name.contains('Energy')) {
        color = Colors.blue;
      } else if (name.contains('Health')) {
        color = Colors.green;
      } else {
        color = Colors.purple;
      }
    } else if (type == 'SpawnPoint') {
      color = name.contains('Team0') ? Colors.blue : Colors.red;
    } else {
      color = Colors.grey;
    }

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(x, y, width, height);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);

    // Иконка
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (type == 'Spawner') {
      canvas.drawCircle(Offset(x + width / 2, y + height / 2), math.min(width, height) / 3, iconPaint);
    } else if (type == 'SpawnPoint') {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + width / 2, y + height / 2), width: width * 0.6, height: height * 0.6), Radius.circular(4)), iconPaint);
    }
  }

  void _drawLabel(Canvas canvas, String name, double x, double y, double width) {
    if (name.isEmpty) return;

    final text = name.length > 15 ? '${name.substring(0, 15)}...' : name;
    final span = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 10,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
      ),
    );

    final tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();

    tp.paint(canvas, Offset(x + width / 2 - tp.width / 2, y - tp.height - 2));
  }

  @override
  bool shouldRepaint(covariant EnvironmentPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.objects != objects || oldDelegate.imageInfo != imageInfo;
  }
}

// Painter для дебаг-информации
class EnvironmentDebugPainter extends CustomPainter {
  final List<dynamic> objects;

  EnvironmentDebugPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.normal);

    for (final obj in objects) {
      final x = (obj['x'] ?? 0).toDouble();
      final y = (obj['y'] ?? 0).toDouble();
      final width = (obj['width'] ?? 32).toDouble();
      final name = (obj['name'] ?? '').toString();
      final type = (obj['type'] ?? '').toString();

      // Координаты
      final coordText = '(${x.toInt()}, ${y.toInt()})';
      final coordSpan = TextSpan(text: coordText, style: textStyle);
      final coordTp = TextPainter(text: coordSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr)..layout();

      coordTp.paint(canvas, Offset(x, y + width + 2));

      // Тип
      if (type.isNotEmpty) {
        final typeSpan = TextSpan(text: type, style: textStyle);
        final typeTp = TextPainter(text: typeSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr)..layout();

        typeTp.paint(canvas, Offset(x, y + width + coordTp.height + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Класс для управления анимациями
class SpriteAnimation {
  final List<SpriteData> sprites;
  final Duration frameDuration;

  SpriteAnimation({required this.sprites, required this.frameDuration});
}

// Экран с эффектами
class EffectsMapScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final Map<String, dynamic> effectsJson;

  const EffectsMapScreen({super.key, required this.mapData, required this.effectsJson});

  @override
  _EffectsMapScreenState createState() => _EffectsMapScreenState();
}

class _EffectsMapScreenState extends State<EffectsMapScreen> {
  bool _showEffects = true;
  bool _showLabels = true;
  bool _showDebug = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Карта с эффектами'),
        actions: [
          IconButton(icon: Icon(_showEffects ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showEffects = !_showEffects), tooltip: 'Эффекты'),
          IconButton(icon: Icon(_showLabels ? Icons.label : Icons.label_off), onPressed: () => setState(() => _showLabels = !_showLabels), tooltip: 'Подписи'),
          IconButton(icon: Icon(_showDebug ? Icons.bug_report : Icons.bug_report_outlined), onPressed: () => setState(() => _showDebug = !_showDebug), tooltip: 'Отладка'),
        ],
      ),
      body: _showEffects
          ? TileMapViewerWithEffects(
              mapData: widget.mapData,
              tileSetImage: AssetImage('assets/grits_master.png'),
              effectsImage: AssetImage('assets/grits_effects.png'),
              effectsJson: widget.effectsJson,
            )
          : Center(child: Text('Эффекты отключены')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEnvironmentInfo();
        },
        tooltip: 'Информация об объектах',
        child: Icon(Icons.info),
      ),
    );
  }

  void _showEnvironmentInfo() {
    final layers = widget.mapData['layers'] as List<dynamic>? ?? [];
    final envLayer = layers.firstWhere((layer) => layer['name'] == 'environment', orElse: () => null);

    if (envLayer == null) return;

    final objects = envLayer['objects'] as List<dynamic>? ?? [];

    // Группируем по типу
    final spawners = objects.where((obj) => obj['type'] == 'Spawner').toList();
    final spawnPoints = objects.where((obj) => obj['type'] == 'SpawnPoint').toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Объекты Environment'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Всего объектов: ${objects.length}'),
              SizedBox(height: 10),
              if (spawners.isNotEmpty) ...[
                Text('Спавнеры (${spawners.length}):', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final spawner in spawners) Text('  • ${spawner['name']}: ${spawner['properties']['SpawnItem'] ?? 'N/A'}'),
                SizedBox(height: 10),
              ],
              if (spawnPoints.isNotEmpty) ...[
                Text('Точки спавна (${spawnPoints.length}):', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final point in spawnPoints) Text('  • ${point['name']}: Команда ${point['properties']['team'] ?? 'N/A'}'),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Закрыть'))],
      ),
    );
  }
}
