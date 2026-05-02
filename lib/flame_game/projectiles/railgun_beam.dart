import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_grits/flame_game/entities/player.dart';
import 'package:flutter_grits/flame_game/game/world/game_world.dart';

/// Луч Railgun - мгновенный луч с линейной коллизией
class RailgunBeam extends PositionComponent with CollisionCallbacks {
  final Player owner;
  final double damage;
  final double lifetime;
  final Vector2 direction;

  // Для отрисовки луча
  late Paint _beamPaint;
  late Paint _glowPaint;
  double _timer = 0;

  // Флаг защиты от двойного уничтожения
  bool _isDestroyed = false;

  RailgunBeam({
    required Vector2 position,
    required this.owner,
    required this.direction,
    required this.damage,
    required this.lifetime,
  }) : super(position: position, size: Vector2(0, 0), anchor: Anchor.center) {
    _beamPaint = Paint()
      ..color =
          Color(0xFF00FFFF) // Голубой цвет луча
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    _glowPaint = Paint()
      ..color = Color(0xFF80FFFF).withValues(alpha: 0.3)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Создаем хитбокс (линейный)
    // Для мгновенного луча используем прямоугольник вдоль направления
    final beamLength = 2000; // Максимальная длина луча
    final beamWidth = 20; // Ширина луча

    size = Vector2(beamLength.toDouble(), beamWidth.toDouble());
    anchor = Anchor.centerLeft; // Начало луча в центре игрока

    // Создаем хитбокс для коллизий
    final hitbox = RectangleHitbox(
      position: Vector2(beamLength / 2.0, 0),
      anchor: Anchor.center,
      size: Vector2(beamLength.toDouble(), beamWidth.toDouble()),
    );
    hitbox.collisionType = CollisionType.passive;
    add(hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _timer += dt;
    if (_timer >= lifetime) {
      destroy();
    }
  }

  @override
  void render(Canvas canvas) {
    // Эффект свечения
    canvas.drawLine(Offset(0, 0), Offset(size.x, 0), _glowPaint);

    // Основной луч
    canvas.drawLine(Offset(0, 0), Offset(size.x, 0), _beamPaint);

    // Ядро луча (белое)
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 0), Offset(size.x, 0), corePaint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (_isDestroyed) return;

    // Игнорируем владельца
    if (other is Player && other == owner) return;

    // Игнорируем другие лучи
    if (other is RailgunBeam) return;

    // Обрабатываем столкновение
    debugPrint(
      '🔦 Railgun hit ${other.runtimeType} at ${intersectionPoints.first}',
    );

    // Наносим урон всем объектам в точке пересечения
    if (other is Player && other != owner) {
      other.takeDamage(damage);
      debugPrint('💥 Railgun damaged Player for $damage');
    }

    // Создаем эффект удара в точке столкновения
    if (intersectionPoints.isNotEmpty) {
      createImpactEffect(intersectionPoints.first);
    }

    // Луч исчезает после первого попадания
    destroy();
  }

  void createImpactEffect(Vector2 position) {
    // Создаем эффект удара (можно использовать существующий или новый)
    final impact = RailgunImpactEffect(position: position);
    final gameWorld = owner.findParent<GameWorld>();
    if (gameWorld != null) {
      gameWorld.add(impact);
    }
  }

  void destroy() {
    if (_isDestroyed) return;
    _isDestroyed = true;
    removeFromParent();
  }
}

/// Эффект удара Railgun
class RailgunImpactEffect extends PositionComponent {
  double _timer = 0;
  static const _duration = 0.2;

  RailgunImpactEffect({required Vector2 position})
    : super(position: position, size: Vector2(30, 30), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _timer / _duration).clamp(0.0, 1.0);

    // Круговой эффект
    canvas.drawCircle(
      Offset(0, 0),
      15 * (1 - _timer / _duration),
      Paint()
        ..color = Color(0xFF00FFFF).withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Ядро
    canvas.drawCircle(
      Offset(0, 0),
      5 * (1 - _timer / _duration),
      Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill,
    );
  }
}
