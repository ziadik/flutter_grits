// lib/flame_game/components/hud/weapon_indicator.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/weapons/weapon_base.dart';
import 'package:flutter_grits/flame_game/models/player_animator.dart';

/// Кастомный компонент для отображения TrimmedSprite
class TrimmedSpriteComponent extends PositionComponent {
  TrimmedSprite? trimmedSprite;
  final Paint? paint;

  TrimmedSpriteComponent({
    this.trimmedSprite,
    this.paint,
    required super.position,
    required super.size,
  });

  @override
  void render(Canvas canvas) {
    if (trimmedSprite != null) {
      canvas.save();
      // Перемещаемся в центр компонента
      canvas.translate(size.x / 2, size.y / 2);

      // Рисуем спрайт с центром в (0,0)
      trimmedSprite!.renderCentered(
        canvas,
        Vector2.zero(),
        Size(size.x, size.y),
        paint,
      );

      canvas.restore();
    }
  }
}

/// Индикатор текущего оружия в HUD
///
/// Отображает:
/// - Иконки оружия во всех 10 слотах (1-9, 0)
/// - Выделенный слот (подсветка жёлтым)
class WeaponIndicatorComponent extends PositionComponent {
  final Player player;
  final Vector2 _size;

  // Размеры иконки оружия
  static const double _iconSize = 32;
  static const double _slotWidth = 65;
  static const double _slotHeight = 45;

  // Компоненты для каждого слота
  final List<TrimmedSpriteComponent> _slotIcons = [];
  final List<RectangleComponent> _slotBorders = [];
  final List<TextComponent> _slotLabels = [];

  late RectangleComponent _background;
  late RectangleComponent _selectionBorder;

  WeaponIndicatorComponent({
    required this.player,
    Vector2? position,
    Vector2? size,
  }) : _size = size ?? Vector2(430, 50),
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
    // Фон
    _background = RectangleComponent(
      size: _size,
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
    // await add(_background);

    // Создаём 6 слотов
    for (int i = 0; i < 6; i++) {
      final x = 10 + (i * _slotWidth);

      // Рамка слота
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

      // Иконка оружия (изначально пустая)
      final icon = TrimmedSpriteComponent(
        trimmedSprite: null,
        position: Vector2(x - (_slotWidth - 128 / 2), 0),
        size: Vector2(_iconSize, _iconSize),
      );
      _slotIcons.add(icon);
      await add(icon);

      // Номер слота (1-6)
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

    // Подсветка выбранного слота (рамка снизу)
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

  /// Обновить отображение (вызывать при смене оружия)
  Future<void> _updateDisplay() async {
    final selectedSlot = player.selectedWeaponSlot;

    // Обновить все слоты
    for (int i = 0; i < 6; i++) {
      final weapon = player.getWeapon(i);
      _updateSlot(i, weapon, i == selectedSlot);
    }

    // Обновить позицию рамки выделения
    _selectionBorder.position = Vector2(10 + (selectedSlot * _slotWidth), 38);
  }

  void _updateSlot(int slotIndex, WeaponBase? weapon, bool isSelected) {
    final icon = _slotIcons[slotIndex];

    if (weapon != null && weapon.weaponSpriteName.isNotEmpty) {
      // Получаем спрайт оружия из аниматора
      final animator = player.resourceManager.playerAnimator;
      final trimmedSprite = animator.getSprite(weapon.weaponSpriteName);

      if (trimmedSprite != null) {
        // Устанавливаем спрайт
        icon.trimmedSprite = trimmedSprite;
        debugPrint(
          '✅ Weapon icon set for slot $slotIndex: ${weapon.weaponSpriteName}',
        );
        debugPrint(
          '   Sprite size: ${trimmedSprite.spriteSourceSize.width}x${trimmedSprite.spriteSourceSize.height}',
        );
      } else {
        // Спрайт не найден
        icon.trimmedSprite = null;
        debugPrint('❌ Weapon sprite NOT FOUND: ${weapon.weaponSpriteName}');
      }
    } else {
      // Нет оружия
      icon.trimmedSprite = null;
    }

    // Обновляем цвет рамки слота
    final border = _slotBorders[slotIndex];
    border.paint.color = isSelected
        ? Colors.yellow.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.3);
    border.paint.strokeWidth = isSelected ? 2 : 1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateDisplay();
  }

  /// Получить компонент для добавления в игру
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
