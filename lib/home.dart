import 'package:flutter/material.dart';
import 'package:ultrixplay/games/game_2048.dart';
import 'package:ultrixplay/games/memory_match.dart';
import 'package:ultrixplay/games/minesweeper.dart';
import 'package:ultrixplay/games/number_memory_game.dart';
import 'package:ultrixplay/games/snake_game.dart';
import 'package:ultrixplay/games/tap_the_circle.dart';
import 'package:ultrixplay/games/tic_tac_toe.dart';
import 'package:ultrixplay/games/rock_paper_scissors.dart';
import 'models/game_model.dart';
import 'widgets/game_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final List<GameModel> games = [
      GameModel(
        'ROCK PAPER SCISSORS',
        'assets/images/rock_paper_logo.png',
        const RockPaperScissors(),
        accentColor: const Color(0xFFFF6B6B),
      ),
      GameModel(
        'TIC TAC TOE',
        'assets/images/tic_tac_toe.png',
        const TicTacToe(),
        accentColor: const Color(0xFF4ECDC4),
      ),
      GameModel(
        'MEMORY MATCH',
        'assets/images/match_card_logo.png',
        const MemoryMatchGame(),
        accentColor: const Color(0xFFFFD166),
      ),
      GameModel(
        'SNAKE CLASH',
        'assets/images/snake_logo.png',
        const SnakeGame(),
        accentColor: const Color(0xFF06D6A0),
      ),
      GameModel(
        'QUICK TAP',
        'assets/images/tap_logo.png',
        const TapTheCircleGame(),
        accentColor: const Color(0xFF118AB2),
      ),
      GameModel(
        'MINESWEEPER',
        'assets/images/minesweeper.png',
        const MinesweeperGame(),
        accentColor: const Color(0xFF118AB2),
      ),
      GameModel(
        'MEMORIZE NUMBER',
        'assets/images/memorize_number.png',
        const NumberMemoryGame(),
        accentColor: const Color(0xFF118AB2),
      ),
      GameModel(
        '2048',
        'assets/images/2048.png',
        const Game2048(),
        accentColor: const Color(0xFF118AB2),
      ),
    ];

    return Scaffold(
      body: Container(
        color: const Color(0xFF05044A),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 85,
              pinned: true,
              floating: false,
              snap: false,
              elevation: 0,
              backgroundColor: const Color(0xFF05044A), // <- important
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'UltrixPlay',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: Colors.white,
                  ),
                ),
                background: Image.asset(
                  'assets/images/game_hub_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final game = games[index];

                    return AnimatedGameCard(
                      game: game,
                      index: index,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => game.page,
                          ),
                        );
                      },
                    );
                  },
                  childCount: games.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1F005C),
                        Color(0xFF5B0060),
                        Color(0xFF870160),
                        Color(0xFFAC255E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.videogame_asset,
                        size: 40,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "More Games Are Coming 🚀",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Stay tuned for exciting new challenges!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
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
}

class AnimatedGameCard extends StatefulWidget {
  final GameModel game;
  final int index;
  final VoidCallback onTap;

  const AnimatedGameCard({
    super.key,
    required this.game,
    required this.index,
    required this.onTap,
  });

  @override
  State<AnimatedGameCard> createState() => _AnimatedGameCardState();
}

class _AnimatedGameCardState extends State<AnimatedGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _tiltAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
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
      animation: _controller,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_tiltAnimation.value),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: GameCard(game: widget.game),
            ),
          ),
        );
      },
    );
  }
}