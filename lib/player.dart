import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

export 'package:flutter_grits/models/sprite_data.dart';
export 'package:flutter_grits/player/player_animator.dart';
export 'package:flutter_grits/player/player_painter.dart';
export 'package:flutter_grits/sprites/sprite_sheet.dart';
export 'package:flutter_grits/painters/tile_layer_painter.dart';
export 'package:flutter_grits/painters/environment_painter.dart';
export 'package:flutter_grits/widgets/tile_map_viewer_with_effects.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tile Map with Effects',
      theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
      home: MapLoaderScreen(),
    );
  }
}

class MapLoaderScreen extends StatefulWidget {
  const MapLoaderScreen({super.key});

  @override
  _MapLoaderScreenState createState() => _MapLoaderScreenState();
}

class _MapLoaderScreenState extends State<MapLoaderScreen> {
  Map<String, dynamic>? _mapData;
  Map<String, dynamic>? _effectsJson;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      // Загружаем карту
      final mapJson = await rootBundle.loadString('assets/maps/small_map1.json');
      final mapData = jsonDecode(mapJson);

      // Загружаем эффекты
      final effectsJson = await rootBundle.loadString('assets/grits_effects.json');
      final effectsData = jsonDecode(effectsJson);

      setState(() {
        _mapData = mapData;
        _effectsJson = effectsData;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text('Загрузка карты...')]),
        ),
      );
    }

    if (_mapData == null || _effectsJson == null) {
      return Scaffold(body: Center(child: Text('Не удалось загрузить ресурсы')));
    }

    return EffectsMapScreen(mapData: _mapData!, effectsJson: _effectsJson!, effectsImage: AssetImage('assets/grits_effects.png'));
  }
}

// Экран с эффектами и игроком
class EffectsMapScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final Map<String, dynamic> effectsJson;
  final ImageProvider effectsImage;

  const EffectsMapScreen({Key? key, required this.mapData, required this.effectsJson, required this.effectsImage}) : super(key: key);

  @override
  _EffectsMapScreenState createState() => _EffectsMapScreenState();
}

class _EffectsMapScreenState extends State<EffectsMapScreen> with TickerProviderStateMixin {
  bool _showEffects = true;
  bool _showLabels = true;
  bool _showDebug = false;
  bool _showPlayer = true;
  bool _followPlayer = true; // Слежение за игроком

  // Управление камерой
  late TransformationController _cameraController;

  // Управление игроком
  final Set<String> _pressedKeys = {};
  late Timer _inputTimer;
  double _moveSpeed = 3.0;

  // Анимация игрока
  late PlayerAnimator _playerAnimator;
  late AnimationController _animationController;

  // Загруженные изображения
  ImageInfo? _effectsImageInfo;

  // Позиция игрока
  double _playerX = 500;
  double _playerY = 500;
  int _playerDirection = 2; // 0: up, 1: left, 2: down, 3: right
  bool _playerWalking = false;
  double _playerAngle = 0;

  @override
  void initState() {
    super.initState();

    // Инициализируем контроллер камеры
    _cameraController = TransformationController();

    // Инициализируем аниматор игрока
    _playerAnimator = PlayerAnimator();
    _playerAnimator.loadFromJson(widget.effectsJson);

    // Контроллер анимации
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 1000))..repeat();

    // Загружаем изображения для PlayerPainter
    _loadEffectsImage();

    _startInputLoop();

    // Подгоняем карту под размер экрана
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToScreen();
    });
  }

  /// Подгоняет карту под размер экрана
  void _fitMapToScreen() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;

    // Получаем размеры карты из данных
    final tileWidth = widget.mapData['tilewidth'] ?? 64;
    final tileHeight = widget.mapData['tileheight'] ?? 64;
    final mapWidth = widget.mapData['width'] ?? 64;
    final mapHeight = widget.mapData['height'] ?? 48;

    // Размер карты в пикселях
    final mapPixelWidth = mapWidth * tileWidth.toDouble();
    final mapPixelHeight = mapHeight * tileHeight.toDouble();

    // Вычисляем масштаб, чтобы карта помещалась в экран
    // Учитываем отступы (10% от размера экрана)
    final padding = 0.1;
    final availableWidth = size.width * (1 - padding);
    final availableHeight = size.height * (1 - padding);

    final scaleX = availableWidth / mapPixelWidth;
    final scaleY = availableHeight / mapPixelHeight;

    // Берём минимальный масштаб, чтобы карта влезла полностью
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Ограничиваем масштаб разумными пределами
    final clampedScale = scale.clamp(0.1, 5.0);

    // Центрируем карту
    final offsetX = (size.width - mapPixelWidth * clampedScale) / 2;
    final offsetY = (size.height - mapPixelHeight * clampedScale) / 2;

    _cameraController.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(clampedScale);
  }

  Future<void> _loadEffectsImage() async {
    final completer = Completer<ImageInfo>();
    final stream = widget.effectsImage.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) => completer.complete(info), onError: (e, _) => completer.completeError(e)));

    try {
      final info = await completer.future;
      if (mounted) {
        setState(() {
          _effectsImageInfo = info;
        });
      }
    } catch (e) {
      print('Ошибка загрузки effectsImage для игрока: $e');
    }
  }

  void _startInputLoop() {
    _inputTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _handleInput();
    });
  }

  void _handleInput() {
    double dx = 0;
    double dy = 0;

    if (_pressedKeys.contains('arrowup') || _pressedKeys.contains('w')) {
      dy -= _moveSpeed;
      _playerDirection = 0;
    }
    if (_pressedKeys.contains('arrowdown') || _pressedKeys.contains('s')) {
      dy += _moveSpeed;
      _playerDirection = 2;
    }
    if (_pressedKeys.contains('arrowleft') || _pressedKeys.contains('a')) {
      dx -= _moveSpeed;
      _playerDirection = 1;
    }
    if (_pressedKeys.contains('arrowright') || _pressedKeys.contains('d')) {
      dx += _moveSpeed;
      _playerDirection = 3;
    }

    if (dx != 0 || dy != 0) {
      setState(() {
        _playerX += dx;
        _playerY += dy;
        _playerWalking = true;

        // Обновляем угол поворота
        if (dx != 0 || dy != 0) {
          _playerAngle = math.atan2(dy, dx);
        }
      });

      // Слежение за игроком
      if (_followPlayer) {
        _updateCameraPosition();
      }
    } else {
      setState(() {
        _playerWalking = false;
      });
    }
  }

  /// Обновляет позицию камеры для слежения за игроком
  void _updateCameraPosition() {
    if (!_followPlayer || !mounted) return;

    final size = MediaQuery.of(context).size;

    // Получаем текущую матрицу трансформации
    final matrix = _cameraController.value;
    final scale = matrix.getMaxScaleOnAxis();

    // Вычисляем размер видимой области в пикселях карты
    final visibleWidth = size.width / scale;
    final visibleHeight = size.height / scale;

    // Целевая позиция игрока (центр экрана)
    final targetX = _playerX * scale - visibleWidth / 2 + 64 * scale;
    final targetY = _playerY * scale - visibleHeight / 2 + 64 * scale;

    // Получаем текущее смещение
    final currentTranslation = matrix.getTranslation();
    final currentX = -currentTranslation.x;
    final currentY = -currentTranslation.y;

    // Плавная интерполяция (lerp)
    const lerpFactor = 0.1;
    final newX = currentX + (targetX - currentX) * lerpFactor;
    final newY = currentY + (targetY - currentY) * lerpFactor;

    // Применяем трансформацию
    _cameraController.value = Matrix4.identity()
      ..translate(newX, newY)
      ..scale(scale);
  }

  /// Центрирует камеру на игроке (одноразово)
  void _centerCameraOnPlayer() {
    final size = MediaQuery.of(context).size;
    final scale = _cameraController.value.getMaxScaleOnAxis();

    // Центрируем игрока на экране
    final x = _playerX * scale - size.width / 2 + 64 * scale;
    final y = _playerY * scale - size.height / 2 + 64 * scale;

    _cameraController.value = Matrix4.identity()
      ..translate(-x / scale, -y / scale)
      ..scale(scale);
  }

  @override
  void dispose() {
    _inputTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    final key = event.logicalKey.keyLabel.toLowerCase();

    if (event is RawKeyDownEvent) {
      setState(() {
        _pressedKeys.add(key);
      });
    } else if (event is RawKeyUpEvent) {
      setState(() {
        _pressedKeys.remove(key);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Карта с эффектами'),
          actions: [
            IconButton(icon: const Icon(Icons.fit_screen), onPressed: () => _fitMapToScreen(), tooltip: 'Вписать карту в экран'),
            IconButton(
              icon: Icon(_followPlayer ? Icons.gps_fixed : Icons.gps_not_fixed),
              onPressed: () => setState(() {
                _followPlayer = !_followPlayer;
                if (_followPlayer) {
                  _centerCameraOnPlayer();
                }
              }),
              tooltip: _followPlayer ? 'Отключить слежение' : 'Слежение за игроком',
            ),
            IconButton(icon: Icon(_showEffects ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _showEffects = !_showEffects), tooltip: 'Эффекты'),
            IconButton(icon: Icon(_showPlayer ? Icons.person : Icons.person_off), onPressed: () => setState(() => _showPlayer = !_showPlayer), tooltip: 'Игрок'),
            IconButton(icon: Icon(_showLabels ? Icons.label : Icons.label_off), onPressed: () => setState(() => _showLabels = !_showLabels), tooltip: 'Подписи'),
          ],
        ),
        body: InteractiveViewer(
          transformationController: _cameraController,
          minScale: 0.1,
          maxScale: 5.0,
          boundaryMargin: EdgeInsets.all(100),
          child: Stack(
            children: [
              // Карта с эффектами
              TileMapViewerWithEffects(
                mapData: widget.mapData,
                tileSetImage: AssetImage('assets/grits_master.png'),
                effectsImage: AssetImage('assets/grits_effects.png'),
                effectsJson: widget.effectsJson,
                showEffects: _showEffects,
                showLabels: _showLabels,
                showDebug: _showDebug,
              ),

              // Игрок
              if (_showPlayer && _effectsImageInfo != null)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Positioned(
                      left: _playerX - 64,
                      top: _playerY - 64,
                      child: CustomPaint(
                        painter: PlayerPainter(
                          animator: _playerAnimator,
                          effectsImageInfo: _effectsImageInfo!,
                          direction: _playerDirection,
                          walking: _playerWalking,
                          animationValue: _animationController.value,
                          angle: _playerAngle,
                          team: 0,
                          name: 'Игрок 1',
                          health: 85,
                          maxHealth: 100,
                          energy: 60,
                          maxEnergy: 100,
                          isLocalPlayer: true,
                        ),
                        size: Size(128, 128),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _playerX = 500;
                  _playerY = 500;
                });
              },
              child: Icon(Icons.refresh),
              tooltip: 'Сбросить позицию игрока',
            ),
          ],
        ),
      ),
    );
  }
}

// Класс для управления камерой с плавной навигацией
class CameraController {
  final TickerProviderStateMixin vsync;
  late AnimationController _animationController;
  late TransformationController _transformationController;

  // Позиция камеры (в тайлах)
  double _cameraX = 0.0;
  double _cameraY = 0.0;

  // Целевая позиция (для плавной навигации)
  double _targetX = 0.0;
  double _targetY = 0.0;

  // Параметры камеры
  double _zoom = 1.0;
  final double _minZoom = 0.1;
  final double _maxZoom = 5.0;
  final double _lerpFactor = 0.1; // Коэффициент интерполяции (чем меньше, тем плавнее)

  // Размер карты
  int _mapWidth = 64;
  int _mapHeight = 48;

  // Размер тайла
  double _tileWidth = 64.0;
  double _tileHeight = 64.0;

  // Ограничения камеры
  bool _enableBounds = true;

  CameraController({required this.vsync, int mapWidth = 64, int mapHeight = 48, double tileWidth = 64.0, double tileHeight = 64.0, double initialZoom = 1.0, bool enableBounds = true})
    : _mapWidth = mapWidth,
      _mapHeight = mapHeight,
      _tileWidth = tileWidth,
      _tileHeight = tileHeight,
      _zoom = initialZoom,
      _enableBounds = enableBounds {
    _animationController =
        AnimationController(vsync: vsync, duration: Duration(milliseconds: 16)) // ~60 FPS
          ..addListener(_updateCamera);

    _transformationController = TransformationController();
  }

  // Получаем текущую позицию камеры
  Offset get cameraPosition {
    return Offset(_cameraX, _cameraY);
  }

  // Получаем целевую позицию
  Offset get targetPosition {
    return Offset(_targetX, _targetY);
  }

  // Получаем текущий масштаб
  double get zoom => _zoom;

  // Устанавливаем целевую позицию (центрируем камеру на точку)
  void followTarget(double targetX, double targetY) {
    _targetX = targetX;
    _targetY = targetY;

    // Ограничиваем цель в пределах карты
    if (_enableBounds) {
      _targetX = _targetX.clamp(0, _mapWidth * _tileWidth - _tileWidth);
      _targetY = _targetY.clamp(0, _mapHeight * _tileHeight - _tileHeight);
    }
  }

  // Устанавливаем позицию камеры (с мгновенным перемещением)
  void setPosition(double x, double y) {
    _cameraX = x;
    _targetX = x;
    _cameraY = y;
    _targetY = y;
  }

  // Устанавливаем масштаб
  void setZoom(double newZoom) {
    _zoom = newZoom.clamp(_minZoom, _maxZoom);
  }

  // Сбрасывает камеру в исходное положение
  void reset() {
    setPosition(0, 0);
    setZoom(1.0);
  }

  // Обновление позиции камеры (интерполяция)
  void _updateCamera() {
    // Плавное перемещение к цели
    _cameraX = _cameraX + (_targetX - _cameraX) * _lerpFactor;
    _cameraY = _cameraY + (_targetY - _cameraY) * _lerpFactor;

    // Применяем трансформацию
    final transform = Matrix4.identity()
      ..translate(_cameraX, _cameraY)
      ..scale(_zoom);

    _transformationController.value = transform;
  }

  // Получаем TransformationController
  TransformationController get transformationController => _transformationController;

  // Обновляем размеры карты
  void updateMapSize(int mapWidth, int mapHeight, double tileWidth, double tileHeight) {
    _mapWidth = mapWidth;
    _mapHeight = mapHeight;
    _tileWidth = tileWidth;
    _tileHeight = tileHeight;

    // Проверяем, не вышла ли камера за границы
    if (_enableBounds) {
      final maxX = _mapWidth * _tileWidth - _tileWidth;
      final maxY = _mapHeight * _tileHeight - _tileHeight;
      _cameraX = _cameraX.clamp(0, maxX);
      _cameraY = _cameraY.clamp(0, maxY);
      _targetX = _targetX.clamp(0, maxX);
      _targetY = _targetY.clamp(0, maxY);
    }
  }

  // Управление камерой (перемещение)
  void moveCamera(double dx, double dy) {
    if (_enableBounds) {
      _targetX = (_targetX - dx).clamp(0, _mapWidth * _tileWidth - _tileWidth);
      _targetY = (_targetY - dy).clamp(0, _mapHeight * _tileHeight - _tileHeight);
    } else {
      _targetX -= dx;
      _targetY -= dy;
    }
  }

  // Управление камерой (зум)
  void zoomCamera(double factor) {
    setZoom(_zoom * factor);
  }

  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
  }
}

// Класс для анимации игрока
class PlayerAnimator {
  final Map<String, List<SpriteData>> _legSpriteAnimList = {};
  final Map<String, List<SpriteData>> _legSpriteMaskAnimList = {};
  final Map<String, SpriteData> _sprites = {};
  bool _loaded = false;

  void loadFromJson(Map<String, dynamic> effectsJson) {
    if (_loaded) return;

    final frames = effectsJson['frames'] as Map<String, dynamic>;

    // Загружаем все спрайты
    frames.forEach((key, value) {
      final frame = value['frame'] as Map<String, dynamic>;
      final spriteSourceSize = value['spriteSourceSize'] as Map<String, dynamic>;
      final sourceSize = value['sourceSize'] as Map<String, dynamic>;

      _sprites[key] = SpriteData(
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

    // Инициализируем анимации ног
    _initLegAnimations();
    _loaded = true;
  }

  void _initLegAnimations() {
    final directions = ['up', 'left', 'down', 'right'];

    for (var dir in directions) {
      final frames = <SpriteData>[];
      final maskFrames = <SpriteData>[];

      // Загружаем кадры для анимации (30 кадров)
      for (int i = 0; i < 30; i++) {
        final frameNumber = i.toString().padLeft(4, '0');
        final spriteName = 'walk_${dir}_${frameNumber}.png';
        final maskSpriteName = 'walk_${dir}_mask_${frameNumber}.png';

        // Ищем спрайты в загруженных данных
        final sprite = _sprites[spriteName];
        final maskSprite = _sprites[maskSpriteName];

        if (sprite != null) {
          frames.add(sprite);
        } else {
          // Запасной вариант, если спрайт не найден
          frames.add(SpriteData(name: spriteName, frame: Rect.fromLTWH(0, 0, 64, 64), spriteSourceSize: Rect.fromLTWH(0, 0, 64, 64), sourceSize: Size(128, 128), trimmed: false, rotated: false));
        }

        if (maskSprite != null) {
          maskFrames.add(maskSprite);
        } else {
          // Запасной вариант, если спрайт не найден
          maskFrames.add(
            SpriteData(name: maskSpriteName, frame: Rect.fromLTWH(0, 0, 64, 64), spriteSourceSize: Rect.fromLTWH(0, 0, 64, 64), sourceSize: Size(128, 128), trimmed: false, rotated: false),
          );
        }
      }

      _legSpriteAnimList[dir] = frames;
      _legSpriteMaskAnimList[dir] = maskFrames;
    }
  }

  SpriteData? getLegSprite(String direction, double animationValue) {
    final frames = _legSpriteAnimList[direction];
    if (frames == null || frames.isEmpty) return null;

    final frameIndex = (animationValue * frames.length).floor() % frames.length;
    return frames[frameIndex];
  }

  SpriteData? getLegMaskSprite(String direction, double animationValue) {
    final frames = _legSpriteMaskAnimList[direction];
    if (frames == null || frames.isEmpty) return null;

    final frameIndex = (animationValue * frames.length).floor() % frames.length;
    return frames[frameIndex];
  }

  SpriteData? getTurretSprite() {
    return _sprites['turret_player_color.png'];
  }
}

// Painter для игрока с анимацией
class PlayerPainter extends CustomPainter {
  final PlayerAnimator animator;
  final ImageInfo effectsImageInfo;
  final int direction;
  final bool walking;
  final double animationValue;
  final double angle;
  final int team;
  final String name;
  final double health;
  final double maxHealth;
  final double energy;
  final double maxEnergy;
  final bool isLocalPlayer;

  PlayerPainter({
    required this.animator,
    required this.effectsImageInfo,
    required this.direction,
    required this.walking,
    required this.animationValue,
    required this.angle,
    required this.team,
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.energy,
    required this.maxEnergy,
    required this.isLocalPlayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Определяем направление для анимации
    String directionName;
    switch (direction) {
      case 0:
        directionName = 'up';
        break;
      case 1:
        directionName = 'left';
        break;
      case 2:
        directionName = 'down';
        break;
      case 3:
        directionName = 'right';
        break;
      default:
        directionName = 'down';
    }

    // Получаем текущий кадр анимации
    final legSprite = walking ? animator.getLegSprite(directionName, animationValue) : animator.getLegSprite(directionName, 0);

    final legMaskSprite = walking ? animator.getLegMaskSprite(directionName, animationValue) : animator.getLegMaskSprite(directionName, 0);

    // Получаем спрайт turret
    final turretSprite = animator.getTurretSprite();

    // Сохраняем состояние канваса
    canvas.save();

    // Центрируем игрока
    canvas.translate(size.width / 2, size.height / 2);

    // Рисуем ноги с маской
    if (legMaskSprite != null) {
      _drawLegMask(canvas, legMaskSprite);
    }

    // Рисуем ноги
    if (legSprite != null) {
      _drawLegs(canvas, legSprite);
    } else {
      _drawDefaultLegs(canvas);
    }

    // Рисуем туловище
    _drawTorso(canvas, size);

    // Рисуем маску команды
    _drawTeamMask(canvas, size);

    // Рисуем пушку
    _drawTurret(canvas, size, turretSprite);

    // Восстанавливаем состояние канваса
    canvas.restore();

    // Рисуем полоски здоровья и энергии
    if (isLocalPlayer) {
      _drawHealthBar(canvas, size);
      _drawEnergyBar(canvas, size);
    } else {
      _drawNameTag(canvas, size);
    }
  }

  void _drawLegMask(Canvas canvas, SpriteData sprite) {
    // Рисуем спрайт маски ног
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false
      ..color = _getTeamColor().withOpacity(0.6)
      ..blendMode = BlendMode.multiply;

    final srcRect = sprite.frame;
    // Масштабируем спрайт под размер игрока
    final scale = 2.0;
    final dstWidth = srcRect.width * scale;
    final dstHeight = srcRect.height * scale;
    final dstRect = Rect.fromCenter(center: Offset.zero, width: dstWidth, height: dstHeight);

    canvas.drawImageRect(effectsImageInfo.image, srcRect, dstRect, paint);
  }

  void _drawLegs(Canvas canvas, SpriteData sprite) {
    // Рисуем спрайт ног
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    final srcRect = sprite.frame;
    // Масштабируем спрайт под размер игрока
    final scale = 2.0;
    final dstWidth = srcRect.width * scale;
    final dstHeight = srcRect.height * scale;
    final dstRect = Rect.fromCenter(center: Offset.zero, width: dstWidth, height: dstHeight);

    canvas.drawImageRect(effectsImageInfo.image, srcRect, dstRect, paint);
  }

  void _drawDefaultLegs(Canvas canvas) {
    final legPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Рисуем простые ноги
    canvas.drawOval(Rect.fromCircle(center: Offset(-15, 0), radius: 12), legPaint);
    canvas.drawOval(Rect.fromCircle(center: Offset(15, 0), radius: 12), legPaint);
  }

  void _drawTorso(Canvas canvas, Size size) {
    // Рисуем туловище (броню/тело)
    final torsoPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, 25, torsoPaint);

    // Обводка туловища
    final borderPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, 25, borderPaint);
  }

  Color _getTeamColor() {
    // Цвета команд
    final teamColors = [
      Color(0xFF33FF33), // Зеленый для команды 0
      Color(0xFFFF9933), // Оранжевый для команды 1
    ];

    return team < teamColors.length ? teamColors[team] : Colors.blue;
  }

  void _drawTeamMask(Canvas canvas, Size size) {
    final maskPaint = Paint()
      ..color = _getTeamColor().withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.multiply;

    canvas.drawCircle(Offset.zero, 22, maskPaint);
  }

  void _drawTurret(Canvas canvas, Size size, SpriteData? turretSprite) {
    canvas.save();
    canvas.rotate(angle + math.pi); // +180 градусов как в оригинале

    if (turretSprite != null) {
      // Рисуем спрайт turret
      final paint = Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false;

      final srcRect = turretSprite.frame;
      final scale = 2.0;
      final dstWidth = srcRect.width * scale;
      final dstHeight = srcRect.height * scale;
      final dstRect = Rect.fromCenter(center: Offset.zero, width: dstWidth, height: dstHeight);

      canvas.drawImageRect(effectsImageInfo.image, srcRect, dstRect, paint);
    } else {
      // Башня
      final turretPaint = Paint()
        ..color = Colors.grey[700]!
        ..style = PaintingStyle.fill;

      final turretRect = Rect.fromCenter(center: Offset(0, 0), width: 40, height: 15);

      canvas.drawRect(turretRect, turretPaint);

      // Дуло
      final barrelPaint = Paint()
        ..color = Colors.grey[900]!
        ..style = PaintingStyle.fill;

      final barrelRect = Rect.fromCenter(center: Offset(30, 0), width: 20, height: 8);

      canvas.drawRect(barrelRect, barrelPaint);
    }

    canvas.restore();
  }

  void _drawHealthBar(Canvas canvas, Size size) {
    final healthPercent = health / maxHealth;
    Color healthColor;

    if (healthPercent >= 0.66) {
      healthColor = Colors.green;
    } else if (healthPercent >= 0.33) {
      healthColor = Colors.orange;
    } else {
      healthColor = Colors.red;
    }

    final barWidth = 60.0;
    final barHeight = 10.0;
    final x = -barWidth / 2;
    final y = -size.height / 2 - 40;

    // Фон
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), bgPaint);

    // Полоска здоровья
    final healthPaint = Paint()
      ..color = healthColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth * healthPercent, barHeight), healthPaint);

    // Рамка
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), borderPaint);
  }

  void _drawEnergyBar(Canvas canvas, Size size) {
    final energyPercent = energy / maxEnergy;
    Color energyColor;

    if (energyPercent >= 0.66) {
      energyColor = Colors.lightBlue;
    } else if (energyPercent >= 0.33) {
      energyColor = Colors.blue;
    } else {
      energyColor = Colors.blue[900]!;
    }

    final barWidth = 60.0;
    final barHeight = 10.0;
    final x = -barWidth / 2;
    final y = -size.height / 2 - 30;

    // Фон
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), bgPaint);

    // Полоска энергии
    final energyPaint = Paint()
      ..color = energyColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth * energyPercent, barHeight), energyPaint);

    // Рамка
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), borderPaint);
  }

  void _drawNameTag(Canvas canvas, Size size) {
    final textStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green);

    final shadowStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black);

    final textSpan = TextSpan(text: name, style: textStyle);
    final shadowSpan = TextSpan(text: name, style: shadowStyle);

    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    final shadowPainter = TextPainter(text: shadowSpan, textDirection: TextDirection.ltr)..layout();

    final x = -textPainter.width / 2;
    final y = -size.height / 2 - 40;

    // Тень
    shadowPainter.paint(canvas, Offset(x + 1, y + 1));

    // Основной текст
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant PlayerPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.walking != walking ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.angle != angle ||
        oldDelegate.health != health ||
        oldDelegate.energy != energy;
  }
}

// Остальные классы (TileMapViewerWithEffects, SpriteSheet, SpriteData, EnvironmentPainter, TileLayerPainter)
// остаются такими же, как в предыдущем коде...

// Добавьте эти классы из предыдущего ответа:

class SpriteData {
  final String name;
  final Rect frame;
  final Rect spriteSourceSize;
  final Size sourceSize;
  final bool trimmed;
  final bool rotated;

  SpriteData({required this.name, required this.frame, required this.spriteSourceSize, required this.sourceSize, required this.trimmed, required this.rotated});
}

class TileMapViewerWithEffects extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final ImageProvider tileSetImage;
  final ImageProvider effectsImage;
  final Map<String, dynamic> effectsJson;
  final bool showEffects;
  final bool showLabels;
  final bool showDebug;

  const TileMapViewerWithEffects({
    Key? key,
    required this.mapData,
    required this.tileSetImage,
    required this.effectsImage,
    required this.effectsJson,
    this.showEffects = true,
    this.showLabels = true,
    this.showDebug = false,
  }) : super(key: key);

  @override
  _TileMapViewerWithEffectsState createState() => _TileMapViewerWithEffectsState();
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
      tileStream.addListener(ImageStreamListener((info, _) => tileSetCompleter.complete(info), onError: (e, _) => tileSetCompleter.completeError(e)));

      // Загружаем эффекты
      final effectsCompleter = Completer<ImageInfo>();
      final effectsStream = widget.effectsImage.resolve(ImageConfiguration.empty);
      effectsStream.addListener(ImageStreamListener((info, _) => effectsCompleter.complete(info), onError: (e, _) => effectsCompleter.completeError(e)));

      final [tileInfo, effectsInfo] = await Future.wait([tileSetCompleter.future, effectsCompleter.future]);

      // Парсим спрайт-лист
      final spriteSheet = SpriteSheet.fromJson(widget.effectsJson, widget.effectsImage);

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

    return Container(
      width: (mapWidth * tileWidth).toDouble(),
      height: (mapHeight * tileHeight).toDouble(),
      child: Stack(
        children: [
          // Основные слои тайлов
          ..._buildTileLayers(),

          // Объекты environment
          if (widget.showEffects && _effectsInfo != null && _spriteSheet != null) _buildEnvironmentLayer(),
        ],
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

    return CustomPaint(
      painter: EnvironmentPainter(imageInfo: _effectsInfo!, spriteSheet: _spriteSheet!, objects: objects, showLabels: widget.showLabels, showDebug: widget.showDebug),
    );
  }
}

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

class EnvironmentPainter extends CustomPainter {
  final ImageInfo imageInfo;
  final SpriteSheet spriteSheet;
  final List<dynamic> objects;
  final bool showLabels;
  final bool showDebug;

  EnvironmentPainter({required this.imageInfo, required this.spriteSheet, required this.objects, this.showLabels = true, this.showDebug = false});

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

      // Определяем спрайт для объекта
      String spriteName = '';

      if (type == 'Spawner') {
        final spawnItem = properties['SpawnItem']?.toString() ?? '';
        if (spawnItem.contains('QuadDamage')) {
          spriteName = 'powerup';
        } else if (spawnItem.contains('Energy')) {
          spriteName = 'energy';
        } else if (spawnItem.contains('Health')) {
          spriteName = 'health';
        }
      } else if (type == 'SpawnPoint') {
        spriteName = 'spawn';
      }

      SpriteData? sprite;
      if (spriteName.isNotEmpty) {
        sprite = spriteSheet.findSprite(spriteName);
      }

      // Рисуем объект
      if (sprite != null) {
        _drawSprite(canvas, sprite, x, y, width, height);
      } else {
        _drawFallback(canvas, name, type, x, y, width, height);
      }

      // Подпись объекта
      if (showLabels && name.isNotEmpty) {
        _drawLabel(canvas, name, x, y, width);
      }

      // Отладочная информация
      if (showDebug) {
        _drawDebugInfo(canvas, obj, x, y, width, height);
      }
    }
  }

  void _drawSprite(Canvas canvas, SpriteData sprite, double x, double y, double width, double height) {
    final srcRect = sprite.frame;
    final dstRect = Rect.fromLTWH(x, y, width, height);

    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    canvas.drawImageRect(imageInfo.image, srcRect, dstRect, paint);
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
    final textStyle = TextStyle(
      fontSize: 10,
      color: Colors.white,
      shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
    );

    final tp = TextPainter(
      text: TextSpan(text: name, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final shadowTp = TextPainter(
      text: TextSpan(text: name, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final xPos = x + width / 2 - tp.width / 2;
    final yPos = y - tp.height - 2;

    // Тень
    shadowTp.paint(canvas, Offset(xPos + 1, yPos + 1));

    // Основной текст
    tp.paint(canvas, Offset(xPos, yPos));
  }

  void _drawDebugInfo(Canvas canvas, dynamic obj, double x, double y, double width, double height) {
    final textStyle = TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.normal);

    // Координаты
    final coordText = '(${x.toInt()}, ${y.toInt()})';
    final coordSpan = TextSpan(text: coordText, style: textStyle);
    final coordTp = TextPainter(text: coordSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr)..layout();

    coordTp.paint(canvas, Offset(x, y + height + 2));
  }

  @override
  bool shouldRepaint(covariant EnvironmentPainter oldDelegate) {
    return oldDelegate.objects != objects || oldDelegate.showLabels != showLabels || oldDelegate.showDebug != showDebug;
  }
}

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
