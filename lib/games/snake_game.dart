import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum Direction { up, down, left, right }

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with SingleTickerProviderStateMixin {
  static const int rowSize = 20;
  static const int totalSquares = rowSize * rowSize;
  static const Duration _initialSpeed = Duration(milliseconds: 200);
  static const int _maxLevel = 10;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<int> snake = [45, 65, 85];
  int food = Random().nextInt(totalSquares);
  Direction direction = Direction.down;
  Timer? gameTimer;
  bool gameOver = false;
  int score = 0;
  int highScore = 0;
  bool isPaused = false;
  int level = 1;
  late AnimationController _glowController;
  bool _showTutorial = true;
  bool _isFoodSpecial = false;
  int _specialFoodCounter = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      gameOver = false;
      isPaused = false;
      snake = [45, 65, 85];
      direction = Direction.down;
      food = generateNewFood();
      score = 0;
      level = 1;
      _isFoodSpecial = false;
      _specialFoodCounter = 0;
      _showTutorial = false;
    });
    startTimer();
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(_calculateSpeed(), (timer) {
      if (!isPaused) updateSnake();
    });
  }

  Duration _calculateSpeed() {
    int speedReduction = min(150, (level - 1) * 20);
    return Duration(milliseconds: _initialSpeed.inMilliseconds - speedReduction);
  }

  bool _isWallCollision(int head, Direction direction) {
    int row = head ~/ rowSize;
    int col = head % rowSize;

    switch (direction) {
      case Direction.left:
        return col == 0;
      case Direction.right:
        return col == rowSize - 1;
      case Direction.up:
        return row == 0;
      case Direction.down:
        return row == rowSize - 1;
    }
  }


  void updateSnake() {
    setState(() {
      int head = snake.last;

// WALL collision — FIXED
      if (_isWallCollision(head, direction)) {
        _endGame();
        return;
      }

      int next = _calculateNextPosition(head);

// SELF collision
      if (snake.contains(next)) {
        _endGame();
        return;
      }

      snake.add(next);

      if (next == food) {
        _handleFoodEaten();
      } else {
        snake.removeAt(0);
      }
    });
  }

  void _handleFoodEaten() {
    _audioPlayer.stop();
    _audioPlayer.play(AssetSource('sounds/snake_eat.mp3'));
    score += _isFoodSpecial ? 30 : 10;
    _specialFoodCounter++;

    if (_specialFoodCounter >= 3) {
      _specialFoodCounter = 0;
      level = min(_maxLevel, level + 1);
    }

    if (score > highScore) highScore = score;

    food = generateNewFood();
    _isFoodSpecial = Random().nextDouble() < 0.2;
    startTimer();
  }

  int _calculateNextPosition(int head) {
    switch (direction) {
      case Direction.up:
        return head - rowSize;
      case Direction.down:
        return head + rowSize;
      case Direction.left:
        return head - 1;
      case Direction.right:
        return head + 1;
    }
  }

  void _endGame() {
    gameTimer?.cancel();
    _audioPlayer.play(AssetSource('sounds/snake_game_over.mp3'));
    setState(() {
      gameOver = true;
    });
  }

  int generateNewFood() {
    final availableSpots = List.generate(totalSquares, (index) => index)
      ..removeWhere(snake.contains);
    if (availableSpots.isEmpty) return -1;
    return availableSpots[Random().nextInt(availableSpots.length)];
  }

  void changeDirection(Direction newDirection) {
    if (direction == Direction.up && newDirection == Direction.down) return;
    if (direction == Direction.down && newDirection == Direction.up) return;
    if (direction == Direction.left && newDirection == Direction.right) return;
    if (direction == Direction.right && newDirection == Direction.left) return;

    setState(() {
      direction = newDirection;
    });
  }

  void togglePause() {
    if (gameOver) return;
    setState(() {
      isPaused = !isPaused;
    });
  }


  Widget _buildScoreCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.blue[200],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSnakeSegment(int index, bool isHead) {
    return Positioned.fill(
      child: FractionallySizedBox(
        widthFactor: 1 / rowSize,
        heightFactor: 1 / rowSize,
        alignment: Alignment(
          ((index % rowSize) / (rowSize / 2)) - 1,
          ((index ~/ rowSize) / (rowSize / 2)) - 1,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isHead ? Colors.lightGreenAccent : Colors.green,
            borderRadius: BorderRadius.circular(isHead ? 8 : 4),
            boxShadow: isHead
                ? [
              BoxShadow(
                color: Colors.lightGreenAccent.withOpacity(_glowController.value * 0.5 + 0.5),
                blurRadius: 10,
                spreadRadius: _glowController.value * 2,
              ),
            ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFood(int index) {
    return Positioned.fill(
      child: FractionallySizedBox(
        widthFactor: 1 / rowSize,
        heightFactor: 1 / rowSize,
        alignment: Alignment(
          ((index % rowSize) / (rowSize / 2)) - 1,
          ((index ~/ rowSize) / (rowSize / 2)) - 1,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _isFoodSpecial ? Colors.deepPurpleAccent : Colors.redAccent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _isFoodSpecial
                    ? Colors.deepPurpleAccent.withOpacity(_glowController.value * 0.5 + 0.5)
                    : Colors.redAccent.withOpacity(0.5),
                blurRadius: _isFoodSpecial ? 15 : 8,
                spreadRadius: _isFoodSpecial ? _glowController.value * 3 : 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Center(
      child: _buildGameStatusCard(
        'GAME OVER',
        'Your Score: $score\nHigh Score: $highScore',
        'RESTART',
        startGame,
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Center(
      child: _buildGameStatusCard(
        'PAUSED',
        'Press play to resume',
        'RESUME',
        togglePause,
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    return Center(
      child: _buildGameStatusCard(
        'WELCOME TO SNAKE!',
        'Use the arrow buttons to move.\nEat the red food to grow.\nAvoid walls and your own tail.\nSpecial food (purple) gives more points!',
        'START GAME',
        startGame,
      ),
    );
  }

  Widget _buildGameStatusCard(
      String title, String message, String buttonText, VoidCallback onButtonPressed) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue[100],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              shadowColor: Colors.blueAccent.withOpacity(0.7),
              elevation: 10,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDirectionButton(Icons.keyboard_arrow_up, Direction.up),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionButton(Icons.keyboard_arrow_left, Direction.left),
              const SizedBox(width: 80), // Space between left/right arrows
              _buildDirectionButton(Icons.keyboard_arrow_right, Direction.right),
            ],
          ),
          _buildDirectionButton(Icons.keyboard_arrow_down, Direction.down),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(IconData icon, Direction newDirection) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FloatingActionButton(
        onPressed: () => changeDirection(newDirection),
        backgroundColor: Colors.blue[700],
        elevation: 8,
        shape: const CircleBorder(),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        title: const Text(
          'SNAKE GAME',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor:Color(0xFF283593),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.white,),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color(0xFF0A0F3A),
      body: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0F3A).withOpacity(0.8),
                  const Color(0xFF1A237E).withOpacity(0.5),
                ],
              ),
            ),
          ),

          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(),
            ),
          ),

          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A237E),
                      Color(0xFF283593),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreCard('SCORE', '$score'),
                    Column(
                      children: [

                        Text(
                          'Level $level',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[200],
                          ),
                        ),
                      ],
                    ),
                    _buildScoreCard('BEST', '$highScore'),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blueAccent.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A237E).withOpacity(0.7),
                            const Color(0xFF0A0F3A).withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // FIX: Removed GridView to prevent RenderFlow error
                          // Added CustomPaint for grid background
                          CustomPaint(
                            painter: _GameGridPainter(rowSize: rowSize), // Pass rowSize
                            size: Size.infinite,
                          ),

                          // Render snake segments
                          for (int i = 0; i < snake.length; i++)
                            _buildSnakeSegment(snake[i], i == snake.length - 1),

                          // Render food
                          if (food != -1) _buildFood(food),

                          if (gameOver) _buildGameOverOverlay(),
                          if (isPaused) _buildPausedOverlay(),
                          if (_showTutorial) _buildTutorialOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              _buildControlPanel(),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: togglePause,
        backgroundColor: Colors.blue[800],
        child: Icon(
          isPaused ? Icons.play_arrow : Icons.pause,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

// Move _GameGridPainter outside of _SnakeGameState
class _GameGridPainter extends CustomPainter {
  final int rowSize; // Add rowSize as a parameter

  _GameGridPainter({required this.rowSize}); // Constructor to receive rowSize

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / rowSize;
    final paint = Paint()
      ..color = Colors.blue[900]!.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (int i = 0; i <= rowSize; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i <= rowSize; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[900]!.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final gridSize = 20.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}