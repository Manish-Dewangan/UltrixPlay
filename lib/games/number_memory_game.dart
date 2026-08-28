import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';


class NumberMemoryGame extends StatefulWidget {
  const NumberMemoryGame({super.key});

  @override
  State<NumberMemoryGame> createState() => _GameScreenState();
}

class _GameScreenState extends State<NumberMemoryGame> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playCorrectSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/memorize_next.mp3'));
  }

  Future<void> _playWinSound() async {
    await _audioPlayer.play(AssetSource('sounds/memorize_win.mp3'));
  }

  Future<void> _playLoseSound() async {
    await _audioPlayer.play(AssetSource('sounds/memorize_lose.wav'));
  }

  // Game states
  List<int> numbers = [];
  List<bool> revealed = [];
  List<Color> colors = [];
  List<int> sequence = [];
  int currentIndex = 0;
  int score = 0;
  Stopwatch stopwatch = Stopwatch();
  Timer? countdownTimer;
  Timer? gameTimer;
  int countdown = 3;
  bool isMemorizing = true;
  bool gameStarted = false;
  bool gameOver = false;
  bool gameWon = false;

  // Difficulty levels - keep same grid size, only change memorization time
  Difficulty _currentDifficulty = Difficulty.easy;
  int _memorizationTime = 5; // Easy difficulty

  // Predefined vibrant colors
  final List<Color> availableColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.deepPurpleAccent,
    Colors.lightBlueAccent,
    Colors.lightGreenAccent,
    Colors.amberAccent,
    Colors.deepOrangeAccent,
    Colors.indigoAccent,
    Colors.cyanAccent,
    Colors.limeAccent,
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    setState(() {
      numbers = List.generate(8, (index) => index + 1)..shuffle();
      numbers = [...numbers, ...numbers]..shuffle();

      colors = List.generate(16, (index) {
        int num = numbers[index];
        return availableColors[num - 1];
      });

      revealed = List.filled(16, true);
      sequence = List.generate(8, (index) => index + 1);
      currentIndex = 0;
      score = 0;
      countdown = 3;
      isMemorizing = true;
      gameStarted = false;
      gameOver = false;
      gameWon = false;
      stopwatch.reset();
    });
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });

      if (countdown == 0) {
        timer.cancel();
        _startMemorizationPhase();
      }
    });
  }

  void _startMemorizationPhase() {
    setState(() {
      isMemorizing = true;
      gameStarted = true;
    });

    Future.delayed(Duration(seconds: _memorizationTime), () {
      if (mounted) {
        setState(() {
          revealed = List.filled(16, false);
          isMemorizing = false;
          stopwatch.start();
          _startGameTimer();
        });
      }
    });
  }

  void _startGameTimer() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onNumberClicked(int index) {
    if (gameOver || isMemorizing || !gameStarted) return;

    setState(() {
      revealed[index] = true;
    });

    // Check if correct number in sequence
    if (numbers[index] == sequence[currentIndex]) {
      _playCorrectSound();
      currentIndex++;
      score++;

      // Check if game is won
      if (currentIndex == sequence.length) {
        _gameWon();
      }
    } else {
      _gameOver();
    }
  }

  void _gameOver() {
    _playLoseSound();
    setState(() {
      gameOver = true;
      gameWon = false;
      stopwatch.stop();
    });
    gameTimer?.cancel();

    _showGameOverDialog();
  }

  void _gameWon() {
    _playWinSound();
    setState(() {
      gameWon = true;
      gameOver = false;
      stopwatch.stop();
    });
    gameTimer?.cancel();

    _showWinDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Game Over!',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'Wrong number selected!',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Time: ${_formatTime(stopwatch.elapsed)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              'Score: $score/8',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            child: const Text(
              'PLAY AGAIN',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Victory!',
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              color: Colors.greenAccent,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              'Congratulations!',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Time: ${_formatTime(stopwatch.elapsed)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Text(
              'Score: $score/8 - Perfect!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            child: const Text(
              'PLAY AGAIN',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeDifficulty(Difficulty difficulty) {
    setState(() {
      _currentDifficulty = difficulty;
      switch (difficulty) {
        case Difficulty.easy:
          _memorizationTime = 5;
          break;
        case Difficulty.medium:
          _memorizationTime = 3;
          break;
        case Difficulty.hard:
          _memorizationTime = 2;
          break;
      }
      _initializeGame();
    });
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitMillis = twoDigits(duration.inMilliseconds.remainder(1000) ~/ 10);
    return '$twoDigitMinutes:$twoDigitSeconds.$twoDigitMillis';
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    gameTimer?.cancel();
    stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: Text(
          'NUMBER MEMORY GAME',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView( // Make the entire body scrollable
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Difficulty Selector
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'DIFFICULTY:',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DifficultyButton(
                          label: 'EASY',
                          time: 5,
                          isSelected: _currentDifficulty == Difficulty.easy,
                          onTap: () => _changeDifficulty(Difficulty.easy),
                          color: Colors.greenAccent,
                        ),
                        _DifficultyButton(
                          label: 'MEDIUM',
                          time: 3,
                          isSelected: _currentDifficulty == Difficulty.medium,
                          onTap: () => _changeDifficulty(Difficulty.medium),
                          color: Colors.orangeAccent,
                        ),
                        _DifficultyButton(
                          label: 'HARD',
                          time: 2,
                          isSelected: _currentDifficulty == Difficulty.hard,
                          onTap: () => _changeDifficulty(Difficulty.hard),
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Game Stats
              _buildGameStats(),

              const SizedBox(height: 20),

              // Game Status
              _buildGameStatus(),

              const SizedBox(height: 30),

              // Grid
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.width, // Square grid
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    return _buildGridItem(index);
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Current Sequence
              _buildSequenceDisplay(),

              const SizedBox(height: 20),

              // Controls
              _buildControlButtons(),

              const SizedBox(height: 20),

              // Instructions - Now scrollable if needed
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'HOW TO PLAY',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 15,
                      runSpacing: 10,
                      children: [
                        _buildInstruction('1️⃣', 'Memorize numbers & colors for $_memorizationTime seconds'),
                        _buildInstruction('2️⃣', 'Find numbers 1-8 in order'),
                        _buildInstruction('3️⃣', 'Each number has a unique color'),
                        _buildInstruction('4️⃣', 'Click numbers in sequence'),
                        _buildInstruction('5️⃣', 'Wrong click = Game Over'),
                        _buildInstruction('6️⃣', 'Harder levels give less time'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                'SCORE',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                '$score/8',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'TIME',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                _formatTime(stopwatch.elapsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'LEVEL',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                _currentDifficulty.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: _getDifficultyColor(),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatus() {
    if (!gameStarted) {
      return Column(
        children: [
          Text(
            'READY IN',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$countdown',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap NEW GAME to start',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (isMemorizing) {
      return Column(
        children: [
          const Text(
            'MEMORIZE',
            style: TextStyle(
              color: Colors.yellowAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Numbers & Colors',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.yellowAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.yellowAccent),
            ),
            child: Text(
              '$_memorizationTime seconds',
              style: const TextStyle(
                color: Colors.yellowAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'FIND: ${sequence[currentIndex]}',
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (currentIndex + 1) / sequence.length,
          backgroundColor: Colors.grey[800],
          color: Colors.greenAccent,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 5),
        Text(
          '${currentIndex + 1} of ${sequence.length}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(int index) {
    return GestureDetector(
      onTap: () => _onNumberClicked(index),
      child: Container(
        decoration: BoxDecoration(
          color: revealed[index] ? colors[index] : Colors.grey[800],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: revealed[index]
                  ? colors[index].withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: revealed[index] ? Colors.white : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Center(
          child: revealed[index]
              ? Text(
            '${numbers[index]}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          )
              : gameOver
              ? Text(
            '${numbers[index]}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildSequenceDisplay() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Text(
            'SEQUENCE TO FIND',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(sequence.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: index < currentIndex
                        ? Colors.greenAccent
                        : index == currentIndex && gameStarted && !isMemorizing
                        ? Colors.blueAccent
                        : Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${sequence[index]}',
                      style: TextStyle(
                        color: index < currentIndex ? Colors.black : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _initializeGame();
            _startCountdown();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
          ),
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text(
            'NEW GAME',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ElevatedButton.icon(
          onPressed: _initializeGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: const Icon(Icons.restart_alt, color: Colors.white),
          label: const Text(
            'RESTART',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor() {
    switch (_currentDifficulty) {
      case Difficulty.easy:
        return Colors.greenAccent;
      case Difficulty.medium:
        return Colors.orangeAccent;
      case Difficulty.hard:
        return Colors.redAccent;
    }
  }
}

// Difficulty enum
enum Difficulty { easy, medium, hard }

// Difficulty Button Widget
class _DifficultyButton extends StatelessWidget {
  final String label;
  final int time;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _DifficultyButton({
    required this.label,
    required this.time,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[700]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 12,
              ),
            ),
            Text(
              '$time sec',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.black87 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}