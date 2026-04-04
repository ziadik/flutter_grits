import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grits/player/player_animator.dart';
import 'package:flutter_grits/widgets/game_player_widget.dart';
import 'package:flutter_grits/widgets/tile_map_viewer_with_effects.dart';

class EffectsMapScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final Map<String, dynamic> effectsJson;
  final ImageProvider effectsImage;

  const EffectsMapScreen({
    super.key,
    required this.mapData,
    required this.effectsJson,
    required this.effectsImage,
  });

  @override
  State<EffectsMapScreen> createState() => _EffectsMapScreenState();
}

class _EffectsMapScreenState extends State<EffectsMapScreen>
    with TickerProviderStateMixin {
  bool _showEffects = true;
  bool _showLabels = true;
  bool _showDebug = false;
  bool _showPlayer = true;
  bool _followPlayer = true;

  late TransformationController _cameraController;

  final Set<String> _activeKeys = {};

  late Timer _inputTimer;
  final double _moveSpeed = 3.0;

  late PlayerAnimator _playerAnimator;
  late AnimationController _animationController;

  ImageInfo? _effectsImageInfo;
  bool _isLoadingEffects = true;

  double _playerX = 0;
  double _playerY = 0;
  int _playerDirection = 2;
  bool _playerWalking = false;
  double _playerAngle = 0;

  late int _mapWidth;
  late int _mapHeight;
  late int _tileWidth;
  late int _tileHeight;

  double _currentScale = 1.0;

  // Флаг для отслеживания, было ли ручное взаимодействие
  bool _wasManualInteraction = false;
  Timer? _manualInteractionTimer;

  @override
  void initState() {
    super.initState();

    _tileWidth = widget.mapData['tilewidth'] ?? 64;
    _tileHeight = widget.mapData['tileheight'] ?? 64;
    _mapWidth = widget.mapData['width'] ?? 64;
    _mapHeight = widget.mapData['height'] ?? 48;

    final centerTileX = _mapWidth ~/ 2;
    final centerTileY = _mapHeight ~/ 2;
    _playerX = (centerTileX * _tileWidth).toDouble();
    _playerY = (centerTileY * _tileHeight).toDouble();

    _cameraController = TransformationController();
    _playerAnimator = PlayerAnimator();
    _playerAnimator.loadFromJson(widget.effectsJson);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _loadEffectsImage();
    _startInputLoop();

    HardwareKeyboard.instance.addHandler(_handleHardwareKey);

    _cameraController.addListener(_onCameraChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToScreen();
    });
  }

  void _onCameraChanged() {
    if (mounted) {
      final scale = _cameraController.value.getMaxScaleOnAxis();
      if (_currentScale != scale) {
        setState(() {
          _currentScale = scale;
        });
      }
    }
  }

  bool _handleHardwareKey(KeyEvent event) {
    final key = event.logicalKey.keyLabel.toLowerCase();

    const moveKeys = {
      'w',
      'a',
      's',
      'd',
      'arrowup',
      'arrowleft',
      'arrowdown',
      'arrowright',
    };

    if (!moveKeys.contains(key)) {
      return false;
    }

    if (event is KeyDownEvent) {
      if (!_activeKeys.contains(key)) {
        setState(() {
          _activeKeys.add(key);
        });
        // При движении с клавиатуры включаем слежение
        if (_followPlayer == false && _wasManualInteraction) {
          setState(() {
            _followPlayer = true;
            _wasManualInteraction = false;
          });
        }
      }
    } else if (event is KeyUpEvent) {
      setState(() {
        _activeKeys.remove(key);
      });
    }

    return true;
  }

  Future<void> _loadEffectsImage() async {
    final completer = Completer<ImageInfo>();
    final stream = widget.effectsImage.resolve(ImageConfiguration.empty);

    stream.addListener(
      ImageStreamListener(
        (info, _) => completer.complete(info),
        onError: (e, _) => completer.completeError(e),
      ),
    );

    try {
      final info = await completer.future;
      if (mounted) {
        setState(() {
          _effectsImageInfo = info;
          _isLoadingEffects = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки effectsImage: $e');
      if (mounted) {
        setState(() => _isLoadingEffects = false);
      }
    }
  }

  void _startInputLoop() {
    _inputTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _handleInput();
    });
  }

  void _handleInput() {
    double dx = 0;
    double dy = 0;
    int newDirection = _playerDirection;

    if (_activeKeys.contains('w') || _activeKeys.contains('arrowup')) {
      dy -= _moveSpeed;
      newDirection = 0;
    }
    if (_activeKeys.contains('s') || _activeKeys.contains('arrowdown')) {
      dy += _moveSpeed;
      newDirection = 2;
    }
    if (_activeKeys.contains('a') || _activeKeys.contains('arrowleft')) {
      dx -= _moveSpeed;
      newDirection = 1;
    }
    if (_activeKeys.contains('d') || _activeKeys.contains('arrowright')) {
      dx += _moveSpeed;
      newDirection = 3;
    }

    final isMoving = dx != 0 || dy != 0;

    if (isMoving) {
      setState(() {
        double newX = _playerX + dx;
        double newY = _playerY + dy;

        final minX = 0.0;
        final maxX = (_mapWidth * _tileWidth).toDouble() - 32;
        final minY = 0.0;
        final maxY = (_mapHeight * _tileHeight).toDouble() - 32;

        _playerX = newX.clamp(minX, maxX);
        _playerY = newY.clamp(minY, maxY);
        _playerDirection = newDirection;

        if (!_playerWalking) {
          _playerWalking = true;
        }

        if (dx != 0 || dy != 0) {
          _playerAngle = math.atan2(dy, dx);
        }
      });

      // Всегда обновляем позицию камеры, если слежение включено
      if (_followPlayer) {
        _updateCameraPosition();
      }
    } else if (_playerWalking) {
      setState(() {
        _playerWalking = false;
      });
    }
  }

  void _updateCameraPosition() {
    if (!_followPlayer || !mounted) return;

    final size = MediaQuery.of(context).size;
    final scale = _currentScale;

    final mapWidthPx = (_mapWidth * _tileWidth).toDouble();
    final mapHeightPx = (_mapHeight * _tileHeight).toDouble();

    // Желаемая позиция камеры (центр на игроке)
    double targetX = (_playerX + 32) * scale - size.width / 2;
    double targetY = (_playerY + 32) * scale - size.height / 2;

    final maxX = (mapWidthPx * scale) - size.width;
    final maxY = (mapHeightPx * scale) - size.height;

    // Ограничиваем позицию
    double clampedX;
    double clampedY;

    if (maxX <= 0) {
      clampedX = (size.width - mapWidthPx * scale) / 2;
    } else {
      clampedX = targetX.clamp(0.0, maxX);
    }

    if (maxY <= 0) {
      clampedY = (size.height - mapHeightPx * scale) / 2;
    } else {
      clampedY = targetY.clamp(0.0, maxY);
    }

    // Применяем трансформацию
    double finalX;
    double finalY;

    if (maxX <= 0) {
      finalX = clampedX;
    } else {
      finalX = -clampedX;
    }

    if (maxY <= 0) {
      finalY = clampedY;
    } else {
      finalY = -clampedY;
    }

    _cameraController.value = Matrix4.identity()
      ..translate(finalX, finalY)
      ..scale(scale);
  }

  void _fitMapToScreen() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    final mapWidthPx = (_mapWidth * _tileWidth).toDouble();
    final mapHeightPx = (_mapHeight * _tileHeight).toDouble();

    final scaleX = size.width / mapWidthPx;
    final scaleY = size.height / mapHeightPx;
    double scale = math.min(scaleX, scaleY);
    scale = scale.clamp(0.3, 3.0);

    final offsetX = (size.width - mapWidthPx * scale) / 2;
    final offsetY = (size.height - mapHeightPx * scale) / 2;

    _cameraController.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale);

    setState(() {
      _currentScale = scale;
    });
  }

  void _centerCameraOnPlayer() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    final mapWidthPx = (_mapWidth * _tileWidth).toDouble();
    final mapHeightPx = (_mapHeight * _tileHeight).toDouble();
    final scale = _currentScale;

    double targetX = (_playerX + 32) * scale - size.width / 2;
    double targetY = (_playerY + 32) * scale - size.height / 2;

    final maxX = (mapWidthPx * scale) - size.width;
    final maxY = (mapHeightPx * scale) - size.height;

    double finalX;
    double finalY;

    if (maxX <= 0) {
      finalX = (size.width - mapWidthPx * scale) / 2;
    } else {
      finalX = -targetX.clamp(0.0, maxX);
    }

    if (maxY <= 0) {
      finalY = (size.height - mapHeightPx * scale) / 2;
    } else {
      finalY = -targetY.clamp(0.0, maxY);
    }

    _cameraController.value = Matrix4.identity()
      ..translate(finalX, finalY)
      ..scale(scale);
  }

  @override
  void dispose() {
    _inputTimer.cancel();
    _manualInteractionTimer?.cancel();
    _animationController.dispose();
    _cameraController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Карта с эффектами'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: () {
              _fitMapToScreen();
              if (_followPlayer) {
                _centerCameraOnPlayer();
              }
            },
          ),
          IconButton(
            icon: Icon(_followPlayer ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () {
              setState(() {
                _followPlayer = !_followPlayer;
                _wasManualInteraction = false;
                if (_followPlayer) {
                  _centerCameraOnPlayer();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_showEffects ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showEffects = !_showEffects),
          ),
          IconButton(
            icon: Icon(_showPlayer ? Icons.person : Icons.person_off),
            onPressed: () => setState(() => _showPlayer = !_showPlayer),
          ),
        ],
      ),
      body: _isLoadingEffects
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onPanStart: (_) {
                // При начале ручного перетаскивания отключаем слежение
                if (_followPlayer) {
                  setState(() {
                    _followPlayer = false;
                    _wasManualInteraction = true;
                  });
                }
              },
              child: InteractiveViewer(
                transformationController: _cameraController,
                minScale: 0.3,
                maxScale: 3.0,
                boundaryMargin: EdgeInsets.zero,
                constrained: false,
                onInteractionEnd: (details) {
                  // Не включаем слежение обратно автоматически
                  // Пользователь должен нажать кнопку GPS
                },
                child: SizedBox(
                  width: (_mapWidth * _tileWidth).toDouble(),
                  height: (_mapHeight * _tileHeight).toDouble(),
                  child: Stack(
                    children: [
                      TileMapViewerWithEffects(
                        mapData: widget.mapData,
                        tileSetImage: const AssetImage(
                          'assets/grits_master.png',
                        ),
                        effectsImage: const AssetImage(
                          'assets/grits_effects.png',
                        ),
                        effectsJson: widget.effectsJson,
                        showEffects: _showEffects,
                        showLabels: _showLabels,
                        showDebug: _showDebug,
                      ),
                      if (_showPlayer && _effectsImageInfo != null)
                        Positioned(
                          left: _playerX,
                          top: _playerY,
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: GamePlayerWidget(
                              animator: _playerAnimator,
                              effectsImageInfo: _effectsImageInfo!,
                              playerX: 0,
                              playerY: 0,
                              playerDirection: _playerDirection,
                              playerWalking: _playerWalking,
                              playerAngle: _playerAngle,
                              team: 0,
                              name: 'Игрок 1',
                              health: 85,
                              maxHealth: 100,
                              energy: 60,
                              maxEnergy: 100,
                              isLocalPlayer: true,
                              animationController: _animationController,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          setState(() {
            final centerTileX = _mapWidth ~/ 2;
            final centerTileY = _mapHeight ~/ 2;
            _playerX = (centerTileX * _tileWidth).toDouble();
            _playerY = (centerTileY * _tileHeight).toDouble();
            _fitMapToScreen();
            _followPlayer = true;
            _wasManualInteraction = false;
            _centerCameraOnPlayer();
          });
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
