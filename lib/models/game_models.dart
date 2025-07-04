enum PlatformType { normal, curved }

enum CurveDirection { up, down }

class Platform {
  final double x;
  final double y;
  final double width;
  final double height;
  final PlatformType type;
  final CurveDirection? curveDirection;

  Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    this.curveDirection,
  });
}

class TrailPoint {
  final double x;
  final double y;
  double opacity;
  double size;

  TrailPoint({
    required this.x,
    required this.y,
    required this.opacity,
    required this.size,
  });
}

class ScoreEffect {
  final double x;
  double y;
  final int points;
  double opacity;
  double scale;

  ScoreEffect({
    required this.x,
    required this.y,
    required this.points,
    required this.opacity,
    required this.scale,
  });
}
