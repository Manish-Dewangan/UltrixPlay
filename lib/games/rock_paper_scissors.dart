import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class RockPaperScissors extends StatefulWidget {
  const RockPaperScissors({super.key});

  @override
  State<RockPaperScissors> createState() => _RockPaperScissorsState();
}

class _RockPaperScissorsState extends State<RockPaperScissors>
    with SingleTickerProviderStateMixin {
  final List<String> choices = ['Rock', 'Paper', 'Scissors'];
  String playerChoice = '';
  String computerChoice = '';
  String result = '';
  int playerScore = 0;
  int computerScore = 0;
  bool _isComputerThinking = false;
  late AnimationController _controller;
  late Animation<double> _playerAnimation;
  late Animation<double> _computerAnimation;
  final Map<String, bool> _assetCache = {};
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _debugMode = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _playerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _computerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    final assets = [
      'assets/images/rock_btn.png',
      'assets/images/paper_btn.png',
      'assets/images/scissor_btn.png'
    ];

    for (final asset in assets) {
      _assetCache[asset] = await _assetExists(asset);
      if (_debugMode) {
        debugPrint('Asset $asset exists: ${_assetCache[asset]}');
      }
    }
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      if (_debugMode) {
        debugPrint('Asset load error for $path: $e');
      }
      return false;
    }
  }

  Future<void> playTapSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/btn_tap.mp3'));
    } catch (e) {
      if (_debugMode) debugPrint('Error playing sound: $e');
    }
  }

  void playGame(String userChoice) async {
    await playTapSound();

    setState(() {
      playerChoice = userChoice;
      computerChoice = '';
      result = '';
      _isComputerThinking = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    final compChoice = choices[random.nextInt(3)];
    final outcome = getResult(userChoice, compChoice);

    setState(() {
      computerChoice = compChoice;
      result = outcome;
      _isComputerThinking = false;
    });

    _controller.forward(from: 0);

    setState(() {
      if (outcome == 'You Win!') {
        playerScore++;
      } else if (outcome == 'You Lose!') {
        computerScore++;
      }
    });
  }

  String getResult(String player, String computer) {
    if (player == computer) return 'It\'s a Draw!';
    if ((player == 'Rock' && computer == 'Scissors') ||
        (player == 'Scissors' && computer == 'Paper') ||
        (player == 'Paper' && computer == 'Rock')) {
      return 'You Win!';
    }
    return 'You Lose!';
  }

  void resetGame() {
    playTapSound(); // Optional: play sound on reset
    setState(() {
      playerChoice = '';
      computerChoice = '';
      result = '';
    });
  }

  String getAssetPath(String choice) {
    switch (choice.toLowerCase()) {
      case 'rock':
        return 'assets/images/rock_btn.png';
      case 'paper':
        return 'assets/images/paper_btn.png';
      case 'scissors':
        return 'assets/images/scissor_btn.png';
      default:
        return 'assets/images/rock_btn.png';
    }
  }

  Widget buildChoiceButton(String label, String assetName) {
    final bool isSelected = playerChoice == label;
    final assetExists = _assetCache[assetName] ?? false;

    return GestureDetector(
      onTap: () => playGame(label),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3A4FCD).withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4A5FDD)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: assetExists
                ? Image.asset(assetName, width: 80, height: 80)
                : Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF3A4FCD).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4A5FDD),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  label[0],
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPlayerCard(String choice, bool isPlayer) {
    if (choice.isEmpty) return const SizedBox(width: 80, height: 80);

    final assetPath = getAssetPath(choice);
    final assetExists = _assetCache[assetPath] ?? false;
    final color = isPlayer ? Colors.blueAccent : Colors.redAccent;

    return ScaleTransition(
      scale: isPlayer ? _playerAnimation : _computerAnimation,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          color: Colors.white10,
        ),
        child: ClipOval(
          child: assetExists
              ? Image.asset(assetPath, fit: BoxFit.cover)
              : Center(
            child: Text(
              choice[0],
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0C114F).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A4FCD), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const Text("YOU", style: TextStyle(color: Colors.white70)),
              Text(
                '$playerScore',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ],
          ),
          Container(width: 2, height: 50, color: Colors.white24),
          Column(
            children: [
              const Text("CPU", style: TextStyle(color: Colors.white70)),
              Text(
                '$computerScore',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildResultPanel() {
    if (result.isEmpty) return const SizedBox.shrink();

    Color resultColor;
    switch (result) {
      case 'You Win!':
        resultColor = Colors.greenAccent;
        break;
      case 'You Lose!':
        resultColor = Colors.redAccent;
        break;
      default:
        resultColor = Colors.amber;
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          result,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: resultColor,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 15),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: resetGame,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('PLAY AGAIN', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A4FCD),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A47),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C114F),
        title: const Text(
          'ROCK PAPER SCISSORS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        elevation: 5,
        shadowColor: Colors.blueAccent.withOpacity(0.5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildScoreBoard(),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0C114F).withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Column(
                children: [
                  const Text(
                    'VS BATTLE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('YOU', style: TextStyle(color: Colors.blueAccent)),
                          const SizedBox(height: 10),
                          buildPlayerCard(playerChoice, true),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _isComputerThinking
                            ? const SizedBox(
                          width: 80,
                          height: 80,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                              strokeWidth: 4,
                            ),
                          ),
                        )
                            : Column(
                          children: [
                            const Text('CPU', style: TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 10),
                            buildPlayerCard(computerChoice, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Text(
                  'CHOOSE YOUR WEAPON:',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildChoiceButton('Rock', 'assets/images/rock_btn.png'),
                    buildChoiceButton('Scissors', 'assets/images/scissor_btn.png'),
                    buildChoiceButton('Paper', 'assets/images/paper_btn.png'),
                  ],
                ),
              ],
            ),
            buildResultPanel(),
          ],
        ),
      ),
    );
  }
}
