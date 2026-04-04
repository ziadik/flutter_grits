import 'package:flutter/material.dart';
import 'package:flutter_grits/player/player_animator.dart';
import 'package:flutter_grits/player/player_painter.dart';

class GamePlayerWidget extends StatelessWidget {
  final PlayerAnimator animator;
  final ImageInfo effectsImageInfo;
  final double playerX;
  final double playerY;
  final int playerDirection;
  final bool playerWalking;
  final double playerAngle;
  final int team;
  final String name;
  final double health;
  final double maxHealth;
  final double energy;
  final double maxEnergy;
  final bool isLocalPlayer;
  final AnimationController animationController;

  const GamePlayerWidget({
    super.key,
    required this.animator,
    required this.effectsImageInfo,
    required this.playerX,
    required this.playerY,
    required this.playerDirection,
    required this.playerWalking,
    required this.playerAngle,
    required this.team,
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.energy,
    required this.maxEnergy,
    required this.isLocalPlayer,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        // Убеждаемся что значение анимации - double
        final animationValue = animationController.value;

        return CustomPaint(
          painter: PlayerPainter(
            animator: animator,
            effectsImageInfo: effectsImageInfo,
            direction: playerDirection,
            walking: playerWalking,
            animationValue: animationValue, // Это уже double
            angle: playerAngle,
            team: team,
            name: name,
            health: health,
            maxHealth: maxHealth,
            energy: energy,
            maxEnergy: maxEnergy,
            isLocalPlayer: isLocalPlayer,
          ),
          size: const Size(64, 64),
        );
      },
    );
  }
}
