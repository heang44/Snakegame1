import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SnakeGameApp());

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const StartScreen(),
      theme: ThemeData(fontFamily: 'PressStart2P'),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 72, 134),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SNAKE GAME',
                style: TextStyle(fontSize: 36, color: Colors.green)),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SnakeGame())),
              child: const Text('PLAY', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static const int gridSize = 15;
  static const int cellCount = gridSize * gridSize;
  final List<int> snake = [112, 113, 114];
  int food = Random().nextInt(cellCount);
  List<int> walls = [];

  String direction = 'right';
  String nextDirection = 'right';
  Timer? gameTimer;

  int score = 0;
  int highScore = 0;
  bool isPaused = false;
  bool gameOver = false;
  int gameSpeed = 200;
  bool showMenu = false;

  @override
  void initState() {
    super.initState();
    loadPreferences();
    generateWalls();
    startGame();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
      gameSpeed = prefs.getInt('gameSpeed') ?? 200;
    });
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
    await prefs.setInt('gameSpeed', gameSpeed);
  }

  void generateWalls() {
    walls = [];
    for (int i = 0; i < gridSize; i++) {
      walls.add(i);
      walls.add(i * gridSize);
      walls.add((i + 1) * gridSize - 1);
      walls.add((gridSize - 1) * gridSize + i);
    }
    while (walls.contains(food) || snake.contains(food)) {
      food = Random().nextInt(cellCount);
    }
  }

  void startGame() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(Duration(milliseconds: gameSpeed), (timer) {
      if (!isPaused && !gameOver && !showMenu) moveSnake();
    });
  }

  void moveSnake() {
    setState(() {
      direction = nextDirection;
      final head = snake.last;
      int newHead;

      switch (direction) {
        case 'up': newHead = head - gridSize; break;
        case 'down': newHead = head + gridSize; break;
        case 'left': newHead = head - 1; break;
        case 'right': newHead = head + 1; break;
        default: return;
      }

      if (snake.contains(newHead) || walls.contains(newHead) || newHead < 0 || newHead >= cellCount) {
        gameOver = true;
        gameTimer?.cancel();
        showGameOver();
        return;
      }

      snake.add(newHead);
      if (newHead == food) {
        score += 10;
        if (score > highScore) highScore = score;
        savePreferences();
        do {
          food = Random().nextInt(cellCount);
        } while (snake.contains(food) || walls.contains(food));
      } else {
        snake.removeAt(0);
      }
    });
  }

  void changeDirection(String newDir) {
    if ((newDir == 'up' && direction != 'down') ||
        (newDir == 'down' && direction != 'up') ||
        (newDir == 'left' && direction != 'right') ||
        (newDir == 'right' && direction != 'left')) {
      nextDirection = newDir;
    }
  }

  void resetGame() {
    setState(() {
      snake.clear();
      snake.addAll([112, 113, 114]);
      direction = 'right';
      nextDirection = 'right';
      score = 0;
      gameOver = false;
      showMenu = false;
      generateWalls();
    });
    startGame();
  }

  void togglePause() {
    setState(() => isPaused = !isPaused);
  }

  void toggleMenu() {
    setState(() {
      showMenu = !showMenu;
      if (showMenu) isPaused = true;
    });
  }

  void changeSpeed(int newSpeed) {
    setState(() => gameSpeed = newSpeed);
    savePreferences();
    if (!isPaused && !gameOver) startGame();
  }

  void showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.green, width: 2),
        ),
        title: const Text('GAME OVER', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score', style: const TextStyle(color: Colors.white)),
            Text('High Score: $highScore', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  resetGame();
                },
                child: const Text('PLAY AGAIN', style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pop(context);
                },
                child: const Text('EXIT', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
      itemCount: cellCount,
      itemBuilder: (ctx, index) {
        if (snake.contains(index)) {
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: index == snake.last ? Colors.lightGreen : Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: index == snake.last
                ? Center(child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ))
                : null,
          );
        } else if (index == food) {
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          );
        } else if (walls.contains(index)) {
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.brown,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        } else {
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }
      },
    );
  }

  Widget buildGameMenu() {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME MENU', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showMenu = false;
                  isPaused = false;
                });
                startGame();
              },
              child: const Text('RESUME'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: resetGame,
              child: const Text('RESTART'),
            ),
            const SizedBox(height: 10),
            const Text('GAME SPEED', style: TextStyle(color: Colors.white)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Slow'),
                  selected: gameSpeed == 300,
                  onSelected: (_) => changeSpeed(300),
                  selectedColor: Colors.green,
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Medium'),
                  selected: gameSpeed == 200,
                  onSelected: (_) => changeSpeed(200),
                  selectedColor: Colors.green,
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Fast'),
                  selected: gameSpeed == 100,
                  onSelected: (_) => changeSpeed(100),
                  selectedColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('EXIT GAME'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SCORE: $score', style: const TextStyle(color: Colors.white)),
                    Text('HIGH: $highScore', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Expanded(child: buildGrid()),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: DirectionPad(
              onDirectionChanged: changeDirection,
              color: Colors.green,
            ),
          ),
          if (showMenu) buildGameMenu(),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              onPressed: toggleMenu,
            ),
          ),
          if (isPaused && !showMenu)
            const Center(child: Text('PAUSED', style: TextStyle(color: Colors.white, fontSize: 30))),
        ],
      ),
    );
  }
}

class DirectionPad extends StatelessWidget {
  final Function(String) onDirectionChanged;
  final Color color;

  const DirectionPad({
    super.key,
    required this.onDirectionChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onDirectionChanged('up'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.keyboard_arrow_up, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => onDirectionChanged('left'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.keyboard_arrow_left, color: color, size: 30),
              ),
            ),
            const SizedBox(width: 58),
            GestureDetector(
              onTap: () => onDirectionChanged('right'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.keyboard_arrow_right, color: color, size: 30),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => onDirectionChanged('down'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.keyboard_arrow_down, color: color, size: 30),
          ),
        ),
      ],
    );
  }
}