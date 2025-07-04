import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_models.dart';

class GamePainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final double rotation;
  final List<Platform> platforms;
  final List<TrailPoint> trail;
  final List<ScoreEffect> scoreEffects;
  final double cameraOffset;
  final double screenWidth;
  final double screenHeight;
  final bool isPressed;
  final bool isOnGround;

  GamePainter({
    required this.playerX,
    required this.playerY,
    required this.rotation,
    required this.platforms,
    required this.trail,
    required this.scoreEffects,
    required this.cameraOffset,
    required this.screenWidth,
    required this.screenHeight,
    required this.isPressed,
    required this.isOnGround,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawTrail(canvas, size);
    _drawPlatforms(canvas, size);
    _drawPlayer(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1a0a2e), Color(0xFF16213e), Color(0xFF0f3460)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
  }

  void _drawTrail(Canvas canvas, Size size) {
    for (TrailPoint point in trail) {
      double screenX = point.x - cameraOffset;
      if (screenX > -20 && screenX < size.width + 20) {
        Paint trailPaint = Paint()
          ..color = Colors.cyan.withOpacity(point.opacity * 0.8)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(screenX, point.y), point.size, trailPaint);
      }
    }
  }

  void _drawPlatforms(Canvas canvas, Size size) {
    for (Platform platform in platforms) {
      double screenX = platform.x - cameraOffset;
      if (screenX + platform.width > -50 && screenX < size.width + 50) {
        if (platform.type == PlatformType.curved) {
          _drawCurvedPlatform(canvas, screenX, platform);
        } else {
          _drawNormalPlatform(canvas, screenX, platform);
        }
      }
    }
  }

  void _drawCurvedPlatform(Canvas canvas, double screenX, Platform platform) {
    // Platform glow effect
    Paint glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    Path curvePath = Path();
    curvePath.moveTo(screenX, platform.y + platform.height);
    curvePath.quadraticBezierTo(
      screenX + platform.width / 2,
      platform.y - 20,
      screenX + platform.width,
      platform.y + platform.height,
    );
    curvePath.lineTo(
      screenX + platform.width,
      platform.y + platform.height + 15,
    );
    curvePath.quadraticBezierTo(
      screenX + platform.width / 2,
      platform.y + 5,
      screenX,
      platform.y + platform.height + 15,
    );
    curvePath.close();

    canvas.drawPath(curvePath, glowPaint);

    // Main curved platform
    Paint platformPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    Path mainPath = Path();
    mainPath.moveTo(screenX, platform.y + platform.height);
    mainPath.quadraticBezierTo(
      screenX + platform.width / 2,
      platform.y - 20,
      screenX + platform.width,
      platform.y + platform.height,
    );
    mainPath.lineTo(
      screenX + platform.width,
      platform.y + platform.height + 10,
    );
    mainPath.quadraticBezierTo(
      screenX + platform.width / 2,
      platform.y - 10,
      screenX,
      platform.y + platform.height + 10,
    );
    mainPath.close();

    canvas.drawPath(mainPath, platformPaint);
  }

  void _drawNormalPlatform(Canvas canvas, double screenX, Platform platform) {
    // Platform glow effect
    Paint glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    RRect glowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        screenX - 5,
        platform.y - 5,
        platform.width + 10,
        platform.height + 10,
      ),
      Radius.circular(15),
    );
    canvas.drawRRect(glowRect, glowPaint);

    // Main platform
    Paint platformPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(screenX, platform.y, platform.width, platform.height),
        Radius.circular(10),
      ),
      platformPaint,
    );
  }

  void _drawPlayer(Canvas canvas, Size size) {
    canvas.save();

    double screenPlayerX = playerX - cameraOffset;
    canvas.translate(screenPlayerX, playerY);
    canvas.rotate(rotation * math.pi / 180);

    _drawPlayerGlow(canvas);
    _drawPlayerBody(canvas);
    _drawWheels(canvas);
    _drawBoostEffect(canvas);

    canvas.restore();
  }

  void _drawPlayerGlow(Canvas canvas) {
    Paint playerGlowPaint = Paint()
      ..color = (isPressed ? Colors.red : Colors.cyan).withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-18, -10, 36, 20),
        Radius.circular(10),
      ),
      playerGlowPaint,
    );
  }

  void _drawPlayerBody(Canvas canvas) {
    Paint bikePaint = Paint()
      ..color = isPressed ? Colors.red : Colors.cyan
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-15, -8, 30, 16),
        Radius.circular(8),
      ),
      bikePaint,
    );
  }

  void _drawWheels(Canvas canvas) {
    Paint wheelPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(10, 10), 5, wheelPaint);
    canvas.drawCircle(Offset(-10, 10), 5, wheelPaint);

    Paint rimPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(10, 10), 2.5, rimPaint);
    canvas.drawCircle(Offset(-10, 10), 2.5, rimPaint);
  }

  void _drawBoostEffect(Canvas canvas) {
    if (isPressed) {
      for (int i = 0; i < 3; i++) {
        Paint boostPaint = Paint()
          ..color = Colors.orange.withOpacity(0.8 - i * 0.2)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(-22 - i * 8, 0 + math.sin(i * 0.8) * 4),
          5.0 - i * 0.8,
          boostPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
