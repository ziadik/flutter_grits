// // lib/components/trimmed_sprite_animation_component.dart
// import 'dart:ui';
// import 'package:flame/components.dart';
// import 'package:flutter_grits/flame_game/models/player_animator.dart';
// import 'package:vector_math/vector_math.dart';
// import '../models/player_animator.dart';

// class TrimmedSpriteAnimationComponent extends PositionComponent {
//   List<TrimmedSprite> _frames = [];
//   double _stepTime = 0.1;
//   double _currentTime = 0;
//   int _currentFrame = 0;
//   bool _loop = true;
//   Paint? _paint;

//   TrimmedSpriteAnimationComponent({
//     required super.size,
//     required super.anchor,
//     List<TrimmedSprite>? frames,
//     double stepTime = 0.1,
//     bool loop = true,
//     Paint? paint,
//   }) {
//     if (frames != null) {
//       _frames = frames;
//     }
//     _stepTime = stepTime;
//     _loop = loop;
//     _paint = paint;
//   }

//   void setAnimation(
//     List<TrimmedSprite> frames, {
//     double stepTime = 0.1,
//     bool loop = true,
//   }) {
//     _frames = frames;
//     _stepTime = stepTime;
//     _loop = loop;
//     _currentFrame = 0;
//     _currentTime = 0;
//   }

//   @override
//   void render(Canvas canvas) {
//     super.render(canvas);

//     if (_frames.isEmpty) return;

//     final frame = _frames[_currentFrame];
//     final renderPosition = Vector2(0, 0); // Относительно компонента

//     frame.render(canvas, renderPosition, size, _paint);
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);

//     if (_frames.isEmpty) return;

//     _currentTime += dt;

//     if (_currentTime >= _stepTime) {
//       _currentTime = 0;
//       _currentFrame++;

//       if (_currentFrame >= _frames.length) {
//         if (_loop) {
//           _currentFrame = 0;
//         } else {
//           _currentFrame = _frames.length - 1;
//         }
//       }
//     }
//   }
// }
