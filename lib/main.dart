import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

void main() {
  runApp(RiderGame());
}

class RiderGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rider Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Timer _gameTimer;

  // Game state
  bool _isGameRunning = false;
  bool _isGameOver = false;
  int _score = 0;
  double _baseSpeed = 3.0;

  // Player (motorcycle) properties
  double _playerX = 100.0;
  double _playerY = 300.0;
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  double _rotation = 0.0;
  bool _isOnGround = false;
  bool _isPressed = false;

  // Physics constants
  final double _gravity = 0.5;
  final double _jumpPower = -12.0;
  final double _groundAcceleration = 0.3;
  final double _airAcceleration = 0.15;
  final double _maxSpeed = 6.0;
  final double _friction = 0.98;
  final double _airResistance = 0.995;

  // Platforms
  List<Platform> _platforms = [];
  double _cameraOffset = 0.0;

  // Screen dimensions
  double _screenWidth = 0;
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    _initializePlatforms();
  }

  @override
  void dispose() {
    if (_gameTimer != null) _gameTimer.cancel();
    super.dispose();
  }

  void _initializePlatforms() {
    _platforms.clear();

    // Starting platform - longer for easier start
    _platforms.add(Platform(x: 0, y: 400, width: 300, height: 30));

    // Generate initial platforms with better spacing
    double currentX = 300;
    double currentY = 400;

    for (int i = 0; i < 50; i++) {
      // More reasonable gaps and height differences
      double gapDistance =
          80 + math.Random().nextDouble() * 60; // 80-140 pixels gap
      double heightChange =
          (math.Random().nextDouble() - 0.5) * 80; // ±40 pixels height change

      currentX += gapDistance;
      currentY += heightChange;

      // Keep platforms within reasonable bounds
      currentY = math.max(150, math.min(500, currentY));

      double width = 100 + math.Random().nextDouble() * 80; // 100-180 width

      _platforms.add(
        Platform(x: currentX, y: currentY, width: width, height: 30),
      );

      currentX += width;
    }
  }

  void _generateNextPlatform() {
    if (_platforms.isEmpty) return;

    Platform lastPlatform = _platforms.last;
    double gapDistance = 80 + math.Random().nextDouble() * 60;
    double heightChange = (math.Random().nextDouble() - 0.5) * 80;

    double nextX = lastPlatform.x + lastPlatform.width + gapDistance;
    double nextY = lastPlatform.y + heightChange;

    // Keep platforms within bounds
    nextY = math.max(150, math.min(500, nextY));

    double width = 100 + math.Random().nextDouble() * 80;

    _platforms.add(Platform(x: nextX, y: nextY, width: width, height: 30));
  }

  void _startGame() {
    setState(() {
      _isGameRunning = true;
      _isGameOver = false;
      _score = 0;
      _playerX = 100.0;
      _playerY = 300.0;
      _velocityX = 0.0;
      _velocityY = 0.0;
      _rotation = 0.0;
      _cameraOffset = 0.0;
      _isOnGround = false;
      _isPressed = false;
    });

    _initializePlatforms();

    _gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void _updateGame() {
    if (!_isGameRunning || _isGameOver) return;

    // Update player physics
    _updatePlayerPhysics();

    // Update camera to follow player
    _cameraOffset = math.max(0, _playerX - _screenWidth * 0.25);

    // Check collisions
    _checkCollisions();

    // Generate new platforms
    _generatePlatformsIfNeeded();

    // Update score based on distance
    _score = (_playerX / 10).floor();

    // Check if player fell off screen
    if (_playerY > _screenHeight + 100) {
      _gameOver();
    }

    setState(() {});
  }

  void _updatePlayerPhysics() {
    // Apply gravity
    _velocityY += _gravity;

    // Handle acceleration based on input and ground contact
    if (_isPressed) {
      if (_isOnGround) {
        _velocityX += _groundAcceleration;
        // Jump when pressed and on ground
        if (_velocityY >= -1) {
          // Only jump if not already jumping
          _velocityY = _jumpPower;
          _isOnGround = false;
        }
      } else {
        _velocityX += _airAcceleration;
      }
    }

    // Apply friction/resistance
    if (_isOnGround) {
      _velocityX *= _friction;
      // Minimum speed when on ground
      _velocityX = math.max(_velocityX, _baseSpeed);
    } else {
      _velocityX *= _airResistance;
    }

    // Cap maximum speed
    _velocityX = math.min(_velocityX, _maxSpeed);

    // Update position
    _playerX += _velocityX;
    _playerY += _velocityY;

    // Update rotation based on velocity (more responsive)
    double targetRotation = math.atan2(_velocityY, _velocityX) * 180 / math.pi;
    targetRotation = math.max(-30, math.min(30, targetRotation));
    _rotation = _rotation * 0.8 + targetRotation * 0.2; // Smooth rotation
  }

  void _checkCollisions() {
    bool wasOnGround = _isOnGround;
    _isOnGround = false;

    // Player bounds (smaller for better gameplay)
    double playerLeft = _playerX - 12;
    double playerRight = _playerX + 12;
    double playerTop = _playerY - 8;
    double playerBottom = _playerY + 8;

    for (Platform platform in _platforms) {
      // Check if player is intersecting with platform
      if (playerRight > platform.x &&
          playerLeft < platform.x + platform.width &&
          playerBottom > platform.y &&
          playerTop < platform.y + platform.height) {
        // Landing on top of platform
        if (_velocityY > 0 && playerBottom - _velocityY <= platform.y + 5) {
          _playerY = platform.y - 8;
          _velocityY = 0;
          _isOnGround = true;
          break;
        }
        // Hit from side or bottom - bounce back
        else if (playerLeft < platform.x + platform.width &&
            playerRight > platform.x) {
          if (_velocityX > 0) {
            _velocityX *= -0.5;
            _playerX = platform.x - 12;
          }
        }
      }
    }
  }

  void _generatePlatformsIfNeeded() {
    // Generate new platforms as needed
    while (_platforms.isNotEmpty &&
        _platforms.last.x < _cameraOffset + _screenWidth * 2) {
      _generateNextPlatform();
    }

    // Remove old platforms to save memory
    _platforms.removeWhere(
      (platform) => platform.x + platform.width < _cameraOffset - 200,
    );
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      _isGameRunning = false;
    });
    _gameTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF87CEEB), // Sky blue background
      body: LayoutBuilder(
        builder: (context, constraints) {
          _screenWidth = constraints.maxWidth;
          _screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Game area
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isPressed = true;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _isPressed = false;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _isPressed = false;
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: GamePainter(
                      playerX: _playerX,
                      playerY: _playerY,
                      rotation: _rotation,
                      platforms: _platforms,
                      cameraOffset: _cameraOffset,
                      screenWidth: _screenWidth,
                      screenHeight: _screenHeight,
                      isPressed: _isPressed,
                      isOnGround: _isOnGround,
                    ),
                  ),
                ),
              ),

              // UI Overlay
              Positioned(
                top: 50,
                left: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Score: $_score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Start/Game Over screen
              if (!_isGameRunning) ...[
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isGameOver ? 'Game Over!' : 'RIDER',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(3, 3),
                                blurRadius: 6,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        if (_isGameOver) ...[
                          Text(
                            'Distance: $_score m',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 30),
                        ],
                        ElevatedButton(
                          onPressed: _startGame,
                          child: Text(
                            _isGameOver ? 'RETRY' : 'START',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Hold to accelerate and jump\nRelease to slow down',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class Platform {
  final double x;
  final double y;
  final double width;
  final double height;

  Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class GamePainter extends CustomPainter {
  final double playerX;
  final double playerY;
  final double rotation;
  final List<Platform> platforms;
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
    required this.cameraOffset,
    required this.screenWidth,
    required this.screenHeight,
    required this.isPressed,
    required this.isOnGround,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw sky gradient background
    Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF87CEEB), // Sky blue
          Color(0xFFE0F6FF), // Light blue
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Draw platforms
    for (Platform platform in platforms) {
      double screenX = platform.x - cameraOffset;
      if (screenX + platform.width > -50 && screenX < size.width + 50) {
        // Platform shadow
        Paint shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              screenX + 3,
              platform.y + 3,
              platform.width,
              platform.height,
            ),
            Radius.circular(8),
          ),
          shadowPaint,
        );

        // Main platform
        Paint platformPaint = Paint()
          ..color =
              Color(0xFF2F4F2F) // Dark green
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(screenX, platform.y, platform.width, platform.height),
            Radius.circular(8),
          ),
          platformPaint,
        );

        // Platform highlight
        Paint highlightPaint = Paint()
          ..color =
              Color(0xFF3CB371) // Medium sea green
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(screenX, platform.y, platform.width, 8),
            Radius.circular(8),
          ),
          highlightPaint,
        );
      }
    }

    // Draw player (motorcycle)
    canvas.save();

    double screenPlayerX = playerX - cameraOffset;
    canvas.translate(screenPlayerX, playerY);
    canvas.rotate(rotation * math.pi / 180);

    // Draw motorcycle shadow
    Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-10, -4, 20, 8),
        Radius.circular(4),
      ),
      shadowPaint,
    );

    // Main motorcycle body
    Paint bikePaint = Paint()
      ..color = isPressed
          ? Color(0xFFFF4500)
          : Color(0xFF1E90FF) // Orange when pressed, blue otherwise
      ..style = PaintingStyle.fill;

    // Main body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-12, -6, 24, 12),
        Radius.circular(6),
      ),
      bikePaint,
    );

    // Windshield
    Paint windshieldPaint = Paint()
      ..color =
          Color(0xFF00CED1) // Turquoise
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, -8, 6, 8), Radius.circular(3)),
      windshieldPaint,
    );

    // Wheels
    Paint wheelPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Wheel rims
    Paint rimPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Front wheel
    canvas.drawCircle(Offset(8, 8), 5, wheelPaint);
    canvas.drawCircle(Offset(8, 8), 3, rimPaint);

    // Back wheel
    canvas.drawCircle(Offset(-8, 8), 5, wheelPaint);
    canvas.drawCircle(Offset(-8, 8), 3, rimPaint);

    // Exhaust trail when accelerating
    if (isPressed && isOnGround) {
      for (int i = 0; i < 3; i++) {
        Paint exhaustPaint = Paint()
          ..color = Color(0xFFFF6347)
              .withOpacity(0.7 - i * 0.2) // Tomato color
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(-16 - i * 4, 2 + math.sin(i * 0.5) * 2),
          3.0 - i * 0.5,
          exhaustPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
