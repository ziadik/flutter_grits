// lib/flame_game/components/hud/weapon_indicator.dart
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';

/// Иконка оружия из grits_interface.png
class WeaponIconComponent extends PositionComponent {
  static const double _iconWidth = 48;
  static const double _iconHeight = 48;

  // Координаты иконок оружия из grits_interface.json
  static const Map<String, Offset> _weaponIconPositions = {
    'MachineGun': Offset(1322, 826),
    'ShotGun': Offset(1322, 1026),
    'ChainGun': Offset(1948, 994),
    'RocketLauncher': Offset(1322, 926),
    'GrenadeLauncher': Offset(1948, 1044),
    'Railgun': Offset(1322, 876),
    'Shield': Offset(1322, 976),
    'Landmine': Offset(1948, 1094),
    'Thrusters': Offset(1322, 1076),
  };

  ui.Image? _interfaceImage;
  String? _currentWeaponName;

  WeaponIconComponent({required super.position, required super.size});

  Future<void> loadInterfaceImage() async {
    final bytes = await rootBundle.load('assets/grits_interface.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _interfaceImage = frame.image;
  }

  void setWeaponIcon(String weaponName) {
    _currentWeaponName = weaponName;
  }

  void clearIcon() {
    _currentWeaponName = null;
  }

  @override
  void render(Canvas canvas) {
    if (_interfaceImage == null) {
      debugPrint('❌ WeaponIconComponent: interface image not loaded');
      return;
    }
    if (_currentWeaponName == null) {
      debugPrint('❌ WeaponIconComponent: no weapon name set');
      return;
    }

    final offset = _weaponIconPositions[_currentWeaponName];
    if (offset == null) {
      debugPrint(
        '❌ WeaponIconComponent: no icon position for $_currentWeaponName',
      );
      return;
    }

    debugPrint(
      '🖼️ Rendering icon: $_currentWeaponName at (${offset.dx}, ${offset.dy})',
    );

    // Рисуем часть спрайт-листа
    final srcRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      _iconWidth,
      _iconHeight,
    );

    final destRect = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawImageRect(_interfaceImage!, srcRect, destRect, Paint());
  }
}

/// Индикатор текущего оружия в HUD
class WeaponIndicatorComponent extends PositionComponent {
  final Player player;
  final Vector2 _size;

  static const double _iconSize = 48;
  static const double _slotWidth = 65;
  static const double _slotHeight = 45;

  final List<WeaponIconComponent> _slotIcons = [];
  final List<RectangleComponent> _slotBorders = [];
  final List<TextComponent> _slotLabels = [];

  late RectangleComponent _background;
  late RectangleComponent _selectionBorder;

  WeaponIndicatorComponent({
    required this.player,
    Vector2? position,
    Vector2? size,
  }) : _size = size ?? Vector2(430, 58),
       super(position: position ?? Vector2(20, 20), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    debugPrint('🔫 WeaponIndicatorComponent: onLoad started');
    await super.onLoad();
    await _createComponents();
    debugPrint('🔫 WeaponIndicatorComponent: components created');
    await _updateDisplay();
    debugPrint('🔫 WeaponIndicatorComponent: onLoad completed');
  }

  Future<void> _createComponents() async {
    _background = RectangleComponent(
      size: _size,
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
    // await add(_background);

    for (int i = 0; i < 6; i++) {
      final x = 10 + (i * _slotWidth);

      final border = RectangleComponent(
        size: Vector2(_slotWidth - 5, _slotHeight),
        position: Vector2(x, 5),
        paint: Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      _slotBorders.add(border);
      await add(border);

      final icon = WeaponIconComponent(
        position: Vector2(x + (_slotWidth - _iconSize) / 2, 5),
        size: Vector2(_iconSize, _iconSize),
      );
      await icon.loadInterfaceImage();
      _slotIcons.add(icon);
      await add(icon);

      final label = TextComponent(
        position: Vector2(x + 5, 3),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        text: '${i + 1}',
      );
      _slotLabels.add(label);
      await add(label);
    }

    _selectionBorder = RectangleComponent(
      size: Vector2(_slotWidth - 5, 4),
      position: Vector2(10, 38),
      paint: Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // await add(_selectionBorder);
  }

  Future<void> _updateDisplay() async {
    final selectedSlot = player.selectedWeaponSlot;

    for (int i = 0; i < 6; i++) {
      final weapon = player.getWeapon(i);
      _updateSlot(i, weapon, i == selectedSlot);
    }

    _selectionBorder.position = Vector2(10 + (selectedSlot * _slotWidth), 38);
  }

  void _updateSlot(int slotIndex, WeaponBase? weapon, bool isSelected) {
    final icon = _slotIcons[slotIndex];

    if (weapon != null) {
      debugPrint('🔧 Slot $slotIndex: weapon="${weapon.displayName}"');
      final weaponName = _getWeaponIconName(weapon.displayName);
      debugPrint('🔧 Slot $slotIndex: iconName="$weaponName"');
      if (weaponName != null) {
        icon.setWeaponIcon(weaponName);
        debugPrint('✅ Weapon icon set for slot $slotIndex: $weaponName');
      } else {
        icon.clearIcon();
        debugPrint('❌ No icon mapping for: ${weapon.displayName}');
      }
    } else {
      icon.clearIcon();
      debugPrint('⚠️ Slot $slotIndex: no weapon');
    }

    final border = _slotBorders[slotIndex];
    border.paint.color = isSelected
        ? Colors.yellow.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.3);
    border.paint.strokeWidth = isSelected ? 2 : 1;
  }

  String? _getWeaponIconName(String displayName) {
    switch (displayName) {
      case 'Machine Gun':
        return 'MachineGun';
      case 'Shot Gun':
        return 'ShotGun';
      case 'Chain Gun':
        return 'ChainGun';
      case 'Rocket Launcher':
        return 'RocketLauncher';
      case 'Grenade Launcher':
        return 'GrenadeLauncher';
      case 'Railgun':
        return 'Railgun';
      case 'Shield':
        return 'Shield';
      case 'Landmines':
        return 'Landmine';
      case 'Energy Sword':
        return 'Shield'; // Используем offensive shield icon
      case 'Thrusters':
        return 'Thrusters';
      default:
        return null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateDisplay();
  }

  static Future<WeaponIndicatorComponent> create({
    required Player player,
    Vector2? position,
  }) async {
    final indicator = WeaponIndicatorComponent(
      player: player,
      position: position,
    );
    await indicator.onLoad();
    return indicator;
  }
}
