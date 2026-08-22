import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';


class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<String> emojis = ['🍇', '🍉', '🍑', '🍓', '🥝', '🍍'];
  late List<String> gameBoard;
  late List<bool> flipped;
  late List<bool> matched;
  int? firstIndex;
  int moves = 0;
  bool _isBusy = false;
  late Stopwatch _stopwatch;
  Timer? _timer;
  String _elapsedTime = '00:00';
  bool _winDialogShown = false;
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initGame();
  }

  @override
  void dispose() {
    _stopTimer();
    _flipController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initGame() {
    final List<String> pairs = [...emojis, ...emojis];
    pairs.shuffle(Random());
    gameBoard = pairs;
    flipped = List.filled(pairs.length, false);
    matched = List.filled(pairs.length, false);
    firstIndex = null;
    moves = 0;
    _stopTimer();
    _stopwatch.reset();
    _elapsedTime = '00:00';
    _winDialogShown = false;
  }

  void _startTimer() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedTime = _formatTime(_stopwatch.elapsed);
        });
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _onCardTap(int index) async {
    if (_isBusy || flipped[index] || matched[index] || firstIndex == index) return;

    _isBusy = true;
    await _audioPlayer.play(AssetSource('sounds/card_flip.mp3'));

    if (!_stopwatch.isRunning) _startTimer();

    setState(() {
      flipped[index] = true;
    });

    if (firstIndex == null) {
      firstIndex = index;
      _isBusy = false;
      return;
    }

    final secondIndex = index;
    moves++;

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      if (gameBoard[firstIndex!] == gameBoard[secondIndex]) {
        matched[firstIndex!] = true;
        matched[secondIndex] = true;
      } else {
        flipped[firstIndex!] = false;
        flipped[secondIndex] = false;
      }
      firstIndex = null;
    });

    _isBusy = false;

    if (matched.every((m) => m) && !_winDialogShown) {
      _stopTimer();
      _winDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _displayWinDialog();
      });
    }
  }

  void _restartGame() {
    setState(_initGame);
  }

  Widget _buildCard(int index) {
    final bool show = flipped[index] || matched[index];

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Container(
          key: ValueKey(show),
          decoration: BoxDecoration(
            color: show ? Colors.white : const Color(0xFF1D2766),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: show
                  ? Text(
                gameBoard[index],
                key: ValueKey(gameBoard[index]),
                style: const TextStyle(fontSize: 36),
              )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  void _displayWinDialog() {
    _audioPlayer.play(AssetSource('sounds/card_match_win.mp3'));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0C114F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white30, width: 2),
        ),
        title: const Text(
          'You Win!',
          style: TextStyle(color: Colors.white, fontSize: 28),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: Colors.yellow, size: 60),
            const SizedBox(height: 20),
            Text(
              'Moves: $moves',
              style: const TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: $_elapsedTime',
              style: const TextStyle(color: Colors.white70, fontSize: 20),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Play Again',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A47),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C114F),
        title: const Text('Memory Match', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0C114F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('⏱️ Time', _elapsedTime),
                  _buildStatCard('🔄 Moves', '$moves'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: gameBoard.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) => _buildCard(index),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Restart Game',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
