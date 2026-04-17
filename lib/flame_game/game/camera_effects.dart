// lib/flame_game/game/camera_effects.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

extension CameraEffects on CameraComponent {
  // Эффект тряски камеры
  void shake({double intensity = 10.0, double duration = 0.3}) {
    final shakeEffect = MoveEffect.by(
      Vector2(
        math.Random().nextDouble() * intensity - intensity / 2,
        math.Random().nextDouble() * intensity - intensity / 2,
      ),
      EffectController(duration: duration, infinite: true),
    );
    viewfinder.add(shakeEffect);
  }

  // Плавный зум
  void zoomTo(double targetZoom, {double duration = 0.5}) {
    viewfinder.add(
      ScaleEffect.by(
        Vector2.all((targetZoom / viewfinder.zoom) - 1),
        EffectController(duration: duration, curve: Curves.easeInOut),
      ),
    );
  }

  // Плавное перемещение к точке
  void moveToPosition(Vector2 target, {double duration = 0.5}) {
    viewfinder.add(
      MoveEffect.to(
        target,
        EffectController(duration: duration, curve: Curves.easeInOut),
      ),
    );
  }

  // Плавное перемещение относительно текущей позиции
  void moveByOffset(Vector2 offset, {double duration = 0.5}) {
    final target = viewfinder.position + offset;
    viewfinder.add(
      MoveEffect.to(
        target,
        EffectController(duration: duration, curve: Curves.easeInOut),
      ),
    );
  }

  // Комбинированный эффект (зум + перемещение)
  void zoomAndMove({
    required double targetZoom,
    required Vector2 targetPosition,
    double duration = 0.5,
  }) {
    // Добавляем параллельные эффекты
    viewfinder.addAll([
      ScaleEffect.by(
        Vector2.all((targetZoom / viewfinder.zoom) - 1),
        EffectController(duration: duration, curve: Curves.easeInOut),
      ),
      MoveEffect.to(
        targetPosition,
        EffectController(duration: duration, curve: Curves.easeInOut),
      ),
    ]);
  }

  // Эффект "удара" (быстрый зум и возврат)
  void hitShake({double intensity = 5.0, double duration = 0.15}) {
    final originalPosition = viewfinder.position;
    final shakeCount = 3;
    final stepDuration = duration / shakeCount;

    for (int i = 0; i < shakeCount; i++) {
      final delay = stepDuration * i;
      final offset = Vector2(
        (i % 2 == 0 ? 1 : -1) * intensity * (1 - i / shakeCount),
        (i % 3 == 0 ? 1 : -1) * intensity * (1 - i / shakeCount),
      );

      Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
        viewfinder.position = originalPosition + offset;
      });
    }

    // Возвращаем на место
    Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
      viewfinder.position = originalPosition;
    });
  }

  // Эффект "взрыва" (тряска + быстрый зум)
  void explosionEffect({double intensity = 15.0, double zoomAmount = 1.2}) {
    // Быстрый зум
    viewfinder.add(
      ScaleEffect.by(
        Vector2.all(zoomAmount - 1),
        EffectController(duration: 0.1, curve: Curves.easeOut),
      ),
    );

    // Тряска
    shake(intensity: intensity, duration: 0.3);

    // Возврат зума
    Future.delayed(const Duration(milliseconds: 200), () {
      viewfinder.add(
        ScaleEffect.by(
          Vector2.all(1.0 / zoomAmount - 1),
          EffectController(duration: 0.3, curve: Curves.easeInOut),
        ),
      );
    });
  }

  // Плавное изменение границ камеры
  void animateBounds(Rect newBounds, {double duration = 0.5}) {
    // Анимируем через эффект (если нужно плавное изменение границ)
    // Это более сложный эффект, требует кастомной реализации
    // Для простоты просто устанавливаем новые границы
    // Примечание: setBounds в Flame работает с Vector2, не с Rect
    // Здесь можно реализовать кастомную логику ограничений
  }
}
