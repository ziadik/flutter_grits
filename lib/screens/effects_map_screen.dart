import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grits/player/player_animator.dart';
import 'package:flutter_grits/widgets/game_player_widget.dart';
import 'package:flutter_grits/widgets/tile_map_viewer_with_effects.dart';

/// Основной экран игры с эффектами и игроком
class EffectsMapScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final Map<String, dynamic> effectsJson;
  final ImageProvider effectsImage;

  const EffectsMapScreen({super.key, required this.mapData, required this.effectsJson, required this.effectsImage});

  @override
  State<EffectsMapScreen> createState() => _EffectsMapScreenState();
}

class _EffectsMapScreenState extends State<EffectsMapScreen> with TickerProviderStateMixin {
  bool _showEffects = true;
  bool _showLabels = true;
  bool _showDebug = false;
  bool _showPlayer = true;
  bool _followPlayer = true;

  // Управление камерой
  late TransformationController _cameraController;

  // Управление игроком
  final Set<String> _pressedKeys = {};
  late Timer _inputTimer;
  final double _moveSpeed = 3.0;

  // Анимация игрока
  late PlayerAnimator _playerAnimator;
  late AnimationController _animationController;

  // Загруженные изображения
  ImageInfo? _effectsImageInfo;

  // Позиция игрока
  double _playerX = 500;
  double _playerY = 500;
  int _playerDirection = 2;
  bool _playerWalking = false;
  double _playerAngle = 0;

  @override
  void initState() {
    super.initState();
    _cameraController = TransformationController();

    _playerAnimator = PlayerAnimator();
    _playerAnimator.loadFromJson(widget.effectsJson);

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

    _loadEffectsImage();
    _startInputLoop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToScreen();
    });
  }

  Future<void> _loadEffectsImage() async {
    final completer = Completer<ImageInfo>();
    final stream = widget.effectsImage.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) => completer.complete(info), onError: (e, _) => completer.completeError(e)));

    try {
      final info = await completer.future;
      if (mounted) {
        setState(() => _effectsImageInfo = info);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки effectsImage: $e');
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
        if (dx != 0 || dy != 0) {
          _playerAngle = math.atan2(dy, dx);
        }
      });

      if (_followPlayer) {
        _updateCameraPosition();
      }
    } else {
      setState(() => _playerWalking = false);
    }
  }

  void _updateCameraPosition() {
    if (!_followPlayer || !mounted) return;

    final size = MediaQuery.of(context).size;
    final matrix = _cameraController.value;
    final scale = matrix.getMaxScaleOnAxis();

    final visibleWidth = size.width / scale;
    final visibleHeight = size.height / scale;

    final targetX = _playerX * scale - visibleWidth / 2 + 64 * scale;
    final targetY = _playerY * scale - visibleHeight / 2 + 64 * scale;

    final currentTranslation = matrix.getTranslation();
    final currentX = -currentTranslation.x;
    final currentY = -currentTranslation.y;

    const lerpFactor = 0.1;
    final newX = currentX + (targetX - currentX) * lerpFactor;
    final newY = currentY + (targetY - currentY) * lerpFactor;

    _cameraController.value = Matrix4.identity()
      ..translate(newX, newY)
      ..scale(scale);
  }

  void _fitMapToScreen() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    final tileWidth = widget.mapData['tilewidth'] ?? 64;
    final tileHeight = widget.mapData['tileheight'] ?? 64;
    final mapWidth = widget.mapData['width'] ?? 64;
    final mapHeight = widget.mapData['height'] ?? 48;

    final mapPixelWidth = mapWidth * tileWidth.toDouble();
    final mapPixelHeight = mapHeight * tileHeight.toDouble();

    const padding = 0.1;
    final availableWidth = size.width * (1 - padding);
    final availableHeight = size.height * (1 - padding);

    final scaleX = availableWidth / mapPixelWidth;
    final scaleY = availableHeight / mapPixelHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final clampedScale = scale.clamp(0.1, 5.0);

    final offsetX = (size.width - mapPixelWidth * clampedScale) / 2;
    final offsetY = (size.height - mapPixelHeight * clampedScale) / 2;

    _cameraController.value = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(clampedScale);
  }

  void _centerCameraOnPlayer() {
    final size = MediaQuery.of(context).size;
    final scale = _cameraController.value.getMaxScaleOnAxis();

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
    _cameraController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    final key = event.logicalKey.keyLabel.toLowerCase();

    if (event is RawKeyDownEvent) {
      setState(() => _pressedKeys.add(key));
    } else if (event is RawKeyUpEvent) {
      setState(() => _pressedKeys.remove(key));
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
          title: const Text('Карта с эффектами'),
          actions: [
            IconButton(icon: const Icon(Icons.fit_screen), onPressed: _fitMapToScreen, tooltip: 'Вписать карту в экран'),
            IconButton(
              icon: Icon(_followPlayer ? Icons.gps_fixed : Icons.gps_not_fixed),
              onPressed: () {
                setState(() {
                  _followPlayer = !_followPlayer;
                  if (_followPlayer) _centerCameraOnPlayer();
                });
              },
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
          boundaryMargin: const EdgeInsets.all(100),
          child: Stack(
            children: [
              TileMapViewerWithEffects(
                mapData: widget.mapData,
                tileSetImage: const AssetImage('assets/grits_master.png'),
                effectsImage: const AssetImage('assets/grits_effects.png'),
                effectsJson: widget.effectsJson,
                showEffects: _showEffects,
                showLabels: _showLabels,
                showDebug: _showDebug,
              ),
              if (_showPlayer && _effectsImageInfo != null)
                GamePlayerWidget(
                  animator: _playerAnimator,
                  effectsImageInfo: _effectsImageInfo!,
                  playerX: _playerX,
                  playerY: _playerY,
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
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () {
            setState(() {
              _playerX = 500;
              _playerY = 500;
            });
          },
          tooltip: 'Сбросить позицию игрока',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
