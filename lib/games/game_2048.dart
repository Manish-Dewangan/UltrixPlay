import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class Game2048 extends StatefulWidget {
  const Game2048({super.key});

  @override
  State<Game2048> createState() => _Game2048State();
}

enum Difficulty { easy, medium, hard }

class _Game2048State extends State<Game2048> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playSwipeSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/2048_swipe.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing swipe sound: $e');
      }
    }
  }

  Future<void> _playWinSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/2048_win.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing win sound: $e');
      }
    }
  }

  Future<void> _playLoseSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/memorize_lose.wav'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing lose sound: $e');
      }
    }
  }

  late List<List<int>> grid;
  int score = 0;
  int bestScore = 0;
  bool gameOver = false;
  bool gameWon = false;
  bool _dialogShown = false;
  bool _showInstructions = false;

  Difficulty _currentDifficulty = Difficulty.easy;
  int _winningTile = 2048;
  int _gridSize = 6;

  // Swipe detection variables
  double startX = 0;
  double startY = 0;
  double endX = 0;
  double endY = 0;

  // Color scheme for tiles
  final Map<int, Color> tileColors = {
    0: const Color(0xFFCDC1B4),
    2: const Color(0xFFEEE4DA),
    4: const Color(0xFFEDE0C8),
    8: const Color(0xFFF2B179),
    16: const Color(0xFFF59563),
    32: const Color(0xFFF67C5F),
    64: const Color(0xFFF65E3B),
    128: const Color(0xFFEDCF72),
    256: const Color(0xFFEDCC61),
    512: const Color(0xFFEDC850),
    1024: const Color(0xFFEDC53F),
    2048: const Color(0xFFEDC22E),
    4096: const Color(0xFF3C3A32),
    8192: const Color(0xFF3C3A32),
  };

  final Map<int, Color> textColors = {
    0: const Color(0xFFCDC1B4),
    2: const Color(0xFF776E65),
    4: const Color(0xFF776E65),
    8: Colors.white,
    16: Colors.white,
    32: Colors.white,
    64: Colors.white,
    128: Colors.white,
    256: Colors.white,
    512: Colors.white,
    1024: Colors.white,
    2048: Colors.white,
    4096: Colors.white,
    8192: Colors.white,
  };

  @override
  void initState() {
    super.initState();
    initGame();
  }

  void initGame() {
    grid = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
    score = 0;
    gameOver = false;
    gameWon = false;
    _dialogShown = false;
    addRandomTile();
    addRandomTile();
    setState(() {});
  }

  void addRandomTile() {
    final empty = <Point<int>>[];
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (grid[i][j] == 0) empty.add(Point(i, j));
      }
    }
    if (empty.isEmpty) return;

    final p = empty[Random().nextInt(empty.length)];
    grid[p.x][p.y] = Random().nextDouble() < 0.9 ? 2 : 4;
  }

  /// 🔥 Core merge logic (FIXED)
  List<int> _mergeLine(List<int> line) {
    final filtered = line.where((e) => e != 0).toList();
    final result = <int>[];

    int i = 0;
    while (i < filtered.length) {
      if (i + 1 < filtered.length && filtered[i] == filtered[i + 1]) {
        int merged = filtered[i] * 2;
        result.add(merged);
        score += merged;
        bestScore = max(bestScore, score);

        if (merged == _winningTile){
          gameWon = true;
          _playWinSound();
        }
        i += 2;
      } else {
        result.add(filtered[i]);
        i++;
      }
    }

    while (result.length < _gridSize) result.add(0);
    return result;
  }

  void moveLeft() {
    bool moved = false;
    for (int i = 0; i < _gridSize; i++) {
      final newRow = _mergeLine(grid[i]);
      if (!listEquals(grid[i], newRow)) moved = true;
      grid[i] = newRow;
    }
    _afterMove(moved);
  }

  void moveRight() {
    bool moved = false;
    for (int i = 0; i < _gridSize; i++) {
      final reversed = grid[i].reversed.toList();
      final merged = _mergeLine(reversed).reversed.toList();
      if (!listEquals(grid[i], merged)) moved = true;
      grid[i] = merged;
    }
    _afterMove(moved);
  }

  void moveUp() {
    bool moved = false;
    for (int c = 0; c < _gridSize; c++) {
      final col = [for (int r = 0; r < _gridSize; r++) grid[r][c]];
      final merged = _mergeLine(col);
      for (int r = 0; r < _gridSize; r++) {
        if (grid[r][c] != merged[r]) moved = true;
        grid[r][c] = merged[r];
      }
    }
    _afterMove(moved);
  }

  void moveDown() {
    bool moved = false;
    for (int c = 0; c < _gridSize; c++) {
      final col = [for (int r = 0; r < _gridSize; r++) grid[r][c]].reversed.toList();
      final merged = _mergeLine(col).reversed.toList();
      for (int r = 0; r < _gridSize; r++) {
        if (grid[r][c] != merged[r]) moved = true;
        grid[r][c] = merged[r];
      }
    }
    _afterMove(moved);
  }

  void _afterMove(bool moved) {
    if (!moved) return;
    _playSwipeSound();
    addRandomTile();
    checkGameOver();
    setState(() {});
  }

  void checkGameOver() {
    for (var row in grid) {
      if (row.contains(0)) return;
    }

    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (j < _gridSize - 1 && grid[i][j] == grid[i][j + 1]) return;
        if (i < _gridSize - 1 && grid[i][j] == grid[i + 1][j]) return;
      }
    }
    gameOver = true;
    _playLoseSound();
  }

  void showEndDialog() {
    if (_dialogShown) return;
    _dialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFF8F5F0),
        title: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gameWon ? const Color(0xFFEDC22E) : const Color(0xFFF59563),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gameWon ? Icons.celebration : Icons.games,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                gameWon ? "🎉 You Win!" : "Game Over",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Your Score",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                score.toString(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF776E65),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Best Score: $bestScore",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  initGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8F7A66),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  "New Game",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              if (gameWon)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    gameWon = false;
                    _dialogShown = false;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2B179),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Handle swipe gestures
  void _handleSwipe(DragUpdateDetails details) {
    endX = details.globalPosition.dx;
    endY = details.globalPosition.dy;
  }

  void _handleSwipeEnd(DragEndDetails details) {
    double dx = endX - startX;
    double dy = endY - startY;
    double swipeThreshold = 50.0;

    if (dx.abs() > dy.abs()) {
      if (dx.abs() > swipeThreshold) {
        if (dx > 0) {
          moveRight();
        } else {
          moveLeft();
        }
      }
    } else {
      if (dy.abs() > swipeThreshold) {
        if (dy > 0) {
          moveDown();
        } else {
          moveUp();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((gameOver || gameWon)) showEndDialog();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8F7A66),
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "2048",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: _handleSwipe,
            onPanEnd: _handleSwipeEnd,
            onPanDown: (details) {
              startX = details.globalPosition.dx;
              startY = details.globalPosition.dy;
              endX = startX;
              endY = startY;
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  // Top: Only 2 scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScoreCard(
                        title: "SCORE",
                        value: score.toString(),
                        color: const Color(0xFFBBADA0),
                      ),
                      _buildScoreCard(
                        title: "BEST",
                        value: bestScore.toString(),
                        color: const Color(0xFFBBADA0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Grid - Takes maximum available space
                  AspectRatio(
                    aspectRatio: 1, // 🔥 keeps grid square
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBADA0),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _gridSize * _gridSize,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemBuilder: (_, i) {
                          int r = i ~/ _gridSize;
                          int c = i % _gridSize;
                          int value = grid[r][c];

                          double fontSize = value < 100
                              ? 20
                              : value < 1000
                              ? 18
                              : value < 10000
                              ? 16
                              : 14;

                          return Container(
                            decoration: BoxDecoration(
                              color: tileColors[value] ?? const Color(0xFF3C3A32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                child: Text(
                                  value == 0 ? "" : value.toString(),
                                  key: ValueKey(value),
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: textColors[value] ?? Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // New Game and How to Play buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: initGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8F7A66),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            "NEW GAME",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showInstructions = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBBADA0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: const Text(
                            "HOW TO PLAY",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Grid info and swipe instructions
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD6CDC4), width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "6×6 GRID",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8F7A66),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.swipe, color: Color(0xFF8F7A66), size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              "SWIPE TO MOVE",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8F7A66),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_left, color: const Color(0xFF8F7A66).withOpacity(0.7), size: 18),
                            Icon(Icons.arrow_upward, color: const Color(0xFF8F7A66).withOpacity(0.7), size: 18),
                            Icon(Icons.arrow_downward, color: const Color(0xFF8F7A66).withOpacity(0.7), size: 18),
                            Icon(Icons.arrow_right, color: const Color(0xFF8F7A66).withOpacity(0.7), size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Small space at bottom
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),

          // Instructions Overlay
          if (_showInstructions)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "HOW TO PLAY",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8F7A66),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showInstructions = false;
                                });
                              },
                              icon: const Icon(Icons.close, size: 24),
                              color: const Color(0xFF8F7A66),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Join the numbers and get to the 2048 tile!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF776E65),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionStep(
                          number: "1",
                          title: "6×6 GRID",
                          description: "Now playing on a larger 6x6 grid with 36 tiles!",
                        ),
                        _buildInstructionStep(
                          number: "2",
                          title: "SWIPE TO MOVE",
                          description: "Swipe in any direction (up, down, left, right) to move all tiles.",
                        ),
                        _buildInstructionStep(
                          number: "3",
                          title: "MERGE TILES",
                          description: "When two tiles with the same number touch, they merge into one!",
                        ),
                        _buildInstructionStep(
                          number: "4",
                          title: "CREATE 2048",
                          description: "Keep merging tiles until you create the 2048 tile to win!",
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFD6CDC4)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F5F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info, color: Color(0xFF8F7A66)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Tip: More space means more strategy! Plan your moves carefully on the larger grid.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF776E65).withOpacity(0.9),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreCard({required String title, required String value, required Color color}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({required String number, required String title, required String description}) {
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF8F7A66),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF776E65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF776E65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
    );
    }
}