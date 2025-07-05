// Import math for sin function
import 'dart:math' show sin;

enum PlatformType {
  flat, // Standard flat platform
  curved, // Curved platform (up/down/wave)
  moving, // Platform that moves horizontally or vertically
  breakable, // Platform that breaks after being stepped on
  bouncy, // Platform that gives extra jump height
  ice, // Slippery platform with reduced friction
}

enum CurveDirection {
  up, // Curves upward (like a hill)
  down, // Curves downward (like a valley)
  wave, // Wave pattern
  none, // No curve (flat)
}

enum MovementType {
  horizontal, // Moves left and right
  vertical, // Moves up and down
  circular, // Moves in a circle
  none, // Doesn't move
}

class Platform {
  final double x;
  final double y;
  final double width;
  final double height;
  final PlatformType type;
  final CurveDirection curveDirection;

  // Movement properties for moving platforms
  final MovementType movementType;
  final double movementSpeed;
  final double movementRange;

  // State for breakable platforms
  bool isBroken;
  double breakTimer;

  // Position offset for moving platforms
  double currentOffset;

  Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    this.curveDirection = CurveDirection.none,
    this.movementType = MovementType.none,
    this.movementSpeed = 0.0,
    this.movementRange = 0.0,
    this.isBroken = false,
    this.breakTimer = 0.0,
    this.currentOffset = 0.0,
  });

  // Get current position accounting for movement
  double get currentX =>
      x + (movementType == MovementType.horizontal ? currentOffset : 0);
  double get currentY =>
      y + (movementType == MovementType.vertical ? currentOffset : 0);

  // Check if platform is solid and can be landed on
  bool get isSolid =>
      !isBroken && type != PlatformType.breakable || breakTimer <= 0;

  // Get platform color based on type
  int get color {
    switch (type) {
      case PlatformType.flat:
        return 0xFF4CAF50; // Green
      case PlatformType.curved:
        return 0xFF2196F3; // Blue
      case PlatformType.moving:
        return 0xFFFF9800; // Orange
      case PlatformType.breakable:
        return isBroken ? 0xFF757575 : 0xFFF44336; // Red/Gray
      case PlatformType.bouncy:
        return 0xFF9C27B0; // Purple
      case PlatformType.ice:
        return 0xFF00BCD4; // Cyan
    }
  }

  // Get friction multiplier based on platform type
  double get frictionMultiplier {
    switch (type) {
      case PlatformType.ice:
        return 0.3; // Very slippery
      case PlatformType.bouncy:
        return 0.8; // Slightly less friction
      default:
        return 1.0; // Normal friction
    }
  }

  // Get bounce multiplier for jump height
  double get bounceMultiplier {
    switch (type) {
      case PlatformType.bouncy:
        return 1.5; // 50% higher jump
      default:
        return 1.0; // Normal jump
    }
  }

  // Update platform state (for animations, movement, etc.)
  void update(double deltaTime) {
    // Update movement
    if (movementType != MovementType.none) {
      currentOffset += movementSpeed * deltaTime;

      // Bounce within range
      if (currentOffset.abs() > movementRange) {
        currentOffset = currentOffset.sign * movementRange;
      }
    }

    // Update break timer
    if (isBroken && breakTimer > 0) {
      breakTimer -= deltaTime;
    }
  }

  // Trigger platform breaking
  void breakPlatform() {
    if (type == PlatformType.breakable && !isBroken) {
      isBroken = true;
      breakTimer = 2.0; // 2 seconds to respawn
    }
  }

  // Copy with new properties
  Platform copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    PlatformType? type,
    CurveDirection? curveDirection,
    MovementType? movementType,
    double? movementSpeed,
    double? movementRange,
    bool? isBroken,
    double? breakTimer,
    double? currentOffset,
  }) {
    return Platform(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      type: type ?? this.type,
      curveDirection: curveDirection ?? this.curveDirection,
      movementType: movementType ?? this.movementType,
      movementSpeed: movementSpeed ?? this.movementSpeed,
      movementRange: movementRange ?? this.movementRange,
      isBroken: isBroken ?? this.isBroken,
      breakTimer: breakTimer ?? this.breakTimer,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

class TrailPoint {
  final double x;
  final double y;
  double opacity;
  double size;
  final DateTime createdAt;

  TrailPoint({
    required this.x,
    required this.y,
    required this.opacity,
    required this.size,
  }) : createdAt = DateTime.now();

  // Update trail point over time
  void update(double deltaTime) {
    opacity -= deltaTime * 2.0; // Fade out over 0.5 seconds
    size *= 0.98; // Shrink slightly

    if (opacity < 0) opacity = 0;
    if (size < 0.1) size = 0.1;
  }

  // Check if trail point should be removed
  bool get shouldRemove => opacity <= 0 || size <= 0.1;

  // Get age in seconds
  double get age =>
      DateTime.now().difference(createdAt).inMilliseconds / 1000.0;
}

class ScoreEffect {
  final double x;
  double y;
  final int points;
  double opacity;
  double scale;
  final DateTime createdAt;
  double velocity;

  ScoreEffect({
    required this.x,
    required this.y,
    required this.points,
    required this.opacity,
    required this.scale,
    this.velocity = -50.0, // Move upward by default
  }) : createdAt = DateTime.now();

  // Update score effect animation
  void update(double deltaTime) {
    // Move upward
    y += velocity * deltaTime;

    // Fade out over time
    double age = DateTime.now().difference(createdAt).inMilliseconds / 1000.0;
    opacity = 1.0 - (age / 2.0); // Fade out over 2 seconds

    // Scale animation (grow then shrink)
    if (age < 0.2) {
      scale = 1.0 + (age / 0.2) * 0.5; // Grow to 1.5x in first 0.2s
    } else {
      scale =
          1.5 - ((age - 0.2) / 1.8) * 0.3; // Shrink to 1.2x over remaining time
    }

    // Clamp values
    if (opacity < 0) opacity = 0;
    if (scale < 0.5) scale = 0.5;
  }

  // Check if effect should be removed
  bool get shouldRemove => opacity <= 0;

  // Get effect color based on points
  int get color {
    if (points >= 100) return 0xFFFFD700; // Gold for high scores
    if (points >= 50) return 0xFFFF8C00; // Orange for medium scores
    return 0xFF32CD32; // Green for low scores
  }

  // Get age in seconds
  double get age =>
      DateTime.now().difference(createdAt).inMilliseconds / 1000.0;
}

// Additional game state classes
class GameState {
  final int score;
  final int lives;
  final int level;
  final bool isPaused;
  final bool isGameOver;
  final double distanceTraveled;

  const GameState({
    required this.score,
    required this.lives,
    required this.level,
    required this.isPaused,
    required this.isGameOver,
    required this.distanceTraveled,
  });

  GameState copyWith({
    int? score,
    int? lives,
    int? level,
    bool? isPaused,
    bool? isGameOver,
    double? distanceTraveled,
  }) {
    return GameState(
      score: score ?? this.score,
      lives: lives ?? this.lives,
      level: level ?? this.level,
      isPaused: isPaused ?? this.isPaused,
      isGameOver: isGameOver ?? this.isGameOver,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
    );
  }
}

class Collectible {
  final double x;
  final double y;
  final CollectibleType type;
  bool isCollected;
  double animationOffset;

  Collectible({
    required this.x,
    required this.y,
    required this.type,
    this.isCollected = false,
    this.animationOffset = 0.0,
  });

  void update(double deltaTime) {
    if (!isCollected) {
      animationOffset += deltaTime * 3.0; // Floating animation
    }
  }

  double get currentY => y + (isCollected ? 0 : (sin(animationOffset) * 5.0));

  int get points {
    switch (type) {
      case CollectibleType.coin:
        return 10;
      case CollectibleType.gem:
        return 50;
      case CollectibleType.star:
        return 100;
    }
  }

  int get color {
    switch (type) {
      case CollectibleType.coin:
        return 0xFFFFD700; // Gold
      case CollectibleType.gem:
        return 0xFF00FF00; // Green
      case CollectibleType.star:
        return 0xFFFFFFFF; // White
    }
  }
}

enum CollectibleType { coin, gem, star }
