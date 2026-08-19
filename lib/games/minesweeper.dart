import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';


class MinesweeperGame extends StatefulWidget {
  const MinesweeperGame({super.key});

  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playTapSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/minesweeper_tap.wav'));
  }

  Future<void> _playWinSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/minesweeper_win.wav'));
  }

  Future<void> _playLoseSound() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/minesweeper_bomb.mp3'));
  }

  // Game configuration - Keep same grid size but increase mine count
  static const int easyRows = 8;
  static const int easyCols = 8;
  static const int easyMines = 10;

  static const int mediumRows = 9;
  static const int mediumCols = 9;
  static const int mediumMines = 25;

  static const int hardRows = 10;
  static const int hardCols = 10;
  static const int hardMines = 40;

  // Current game configuration
  int rows = easyRows;
  int cols = easyCols;
  int mineCount = easyMines;

  // Game state
  late List<List<Cell>> _board;
  GameStatus _gameStatus = GameStatus.playing;
  int _flagsPlaced = 0;
  int _cellsRevealed = 0;
  bool _firstClick = true;
  Stopwatch _stopwatch = Stopwatch();
  Difficulty _currentDifficulty = Difficulty.easy;

  // Colors for numbers
  final Map<int, Color> _numberColors = {
    1: Colors.blue,
    2: Colors.green,
    3: Colors.red,
    4: Colors.purple,
    5: Colors.orange,
    6: Colors.teal,
    7: Colors.black,
    8: Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _board = List.generate(rows, (i) =>
        List.generate(cols, (j) => Cell(row: i, col: j))
    );
    _gameStatus = GameStatus.playing;
    _flagsPlaced = 0;
    _cellsRevealed = 0;
    _firstClick = true;
    _stopwatch.reset();
  }

  void _placeMines(int firstRow, int firstCol) {
    Random random = Random();
    int minesPlaced = 0;

    while (minesPlaced < mineCount) {
      int row = random.nextInt(rows);
      int col = random.nextInt(cols);

      // Don't place a mine on the first clicked cell or adjacent cells
      if ((row == firstRow && col == firstCol) ||
          (row >= firstRow - 1 && row <= firstRow + 1 &&
              col >= firstCol - 1 && col <= firstCol + 1)) {
        continue;
      }

      if (!_board[row][col].isMine) {
        _board[row][col].isMine = true;
        minesPlaced++;

        // Update adjacent mine counts
        for (int r = max(0, row - 1); r <= min(rows - 1, row + 1); r++) {
          for (int c = max(0, col - 1); c <= min(cols - 1, col + 1); c++) {
            if (!(r == row && c == col)) {
              _board[r][c].adjacentMines++;
            }
          }
        }
      }
    }
  }

  void _revealCell(int row, int col) {
    if (_gameStatus != GameStatus.playing ||
        row < 0 || row >= rows || col < 0 || col >= cols ||
        _board[row][col].isRevealed || _board[row][col].isFlagged) {
      return;
    }
    _playTapSound();

    setState(() {
      _board[row][col].isRevealed = true;
      _cellsRevealed++;

      // First click - place mines and start timer
      if (_firstClick) {
        _firstClick = false;
        _placeMines(row, col);
        _stopwatch.start();
      }

      // Check if clicked on a mine
      if (_board[row][col].isMine) {
        _gameStatus = GameStatus.lost;
        _playLoseSound();
        _revealAllMines();
        _stopwatch.stop();
        return;
      }

      // If cell has no adjacent mines, reveal surrounding cells
      if (_board[row][col].adjacentMines == 0) {
        for (int r = max(0, row - 1); r <= min(rows - 1, row + 1); r++) {
          for (int c = max(0, col - 1); c <= min(cols - 1, col + 1); c++) {
            if (!(r == row && c == col)) {
              _revealCell(r, c);
            }
          }
        }
      }

      // Check for win condition
      if (_cellsRevealed == rows * cols - mineCount) {
        _gameStatus = GameStatus.won;
        _playWinSound();
        _stopwatch.stop();
      }
    });
  }

  void _toggleFlag(int row, int col) {
    if (_gameStatus != GameStatus.playing ||
        _board[row][col].isRevealed) {
      return;
    }

    setState(() {
      if (_board[row][col].isFlagged) {
        _board[row][col].isFlagged = false;
        _flagsPlaced--;
      } else if (_flagsPlaced < mineCount) {
        _board[row][col].isFlagged = true;
        _flagsPlaced++;
      }
    });
  }

  void _revealAllMines() {
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (_board[row][col].isMine) {
          _board[row][col].isRevealed = true;
        }
      }
    }
  }

  void _changeDifficulty(Difficulty difficulty) {
    setState(() {
      _currentDifficulty = difficulty;

      switch (difficulty) {
        case Difficulty.easy:
          rows = easyRows;
          cols = easyCols;
          mineCount = easyMines;
          break;
        case Difficulty.medium:
          rows = mediumRows;
          cols = mediumCols;
          mineCount = mediumMines;
          break;
        case Difficulty.hard:
          rows = hardRows;
          cols = hardCols;
          mineCount = hardMines;
          break;
      }

      _initializeGame();
    });
  }

  void _restartGame() {
    setState(() {
      _initializeGame();
    });
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  String _formatTime() {
    int seconds = _stopwatch.elapsed.inSeconds;
    int minutes = seconds ~/ 60;
    seconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Text(
          'Minesweeper',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Game stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBox(
                    icon: Icons.flag,
                    value: '${mineCount - _flagsPlaced}',
                    label: 'Mines Left',
                    color: Colors.red,
                  ),
                  GestureDetector(
                    onTap: _restartGame,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gameStatus == GameStatus.won
                            ? Colors.green.shade300
                            : _gameStatus == GameStatus.lost
                            ? Colors.red.shade300
                            : Colors.blue.shade300,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade300.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _gameStatus == GameStatus.playing
                            ? Icons.sentiment_neutral
                            : _gameStatus == GameStatus.won
                            ? Icons.sentiment_very_satisfied
                            : Icons.sentiment_very_dissatisfied,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  _StatBox(
                    icon: Icons.timer,
                    value: _formatTime(),
                    label: 'Time',
                    color: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Difficulty selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Difficulty:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DifficultyButton(
                          label: 'Easy',
                          mineCount: easyMines,
                          isSelected: _currentDifficulty == Difficulty.easy,
                          onTap: () => _changeDifficulty(Difficulty.easy),
                          color: Colors.green,
                        ),
                        _DifficultyButton(
                          label: 'Medium',
                          mineCount: mediumMines,
                          isSelected: _currentDifficulty == Difficulty.medium,
                          onTap: () => _changeDifficulty(Difficulty.medium),
                          color: Colors.orange,
                        ),
                        _DifficultyButton(
                          label: 'Hard',
                          mineCount: hardMines,
                          isSelected: _currentDifficulty == Difficulty.hard,
                          onTap: () => _changeDifficulty(Difficulty.hard),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Game board
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          childAspectRatio: 1.0,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                        itemCount: rows * cols,
                        itemBuilder: (context, index) {
                          int row = index ~/ cols;
                          int col = index % cols;
                          Cell cell = _board[row][col];

                          return GestureDetector(
                            onTap: () => _revealCell(row, col),
                            onLongPress: () => _toggleFlag(row, col),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cell.isRevealed
                                    ? Colors.blue.shade100
                                    : Colors.blue.shade300,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: cell.isRevealed
                                      ? Colors.blue.shade200
                                      : Colors.blue.shade400,
                                  width: 1,
                                ),
                                boxShadow: !cell.isRevealed
                                    ? [
                                  BoxShadow(
                                    color: Colors.blue.shade500.withOpacity(0.3),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Center(
                                child: _getCellContent(cell),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable Instructions
            Container(
              height: 100, // Fixed height for instructions
              color: Colors.white.withOpacity(0.9),
              child: SingleChildScrollView( // Make it scrollable
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Play:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _InstructionItem(
                            icon: Icons.touch_app,
                            text: 'Tap to reveal cell',
                          ),
                          _InstructionItem(
                            icon: Icons.flag,
                            text: 'Long press to place/remove flag',
                          ),
                          _InstructionItem(
                            icon: Icons.restart_alt,
                            text: 'Change difficulty to restart',
                          ),
                          _InstructionItem(
                            icon: Icons.warning,
                            text: 'Easy: $easyMines mines, Medium: $mediumMines mines, Hard: $hardMines mines',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCellContent(Cell cell) {
    if (cell.isFlagged) {
      return Icon(
        Icons.flag,
        color: Colors.red.shade700,
        size: 20,
      );
    }

    if (!cell.isRevealed) {
      return Container();
    }

    if (cell.isMine) {
      return Icon(
        Icons.circle,
        color: Colors.black,
        size: 16,
      );
    }

    if (cell.adjacentMines > 0) {
      return Text(
        cell.adjacentMines.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _numberColors[cell.adjacentMines],
        ),
      );
    }

    return Container();
  }
}

// Models and Enums
class Cell {
  final int row;
  final int col;
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int adjacentMines = 0;

  Cell({required this.row, required this.col});
}

enum GameStatus { playing, won, lost }
enum Difficulty { easy, medium, hard }

// Widgets
class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final int mineCount;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _DifficultyButton({
    required this.label,
    required this.mineCount,
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
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
                fontSize: 14,
              ),
            ),
            Text(
              '$mineCount mines',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}