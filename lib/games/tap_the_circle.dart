import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class TapTheCircleGame extends StatefulWidget {
  const TapTheCircleGame({super.key});

  @override
  State<TapTheCircleGame> createState() => _TapTheCircleGameState();
}

class _TapTheCircleGameState extends State<TapTheCircleGame>
    with SingleTickerProviderStateMixin {
  //  Use AudioCache for instant playback
  final AudioCache _audioCache = AudioCache(prefix: 'sounds/');

  double circleX = 100;
  double circleY = 200;
  double circleRadius = 40;
  int score = 0;
  int lives = 3;
  double timeLimit = 2.0; // seconds
  Timer? countdown;
  bool gameOver = false;
  final Random random = Random();
  int highScore = 0;
  Color circleColor = Colors.redAccent;
  AnimationController? _animationController;
  double _scale = 1.0;
  double _opacity = 1.0;
  bool _isVisible = true;
  int level = 1;
  int _countdownValue = 0;
  Size? _screenSize;
  double? _appBarHeight;
  double? _statusBarHeight;
  double? _bottomPadding;
  double _bodyTop = 0;

  void initScreenMetrics() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    _screenSize = mediaQuery.size;
    _appBarHeight = AppBar().preferredSize.height;
    _statusBarHeight = mediaQuery.padding.top;
    _bottomPadding = mediaQuery.padding.bottom;
    _bodyTop = _appBarHeight! + _statusBarHeight!;
  }

  void spawnNewCircle() {
    if (gameOver || !mounted) return;
    if (_screenSize == null) initScreenMetrics();

    final double maxX = _screenSize!.width - circleRadius * 2;
    final double maxY = _screenSize!.height -
        circleRadius * 2 -
        _appBarHeight! -
        _statusBarHeight! -
        _bottomPadding! -
        20;

    setState(() {
      circleX = random.nextDouble() * maxX;
      circleY = random.nextDouble() * maxY;
      circleColor = Colors.primaries[random.nextInt(Colors.primaries.length)];
      _scale = 1.0;
      _opacity = 1.0;
      _isVisible = true;
      _countdownValue = (timeLimit * 10).toInt();
    });

    countdown?.cancel();
    _animationController?.reset();
    _animationController?.duration =
        Duration(milliseconds: (timeLimit * 1000).toInt());
    _animationController?.forward();

    countdown = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownValue > 0) {
        setState(() => _countdownValue--);
      } else {
        timer.cancel();
        missCircle();
      }
    });
  }

  void missCircle() {
    if (gameOver || !mounted) return;

    setState(() {
      lives--;
      _isVisible = false;
    });

    if (lives <= 0) {
      endGame();
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) spawnNewCircle();
      });
    }
  }

  void handleTapDown(TapDownDetails details) {
    if (gameOver || !_isVisible) return;

    final tapX = details.globalPosition.dx;
    final tapY = details.globalPosition.dy - _bodyTop;

    final dx = tapX - (circleX + circleRadius);
    final dy = tapY - (circleY + circleRadius);
    final distance = sqrt(dx * dx + dy * dy);

    if (distance <= circleRadius) {
      hitCircle();
    } else {
      missCircle();
    }
  }

  Future<void> hitCircle() async {
    if (!mounted) return;

    // Create a new player each tap for zero delay
    final player = AudioPlayer();
    player.play(AssetSource('sounds/circle_tap.mp3'));

    setState(() {
      score++;
      circleColor = Colors.white;
      if (score % 5 == 0) {
        level++;
        timeLimit = max(0.4, timeLimit * 0.85);
        circleRadius = max(20.0, circleRadius * 0.9);
      }
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        setState(() => circleColor =
        Colors.primaries[random.nextInt(Colors.primaries.length)]);
      }
    });

    spawnNewCircle();
  }

  void endGame() {
    countdown?.cancel();
    _animationController?.stop();

    if (mounted) {
      setState(() {
        gameOver = true;
        if (score > highScore) highScore = score;
      });
    }
  }

  void resetGame() {
    if (!mounted) return;

    setState(() {
      score = 0;
      lives = 3;
      gameOver = false;
      timeLimit = 2.0;
      circleRadius = 40.0;
      level = 1;
    });
    spawnNewCircle();
  }

  @override
  void initState() {
    super.initState();

    // ✅ Preload sound to remove delay
    _audioCache.load('circle_tap.mp3');

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (timeLimit * 1000).toInt()),
    )..addListener(() {
      if (!mounted) return;
      setState(() {
        _scale = 1.0 + 0.5 * _animationController!.value;
        _opacity = 1.0 - 0.8 * _animationController!.value;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initScreenMetrics();
      spawnNewCircle();
    });
  }

  @override
  void dispose() {
    countdown?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_screenSize != MediaQuery.of(context).size) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => initScreenMetrics());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060A47),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C114F),
        title: const Text('Tap the Circle'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow),
                const SizedBox(width: 4),
                Text('$highScore', style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: handleTapDown,
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: List.generate(3, (index) {
                  return Icon(
                    Icons.favorite,
                    color: index < lives ? Colors.red : Colors.grey[700],
                    size: 30,
                  );
                }),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Score: $score',
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level: $level',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.yellow[200],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isVisible)
              Positioned(
                left: circleX,
                top: circleY,
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 100),
                  child: Transform.scale(
                    scale: _scale,
                    child: Container(
                      width: circleRadius * 2,
                      height: circleRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor,
                        boxShadow: [
                          BoxShadow(
                            color: circleColor.withOpacity(0.8),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isVisible)
              Positioned(
                left: circleX + circleRadius - 15,
                top: circleY + circleRadius - 15,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${(_countdownValue / 10).toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (gameOver)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Game Over!',
                        style: TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'High Score: $highScore',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.yellow[300],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: resetGame,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Play Again',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
