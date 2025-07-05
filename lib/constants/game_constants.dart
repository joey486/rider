class GameConstants {
  // Physics constants
  static const double gravity = 0.4;
  static const double jumpPower = -10.0;
  static const double groundAcceleration = 0.4;
  static const double airAcceleration = 0.2;
  static const double maxSpeed = 8.0;
  static const double friction = 0.95;
  static const double airResistance = 0.998;
  static const double spinSpeed = 2.0;
  static const double rotationDamping = 0.92;

  // Game settings
  static const double baseSpeed = 2.0;
  static const int gameUpdateInterval = 16; // milliseconds
  static const int maxTrailLength = 40;

  // Platform generation
  static const double minGapDistance = 60.0;
  static const double maxGapDistance = 120.0;
  static const double maxHeightChange = 80.0;
  static const double minPlatformWidth = 120.0;
  static const double maxPlatformWidth = 200.0;
  static const double platformHeight = 30.0;
  static const double minPlatformY = 200.0;
  static const double maxPlatformY = 450.0;

  // Visual constants
  static const double playerWidth = 30.0;
  static const double playerHeight = 16.0;
  static const double wheelRadius = 5.0;
  static const double wheelRimRadius = 2.5;
}
