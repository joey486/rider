import 'dart:math' as math;
import '../models/game_models.dart';
import '../constants/game_constants.dart';

class PlatformGenerator {
  static List<Platform> generateInitialPlatforms() {
    List<Platform> platforms = [];

    // Starting platform - thin and curved upwards
    platforms.add(
      Platform(
        x: 0,
        y: 400,
        width: 400,
        height: 20, // thin height
        type: PlatformType.curved,
        curveDirection: CurveDirection.up,
      ),
    );

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

      platforms.add(
        Platform(
          x: currentX,
          y: currentY,
          width: width,
          height: 20,
          type: PlatformType.curved,
          curveDirection: CurveDirection.up,
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

    return Platform(
      x: nextX,
      y: nextY,
      width: width,
      height: 20,
      type: PlatformType.curved,
      curveDirection: CurveDirection.up,
    );
  }
}
