import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class TicTacToe extends StatefulWidget {
  const TicTacToe({super.key});

  @override
  State<TicTacToe> createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToe>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  String winner = '';
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  List<int>? winningLine;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _colorAnimation = ColorTween(
      begin: Colors.blueAccent,
      end: Colors.amber,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void handleTap(int index) {
    if (board[index] == '' && winner == '') {
      setState(() {
        board[index] = currentPlayer;
        _controller.forward(from: 0);

        final winResult = checkWinner(currentPlayer);
        if (winResult != null) {
          winner = currentPlayer;
          winningLine = winResult;
          _showConfetti = true;
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) setState(() => _showConfetti = false);
          });
        } else if (!board.contains('')) {
          winner = 'Draw';
        } else {
          currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
        }
      });
    }
  }

  List<int>? checkWinner(String player) {
    const List<List<int>> winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var pattern in winPatterns) {
      if (board[pattern[0]] == player &&
          board[pattern[1]] == player &&
          board[pattern[2]] == player) {
        return pattern;
      }
    }
    return null;
  }

  void resetGame() {
    setState(() {
      board = List.filled(9, '');
      currentPlayer = 'X';
      winner = '';
      winningLine = null;
      _showConfetti = false;
    });
  }

  Widget buildCell(int index) {
    final bool isWinningCell = winningLine?.contains(index) ?? false;
    final bool isEmpty = board[index] == '';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => handleTap(index),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0C114F).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isWinningCell
                      ? Colors.amber.withOpacity(0.8)
                      : Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: isEmpty
                    ? Colors.white24
                    : board[index] == 'X'
                    ? Colors.redAccent
                    : Colors.lightBlue,
                width: 2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: board[index].isEmpty
                    ? const SizedBox()
                    : Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Text(
                          board[index],
                          key: ValueKey<String>(
                            board[index] + index.toString(),
                          ),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: board[index] == 'X'
                                ? Colors.redAccent
                                : Colors.lightBlue,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 15,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildPlayerIndicator(String player, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? (player == 'X'
                  ? Colors.redAccent.withOpacity(0.3)
                  : Colors.blueAccent.withOpacity(0.3))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: player == 'X' ? Colors.redAccent : Colors.blueAccent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            "Player $player",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: player == 'X' ? Colors.redAccent : Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isActive ? "Your Turn" : "",
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget buildResultPanel() {
    if (winner.isEmpty) return const SizedBox.shrink();

    Color resultColor;
    IconData resultIcon;
    String resultText;

    if (winner == 'Draw') {
      resultColor = Colors.amber;
      resultIcon = Icons.handshake;
      resultText = 'It\'s a Draw!';
    } else {
      resultColor = winner == 'X' ? Colors.redAccent : Colors.blueAccent;
      resultIcon = Icons.celebration;
      resultText = 'Player $winner Wins!';

      // Play sound without awaiting
      _audioPlayer.play(AssetSource('sounds/ttt_win.mp3'));
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(resultIcon, size: 60, color: resultColor),
        const SizedBox(height: 10),
        Text(
          resultText,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: resultColor,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 0)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A47),
      body: Stack(
        children: [
          // Background particles
          if (_showConfetti) ...[
            for (int i = 0; i < 50; i++)
              Positioned(
                left: Random().nextDouble() * MediaQuery.of(context).size.width,
                top: Random().nextDouble() * MediaQuery.of(context).size.height,
                child: ConfettiParticle(),
              ),
          ],

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // App bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C114F).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'TIC TAC TOE',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              color: Colors.blueAccent,
                              blurRadius: 10,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Player indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildPlayerIndicator(
                        'X',
                        currentPlayer == 'X' && winner.isEmpty,
                      ),
                      buildPlayerIndicator(
                        'O',
                        currentPlayer == 'O' && winner.isEmpty,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Result panel
                  buildResultPanel(),

                  // Game board
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0C114F).withOpacity(0.4),
                              const Color(0xFF1A1A2E).withOpacity(0.7),
                            ],
                          ),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: GridView.builder(
                          itemCount: 9,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                              ),
                          itemBuilder: (context, index) => buildCell(index),
                        ),
                      ),
                    ),
                  ),

                  // Restart button
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: resetGame,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'NEW GAME',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A4FCD),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      shadowColor: Colors.blueAccent.withOpacity(0.5),
                      elevation: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiParticle extends StatefulWidget {
  const ConfettiParticle({super.key});

  @override
  State<ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<ConfettiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final double size = Random().nextDouble() * 10 + 5;
  final List<Color> colors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: Random().nextInt(3) + 2),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value * 100),
          child: Transform.rotate(
            angle: _animation.value * 2 * pi,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colors[Random().nextInt(colors.length)],
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
