import 'package:flutter/material.dart';
import 'package:flutter_grits/player/player_animator.dart';
import 'package:flutter_grits/player/player_painter.dart';

/// Виджет для отображения игрока на карте
class GamePlayerWidget extends StatefulWidget {
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
  State<GamePlayerWidget> createState() => _GamePlayerWidgetState();
}

class _GamePlayerWidgetState extends State<GamePlayerWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Positioned(
          left: widget.playerX - 64,
          top: widget.playerY - 64,
          child: CustomPaint(
            painter: PlayerPainter(
              animator: widget.animator,
              effectsImageInfo: widget.effectsImageInfo,
              direction: widget.playerDirection,
              walking: widget.playerWalking,
              animationValue: widget.animationController.value,
              angle: widget.playerAngle,
              team: widget.team,
              name: widget.name,
              health: widget.health,
              maxHealth: widget.maxHealth,
              energy: widget.energy,
              maxEnergy: widget.maxEnergy,
              isLocalPlayer: widget.isLocalPlayer,
            ),
            size: const Size(128, 128),
          ),
        );
      },
    );
  }
}
