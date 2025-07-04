import 'dart:math' as math;
import '../models/game_models.dart';
import '../constants/game_constants.dart';

class GamePhysics {
  static void updatePlayerPhysics({
    required bool isPressed,
    required bool isOnGround,
    required double Function() getVelocityY,
    required void Function(double) setVelocityY,
    required double Function() getVelocityX,
    required void Function(double) setVelocityX,
    required double Function() getAngularVelocity,
    required void Function(double) setAngularVelocity,
    required double Function() getRotation,
    required void Function(double) setRotation,
    required double Function() getPlayerX,
    required void Function(double) setPlayerX,
    required double Function() getPlayerY,
    required void Function(double) setPlayerY,
    required double baseSpeed,
  }) {
    double velocityY = getVelocityY();
    double velocityX = getVelocityX();
    double angularVelocity = getAngularVelocity();
    double rotation = getRotation();

    // Apply gravity
    velocityY += GameConstants.gravity;

    if (isPressed) {
      if (isOnGround) {
        // Ground movement
        velocityX += GameConstants.groundAcceleration;
        // Jump only if not already jumping or falling too fast
        // if (velocityY > -2) {
        //   velocityY = GameConstants.jumpPower;
        // }
      } else {
        // Air movement (spin and accelerate)
        velocityX += GameConstants.airAcceleration;
        angularVelocity += GameConstants.spinSpeed;
      }
    }

    if (isOnGround) {
      // Friction and minimal forward speed
      velocityX *= GameConstants.friction;
      velocityX = math.max(velocityX, baseSpeed);

      // Auto-level bike gently on ground
      angularVelocity *= 0.7;
      double levelingForce = -rotation * 0.15;
      angularVelocity += levelingForce;
    } else {
      // Air resistance when in air
      velocityX *= GameConstants.airResistance;
    }

    // Update rotation
    rotation += angularVelocity;

    // Damp rotation speed
    angularVelocity *= GameConstants.rotationDamping;

    // Clamp angular velocity to prevent wild spinning
    angularVelocity = angularVelocity.clamp(-12.0, 12.0);

    // Clamp horizontal speed
    velocityX = velocityX.clamp(0.0, GameConstants.maxSpeed);

    // Update player position
    double playerX = getPlayerX() + velocityX;
    double playerY = getPlayerY() + velocityY;

    // Save updated values
    setVelocityY(velocityY);
    setVelocityX(velocityX);
    setAngularVelocity(angularVelocity);
    setRotation(rotation);
    setPlayerX(playerX);
    setPlayerY(playerY);
  }

  static bool checkCollisions({
    required double playerX,
    required double playerY,
    required double velocityY,
    required double rotation,
    required List<Platform> platforms,
    required Function() onLanding,
    required Function() onCrash,
  }) {
    double playerLeft = playerX - 15;
    double playerRight = playerX + 15;
    double playerTop = playerY - 10;
    double playerBottom = playerY + 10;

    for (Platform platform in platforms) {
      bool horizontallyOverlapping =
          playerRight > platform.x && playerLeft < platform.x + platform.width;
      bool verticallyOverlapping =
          playerBottom > platform.y && playerTop < platform.y + platform.height;

      if (horizontallyOverlapping && verticallyOverlapping) {
        // Landing check: only if player is falling and just about to land
        bool isLandingSurface =
            velocityY > 0 && (playerBottom - velocityY) <= (platform.y + 5);

        if (isLandingSurface) {
          // Normalize rotation to -180..180 degrees
          double normalizedRotation = rotation % 360;
          if (normalizedRotation > 180) normalizedRotation -= 360;
          if (normalizedRotation < -180) normalizedRotation += 360;

          // Crash only if nearly upside down (abs rotation > 150°)
          if (normalizedRotation.abs() > 150) {
            onCrash();
            return false;
          }

          // Otherwise, safe landing
          onLanding();
          return true;
        }

        // Side collision check (only if player is NOT falling fast and hits platform edges)
        bool hittingLeftEdge =
            playerLeft < platform.x + 5 && velocityY.abs() < 1;
        bool hittingRightEdge =
            playerRight > platform.x + platform.width - 5 &&
            velocityY.abs() < 1;

        if (hittingLeftEdge || hittingRightEdge) {
          onCrash();
          return false;
        }
      }
    }

    return false;
  }
}
