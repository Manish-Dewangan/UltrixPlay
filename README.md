

# UltrixPlay

UltrixPlay is an all-in-one Flutter gaming application featuring 8 interactive arcade and puzzle mini-games, complete with custom audio effects and a responsive dashboard.

## Project preview
<!-- Add your screenshots here. The tags below are placeholders matching the reference structure. -->
<img width="2000" height="1414" alt="1" src="https://github.com/user-attachments/assets/20bae736-e50a-4263-a580-7b3bcd7d93ad" />


---


<img width="2000" height="1414" alt="2" src="https://github.com/user-attachments/assets/bfc1dd0a-4bad-42bd-9fc0-11b48b02b4aa" />

---

## Project structure

- `lib/` - Main Flutter application source code.
  - `games/` - Mini-game logic and UI implementations (2048, Snake, Minesweeper, Memory Match, etc.).
  - `models/` - Data structures for games and grid cards.
  - `screens/` - App entry screens including animated SplashScreen.
  - `widgets/` - Reusable UI components such as `GameCard`.
- `assets/` - Image graphics (`assets/images/`) and audio sound effects (`assets/sounds/`).
- `android/` - Android native project files, Gradle scripts, and launcher resources.
- `ios/` - iOS Runner and Xcode project configuration.
- `web/` - Web platform files and entry points.
- `windows/`, `macos/`, `linux/` - Desktop platform runners.

## Features

- **8 Embedded Mini-Games**:
  - 🧩 **2048**: Classic tile sliding puzzle game.
  - 🐍 **Snake Game**: Retro arcade snake game with direction controls and collision detection.
  - 💣 **Minesweeper**: Grid strategy game with mine generation and tile reveal mechanisms.
  - 🧠 **Memory Match**: Card-flipping matching game with visual grid feedback.
  - 🔢 **Number Memory**: Sequence memory recall test.
  - ✊ **Rock Paper Scissors**: Classic decision choice game against AI.
  - 🎯 **Tap The Circle**: High-speed reflex reaction speed challenge.
  - ❌ **Tic Tac Toe**: Classic X and O turn-based grid game.
- **Audio Feedback**: Built-in sound effects using `audioplayers` for button taps, card flips, win/lose events, and tile swipes.
- **Cross-Platform Support**: Built with Flutter supporting Android, iOS, Web, Windows, macOS, and Linux.
- **Responsive UI**: Custom animated dashboard interface for seamlessly launching mini-games.

## Prerequisites

- Flutter SDK (3.24.0+ or compatible version)
- Dart SDK (3.8.1+)
- Android Studio / Xcode (for mobile compilation) or VS Code
- A connected physical device, emulator, or simulator

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/UltrixPlay.git
cd UltrixPlay
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

For mobile emulator or connected device:

```bash
flutter run
```

For web browser:

```bash
flutter run -d chrome
```

For desktop (Windows):

```bash
flutter run -d windows
```

## Games Catalog

| Game | Path | Description |
| :--- | :--- | :--- |
| **2048** | `lib/games/game_2048.dart` | Slide numbered tiles on a grid to combine them and reach 2048. |
| **Memory Match** | `lib/games/memory_match.dart` | Flip cards to find matching pairs with minimum moves. |
| **Minesweeper** | `lib/games/minesweeper.dart` | Uncover safe tiles on a grid without detonating hidden mines. |
| **Number Memory** | `lib/games/number_memory_game.dart` | Remember and repeat increasingly long digit sequences. |
| **Rock Paper Scissors** | `lib/games/rock_paper_scissors.dart` | Play classic Rock-Paper-Scissors against an AI opponent. |
| **Snake Game** | `lib/games/snake_game.dart` | Navigate the snake, eat food, grow longer, and avoid walls. |
| **Tap The Circle** | `lib/games/tap_the_circle.dart` | Test your reaction time by tapping rapidly appearing target circles. |
| **Tic Tac Toe** | `lib/games/tic_tac_toe.dart` | Connect three marks in a row on a 3x3 grid. |

## Notes

- Audio effects require device audio capability configured via `audioplayers`.
- Custom launcher icons are configured via `flutter_launcher_icons`.

## License

This project does not include a license file. Add one if you want to share or publish the code.

