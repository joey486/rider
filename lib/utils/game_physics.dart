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
        // Jump only if we're clearly on ground and not already jumping
        if (velocityY > -2) {
          velocityY = GameConstants.jumpPower;
        }
      } else {
        // Air movement
        velocityX += GameConstants.airAcceleration;
        angularVelocity += GameConstants.spinSpeed;
      }
    }

    // Apply physics based on ground state
    if (isOnGround) {
      // Ground physics
      velocityX *= GameConstants.friction;
      velocityX = math.max(velocityX, baseSpeed); // Maintain minimum speed

      // Auto-level the bike when on ground
      angularVelocity *= 0.7; // Dampen rotation
      double levelingForce = -rotation * 0.15; // Stronger leveling
      angularVelocity += levelingForce;
    } else {
      // Air physics
      velocityX *= GameConstants.airResistance;
    }

    // Apply angular velocity to rotation
    rotation += angularVelocity;
    angularVelocity *= GameConstants.rotationDamping;

    // Limit rotation speed
    angularVelocity = math.max(-12, math.min(12, angularVelocity));

    // Limit horizontal speed
    velocityX = math.min(velocityX, GameConstants.maxSpeed);

    // Update position
    double playerX = getPlayerX() + velocityX;
    double playerY = getPlayerY() + velocityY;

    // Set updated values
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
    // Player collision box
    double playerLeft = playerX - 15;
    double playerRight = playerX + 15;
    double playerTop = playerY - 10;
    double playerBottom = playerY + 10;

    for (Platform platform in platforms) {
      // Check if player is overlapping with platform
      if (playerRight > platform.x &&
          playerLeft < platform.x + platform.width &&
          playerBottom > platform.y &&
          playerTop < platform.y + platform.height) {
        // Only check landing if falling down onto platform
        if (velocityY > 0 && playerBottom - velocityY <= platform.y + 5) {
          // Much more forgiving landing - only crash if completely upside down
          double normalizedRotation = rotation % 360;
          if (normalizedRotation > 180) normalizedRotation -= 360;
          if (normalizedRotation < -180) normalizedRotation += 360;

          // Only crash if nearly upside down (between 150-210 degrees)
          if (normalizedRotation.abs() > 150) {
            onCrash();
            return false;
          }

          // Successful landing
          onLanding();
          return true;
        }
        // Side collision - only if clearly hitting from side
        else if (velocityY < 2 &&
            (playerLeft < platform.x + 5 ||
                playerRight > platform.x + platform.width - 5)) {
          onCrash();
          return false;
        }
      }
    }

    return false;
  }
}
