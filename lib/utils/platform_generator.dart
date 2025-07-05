import 'dart:math' as math;
import '../models/game_models.dart';
import '../constants/game_constants.dart';

class PlatformGenerator {
  static final math.Random _random = math.Random();

  static List<Platform> generateInitialPlatforms() {
    List<Platform> platforms = [];

    // Starting platform - wider and flat for easier start
    platforms.add(
      Platform(
        x: 0,
        y: 200,
        width: 600,
        height: 30,
        type: PlatformType.flat,
        curveDirection: CurveDirection.none,
      ),
    );

    double currentX = 600;
    double currentY = 400;

    for (int i = 0; i < 50; i++) {
      Platform previousPlatform = platforms.last;
      Platform nextPlatform = _generatePlatform(
        currentX,
        currentY,
        i,
        previousPlatform: previousPlatform,
      );
      platforms.add(nextPlatform);

      currentX = nextPlatform.x + nextPlatform.width;
      currentY = nextPlatform.y;
    }

    return platforms;
  }

  static Platform generateNextPlatform(Platform lastPlatform) {
    // Use a progressive difficulty counter (can be passed as parameter later)
    int difficultyLevel = (lastPlatform.x / 1000).floor();
    return _generatePlatform(
      lastPlatform.x + lastPlatform.width,
      lastPlatform.y,
      difficultyLevel,
      previousPlatform: lastPlatform,
    );
  }

  static Platform _generatePlatform(
    double startX,
    double currentY,
    int difficultyLevel, {
    Platform? previousPlatform,
  }) {
    // Progressive difficulty scaling
    double difficultyMultiplier = 1.0 + (difficultyLevel * 0.1);

    // Calculate gap distance with difficulty scaling
    double baseGapDistance =
        GameConstants.minGapDistance * difficultyMultiplier;
    double maxGapDistance = GameConstants.maxGapDistance * difficultyMultiplier;
    double gapDistance =
        baseGapDistance +
        _random.nextDouble() * (maxGapDistance - baseGapDistance);

    // Choose platform type based on difficulty and randomness
    PlatformType type = _choosePlatformType(difficultyLevel);
    CurveDirection curveDirection = _chooseCurveDirection(type);

    // Calculate height change with special logic for flat platforms
    double maxHeightChange =
        GameConstants.maxHeightChange * difficultyMultiplier;
    double heightChange;

    // If previous platform was flat, ensure next platform is reachable
    if (previousPlatform != null &&
        previousPlatform.type == PlatformType.flat) {
      // For flat platforms, bias towards platforms that are below or at same level
      // This prevents impossible jumps after flat platforms
      double maxJumpHeight = 150.0; // Maximum height a player can jump
      double safeHeightChange = math.min(maxHeightChange, maxJumpHeight * 0.6);

      // Bias towards downward or same level (70% chance)
      if (_random.nextDouble() < 0.7) {
        // Go down or stay same level
        heightChange = -_random.nextDouble() * safeHeightChange;
      } else {
        // Go up but not too much
        heightChange = _random.nextDouble() * (safeHeightChange * 0.5);
      }
    } else {
      // Normal height change for non-flat platforms
      heightChange = (_random.nextDouble() - 0.5) * maxHeightChange;
      // Apply some smoothing to prevent drastic height changes
      heightChange *= 0.7;
    }

    double nextX = startX + gapDistance;
    double nextY = currentY + heightChange;

    // Constrain Y position
    nextY = math.max(
      GameConstants.minPlatformY,
      math.min(GameConstants.maxPlatformY, nextY),
    );

    // Vary platform width based on difficulty and gap distance
    double baseWidth = GameConstants.minPlatformWidth;
    double maxWidth = GameConstants.maxPlatformWidth;

    // Smaller platforms for larger gaps (more challenging)
    if (gapDistance > GameConstants.maxGapDistance * 0.7) {
      maxWidth *= 0.8;
    }

    // Make platforms wider after flat platforms to help with landing
    if (previousPlatform != null &&
        previousPlatform.type == PlatformType.flat) {
      baseWidth *= 1.2;
      maxWidth *= 1.1;
    }

    double width = baseWidth + _random.nextDouble() * (maxWidth - baseWidth);

    // Vary height based on type
    double height = _getPlatformHeight(type);

    return Platform(
      x: nextX,
      y: nextY,
      width: width,
      height: height,
      type: type,
      curveDirection: curveDirection,
    );
  }

  static PlatformType _choosePlatformType(int difficultyLevel) {
    // Early game: mostly flat platforms
    if (difficultyLevel < 2) {
      return _random.nextDouble() < 0.8
          ? PlatformType.flat
          : PlatformType.curved;
    }

    // Mid game: introduce more variety
    if (difficultyLevel < 5) {
      double rand = _random.nextDouble();
      if (rand < 0.5) return PlatformType.flat;
      if (rand < 0.8) return PlatformType.curved;
      return PlatformType.moving; // Introduce moving platforms
    }

    // Late game: all types with more challenging ones
    double rand = _random.nextDouble();
    if (rand < 0.3) return PlatformType.flat;
    if (rand < 0.6) return PlatformType.curved;
    if (rand < 0.8) return PlatformType.moving;
    return PlatformType.breakable; // Introduce breakable platforms
  }

  static CurveDirection _chooseCurveDirection(PlatformType type) {
    if (type != PlatformType.curved) {
      return CurveDirection.none;
    }

    // Favor upward curves for better gameplay flow
    double rand = _random.nextDouble();
    if (rand < 0.6) return CurveDirection.up;
    if (rand < 0.8) return CurveDirection.down;
    return CurveDirection.wave;
  }

  static double _getPlatformHeight(PlatformType type) {
    switch (type) {
      case PlatformType.flat:
        return 25.0;
      case PlatformType.curved:
        return 20.0;
      case PlatformType.moving:
        return 30.0;
      case PlatformType.breakable:
        return 20.0;
      default:
        return 25.0;
    }
  }
}
