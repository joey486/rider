import 'dart:math' as math;
import '../models/game_models.dart';
import '../constants/game_constants.dart';

class PlatformGenerator {
  static List<Platform> generateInitialPlatforms() {
    List<Platform> platforms = [];

    // Starting platform - make it bigger for easier start
    platforms.add(
      Platform(
        x: 0,
        y: 400,
        width: 400,
        height: GameConstants.platformHeight,
        type: PlatformType.normal,
      ),
    );

    // Generate initial platforms with better spacing
    double currentX = 400;
    double currentY = 400;

    for (int i = 0; i < 50; i++) {
      double gapDistance =
          GameConstants.minGapDistance +
          math.Random().nextDouble() *
              (GameConstants.maxGapDistance - GameConstants.minGapDistance);
      double heightChange =
          (math.Random().nextDouble() - 0.5) * GameConstants.maxHeightChange;

      currentX += gapDistance;
      currentY += heightChange;
      currentY = math.max(
        GameConstants.minPlatformY,
        math.min(GameConstants.maxPlatformY, currentY),
      );

      double width =
          GameConstants.minPlatformWidth +
          math.Random().nextDouble() *
              (GameConstants.maxPlatformWidth - GameConstants.minPlatformWidth);

      PlatformType type = PlatformType.normal;
      if (math.Random().nextDouble() > 0.8) {
        type = PlatformType.curved;
      }

      platforms.add(
        Platform(
          x: currentX,
          y: currentY,
          width: width,
          height: GameConstants.platformHeight,
          type: type,
        ),
      );

      currentX += width;
    }

    return platforms;
  }

  static Platform generateNextPlatform(Platform lastPlatform) {
    double gapDistance =
        GameConstants.minGapDistance +
        math.Random().nextDouble() *
            (GameConstants.maxGapDistance - GameConstants.minGapDistance);
    double heightChange =
        (math.Random().nextDouble() - 0.5) * GameConstants.maxHeightChange;

    double nextX = lastPlatform.x + lastPlatform.width + gapDistance;
    double nextY = lastPlatform.y + heightChange;
    nextY = math.max(
      GameConstants.minPlatformY,
      math.min(GameConstants.maxPlatformY, nextY),
    );

    double width =
        GameConstants.minPlatformWidth +
        math.Random().nextDouble() *
            (GameConstants.maxPlatformWidth - GameConstants.minPlatformWidth);

    PlatformType type = PlatformType.normal;
    if (math.Random().nextDouble() > 0.8) {
      type = PlatformType.curved;
    }

    return Platform(
      x: nextX,
      y: nextY,
      width: width,
      height: GameConstants.platformHeight,
      type: type,
    );
  }
}
