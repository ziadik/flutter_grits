// lib/flame_game/components/hud/weapon_indicator.dart
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';

/// Индикатор текущего оружия в HUD
///
/// Отображает:
/// - Номера слотов (1, 2, 3)
/// - Названия оружия во всех слотах
/// - Выделенный слот (подсветка)
class WeaponIndicatorComponent extends PositionComponent {
  final Player player;
  final Vector2 _size;

  late TextComponent _slot1Label;
  late TextComponent _slot2Label;
  late TextComponent _slot3Label;
  late RectangleComponent _background;
  late RectangleComponent _selectionBorder;

  WeaponIndicatorComponent({
    required this.player,
    Vector2? position,
    Vector2? size,
  }) : _size = size ?? Vector2(350, 50),
       super(position: position ?? Vector2(20, 20), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _createComponents();
    await _updateDisplay();
  }

  Future<void> _createComponents() async {
    // Фон
    _background = RectangleComponent(
      size: _size,
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
    await add(_background);

    // Слот 1
    _slot1Label = TextComponent(
      position: Vector2(10, 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      text: '1: Empty',
    );
    await add(_slot1Label);

    // Слот 2
    _slot2Label = TextComponent(
      position: Vector2(105, 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      text: '2: Empty',
    );
    await add(_slot2Label);

    // Слот 3
    _slot3Label = TextComponent(
      position: Vector2(200, 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      text: '3: Empty',
    );
    await add(_slot3Label);

    // Подсветка выбранного слота (рамка снизу)
    _selectionBorder = RectangleComponent(
      size: Vector2(80, 6),
      position: Vector2(5, 20),
      paint: Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    await add(_selectionBorder);
  }

  /// Обновить отображение (вызывать при смене оружия)
  Future<void> _updateDisplay() async {
    final slot = player.selectedWeaponSlot;

    // Обновить все слоты
    _slot1Label.text = _formatWeaponText(0);
    _slot2Label.text = _formatWeaponText(1);
    _slot3Label.text = _formatWeaponText(2);

    // Обновить позицию рамки выделения
    _selectionBorder.position = Vector2(10 + (slot * 95), 38);

    // Подсветка цветом текста выбранного слота
    _updateSlotColors(slot);
  }

  String _formatWeaponText(int slotNum) {
    final weapon = player.getWeapon(slotNum);
    final color = slotNum == player.selectedWeaponSlot ? '🟡' : '';
    return '${slotNum + 1}: ${weapon?.displayName ?? 'Empty'} $color';
  }

  void _updateSlotColors(int selectedSlot) {
    final color = selectedSlot == 0 ? Colors.yellow : Colors.white;
    _slot1Label.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 14,
        color: color,
        fontWeight: selectedSlot == 0 ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final color2 = selectedSlot == 1 ? Colors.yellow : Colors.white;
    _slot2Label.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 14,
        color: color2,
        fontWeight: selectedSlot == 1 ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final color3 = selectedSlot == 2 ? Colors.yellow : Colors.white;
    _slot3Label.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 14,
        color: color3,
        fontWeight: selectedSlot == 2 ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Проверка на изменение выбранного оружия
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
