import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/game_models.dart';
import '../constants/game_constants.dart';
import '../painters/game_painter.dart';
import '../utils/platform_generator.dart';
import '../utils/game_physics.dart';

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

  // Player (motorcycle) properties
  double _playerX = 100.0;
  double _playerY = 300.0;
  double _velocityX = 0.0;
  double _velocityY = 0.0;
  double _rotation = 0.0;
  double _angularVelocity = 0.0;
  bool _isOnGround = false;
  bool _isPressed = false;
  List<TrailPoint> _trail = [];

  // Platforms
  List<Platform> _platforms = [];
  double _cameraOffset = 0.0;

  // Screen dimensions
  double _screenWidth = 0;
  double _screenHeight = 0;

  // Effects
  List<ScoreEffect> _scoreEffects = [];

  @override
  void initState() {
    super.initState();
    _initializePlatforms();
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  void _initializePlatforms() {
    _platforms = PlatformGenerator.generateInitialPlatforms();
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
      _angularVelocity = 0.0;
      _cameraOffset = 0.0;
      _isOnGround = false;
      _isPressed = false;
      _trail.clear();
      _scoreEffects.clear();
    });

    _initializePlatforms();

    _gameTimer = Timer.periodic(
      Duration(milliseconds: GameConstants.gameUpdateInterval),
      (timer) => _updateGame(),
    );
  }

  void _updateGame() {
    if (!_isGameRunning || _isGameOver) return;

    // Update player physics
    _updatePlayerPhysics();

    // Update trail
    _updateTrail();

    // Update camera to follow player
    _cameraOffset = math.max(0, _playerX - _screenWidth * 0.3);

    // Check collisions
    _checkCollisions();

    // Generate new platforms
    _generatePlatformsIfNeeded();

    // Update score based on distance
    int newScore = (_playerX / 20).floor();
    if (newScore > _score) {
      _score = newScore;
    }

    // Update score effects
    _updateScoreEffects();

    // Check if player fell off screen
    if (_playerY > _screenHeight + 100) {
      _gameOver();
    }

    setState(() {});
  }

  void _updatePlayerPhysics() {
    bool wasOnGround = _isOnGround;

    GamePhysics.updatePlayerPhysics(
      isPressed: _isPressed,
      isOnGround: _isOnGround,
      getVelocityY: () => _velocityY,
      setVelocityY: (value) => _velocityY = value,
      getVelocityX: () => _velocityX,
      setVelocityX: (value) => _velocityX = value,
      getAngularVelocity: () => _angularVelocity,
      setAngularVelocity: (value) => _angularVelocity = value,
      getRotation: () => _rotation,
      setRotation: (value) => _rotation = value,
      getPlayerX: () => _playerX,
      setPlayerX: (value) => _playerX = value,
      getPlayerY: () => _playerY,
      setPlayerY: (value) => _playerY = value,
      baseSpeed: GameConstants.baseSpeed,
    );

    // Reset ground state (will be set again in collision check)
    _isOnGround = false;
  }

  void _updateTrail() {
    // Add new trail point
    _trail.add(
      TrailPoint(x: _playerX, y: _playerY + 8, opacity: 1.0, size: 3.0),
    );

    // Update existing trail points
    for (int i = _trail.length - 1; i >= 0; i--) {
      _trail[i].opacity -= 0.03;
      _trail[i].size -= 0.08;
      if (_trail[i].opacity <= 0 || _trail[i].size <= 0) {
        _trail.removeAt(i);
      }
    }

    // Limit trail length
    if (_trail.length > GameConstants.maxTrailLength) {
      _trail.removeAt(0);
    }
  }

  void _checkCollisions() {
    bool wasOnGround = _isOnGround;

    bool landed = GamePhysics.checkCollisions(
      playerX: _playerX,
      playerY: _playerY,
      velocityY: _velocityY,
      rotation: _rotation,
      platforms: _platforms,
      onLanding: () {
        _playerY = _findLandingPlatform()!.y - 10;
        _velocityY = 0;
        _isOnGround = true;

        // Landing bonus
        if (!wasOnGround) {
          int landingBonus = 5;
          // Bonus for spinning
          if (_angularVelocity.abs() > 3) {
            landingBonus += 10;
          }
          _addScoreEffect(landingBonus);
        }
      },
      onCrash: () => _gameOver(),
    );
  }

  void _gameOver() {
    setState(() {
      _isGameOver = true;
      _isGameRunning = false;
    });
    _gameTimer.cancel();
  }

  Platform? _findLandingPlatform() {
    double playerLeft = _playerX - 15;
    double playerRight = _playerX + 15;
    double playerBottom = _playerY + 10;

    for (Platform platform in _platforms) {
      if (playerRight > platform.x &&
          playerLeft < platform.x + platform.width &&
          playerBottom > platform.y &&
          playerBottom < platform.y + platform.height + 10) {
        return platform;
      }
    }
    return null;
  }

  void _addScoreEffect(int points) {
    _scoreEffects.add(
      ScoreEffect(
        x: _playerX,
        y: _playerY - 25,
        points: points,
        opacity: 1.0,
        scale: 1.0,
      ),
    );
  }

  void _updateScoreEffects() {
    for (int i = _scoreEffects.length - 1; i >= 0; i--) {
      _scoreEffects[i].y -= 1.5;
      _scoreEffects[i].opacity -= 0.025;
      _scoreEffects[i].scale += 0.015;

      if (_scoreEffects[i].opacity <= 0) {
        _scoreEffects.removeAt(i);
      }
    }
  }

  void _generatePlatformsIfNeeded() {
    while (_platforms.isNotEmpty &&
        _platforms.last.x < _cameraOffset + _screenWidth * 2) {
      _generateNextPlatform();
    }

    _platforms.removeWhere(
      (platform) => platform.x + platform.width < _cameraOffset - 200,
    );
  }

  void _generateNextPlatform() {
    if (_platforms.isEmpty) return;

    Platform lastPlatform = _platforms.last;
    double gapDistance = 60 + math.Random().nextDouble() * 60;
    double heightChange = (math.Random().nextDouble() - 0.5) * 80;

    double nextX = lastPlatform.x + lastPlatform.width + gapDistance;
    double nextY = lastPlatform.y + heightChange;
    nextY = math.max(200, math.min(450, nextY));

    double width = 120 + math.Random().nextDouble() * 80;

    PlatformType type = PlatformType.normal;
    if (math.Random().nextDouble() > 0.8) {
      type = PlatformType.curved;
    }

    _platforms.add(
      Platform(x: nextX, y: nextY, width: width, height: 30, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a0a2e),
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
                      trail: _trail,
                      scoreEffects: _scoreEffects,
                      cameraOffset: _cameraOffset,
                      screenWidth: _screenWidth,
                      screenHeight: _screenHeight,
                      isPressed: _isPressed,
                      isOnGround: _isOnGround,
                    ),
                  ),
                ),
              ),

              // Score UI
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$_score',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 0),
                          blurRadius: 10,
                          color: Colors.cyan,
                        ),
                      ],
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
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Color(0xFF1a0a2e).withOpacity(0.9),
                        Color(0xFF16213e).withOpacity(0.95),
                        Colors.black.withOpacity(0.98),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isGameOver ? 'GAME OVER' : 'RIDER',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 0),
                                blurRadius: 20,
                                color: Colors.cyan,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        if (_isGameOver) ...[
                          Text(
                            'Score: $_score',
                            style: TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 40),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.cyan, Colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _startGame,
                            child: Text(
                              _isGameOver ? 'RETRY' : 'START',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.cyan.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Hold to accelerate and jump\nHold in air to spin and perform tricks\nLand upright to avoid crashing!\nAvoid landing upside down!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
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
