import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const OlafVikingGame());
}

class OlafVikingGame extends StatelessWidget {
  const OlafVikingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أولاف الفايكنج - لعبة الجري',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial', // Fallback font
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Game Constants
  static const double gameWidth = 1360;
  static const double gameHeight = 960;
  static const double groundHeight = 100;
  static const double gravity = 0.8;
  static const double jumpForce = -22.0;
  static const double speed = 8.0;

  // Game State
  late Timer _timer;
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  int backgroundType = 0; // 0: Glacier, 1: Mountain, 2: Volcano
  double distanceTraveled = 0;

  // Olaf State
  double olafY = gameHeight - groundHeight - 100; // Start on ground
  double olafX = 150;
  double olafVelocityY = 0;
  bool isJumping = false;
  double olafWidth = 60;
  double olafHeight = 90;

  // Entities
  List<GameObject> obstacles = [];
  List<GameObject> coins = [];
  Random random = Random();

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      isGameOver = false;
      score = 0;
      distanceTraveled = 0;
      backgroundType = 0;
      olafY = gameHeight - groundHeight - olafHeight;
      olafVelocityY = 0;
      obstacles.clear();
      coins.clear();
    });

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void jump() {
    if (!isPlaying) {
      startGame();
      return;
    }
    if (isGameOver) {
      startGame();
      return;
    }
    
    // Allow jump if on ground
    if (olafY >= gameHeight - groundHeight - olafHeight - 5) {
      setState(() {
        olafVelocityY = jumpForce;
        isJumping = true;
      });
    }
  }

  void updateGame() {
    if (isGameOver || !isPlaying) return;

    setState(() {
      // 1. Physics & Movement for Olaf
      olafVelocityY += gravity;
      olafY += olafVelocityY;

      // Ground Collision
      if (olafY >= gameHeight - groundHeight - olafHeight) {
        olafY = gameHeight - groundHeight - olafHeight;
        olafVelocityY = 0;
        isJumping = false;
      }

      // 2. Background & Level Progression
      distanceTraveled += speed;
      if (distanceTraveled > 3000) { // Change biome every 3000 pixels
        distanceTraveled = 0;
        backgroundType = (backgroundType + 1) % 3;
      }

      // 3. Move & Remove Obstacles
      for (var obstacle in obstacles) {
        obstacle.x -= speed;
      }
      obstacles.removeWhere((obs) => obs.x < -100);

      // 4. Move & Remove Coins
      for (var coin in coins) {
        coin.x -= speed;
      }
      coins.removeWhere((coin) => coin.x < -100);

      // 5. Spawn Entities
      spawnEntities();

      // 6. Collision Detection
      checkCollisions();
    });
  }

  void spawnEntities() {
    // Spawn Obstacles (Spikes)
    if (random.nextDouble() < 0.015) {
      // Ensure enough space between obstacles
      if (obstacles.isEmpty || obstacles.last.x < gameWidth - 300) {
        obstacles.add(GameObject(
          x: gameWidth,
          y: gameHeight - groundHeight - 60, // Spikes on ground
          width: 50,
          height: 60,
          type: EntityType.obstacle,
        ));
      }
    }

    // Spawn Coins
    if (random.nextDouble() < 0.02) {
      double coinY = gameHeight - groundHeight - 150 - random.nextDouble() * 200; // Air coins
      coins.add(GameObject(
        x: gameWidth,
        y: coinY,
        width: 40,
        height: 40,
        type: EntityType.coin,
      ));
    }
  }

  void checkCollisions() {
    // Olaf Hitbox
    Rect olafRect = Rect.fromLTWH(olafX + 10, olafY + 10, olafWidth - 20, olafHeight - 20);

    // Check Obstacles
    for (var obstacle in obstacles) {
      Rect obsRect = Rect.fromLTWH(obstacle.x + 10, obstacle.y + 10, obstacle.width - 20, obstacle.height - 20);
      if (olafRect.overlaps(obsRect)) {
        gameOver();
        return;
      }
    }

    // Check Coins
    for (var coin in List.of(coins)) {
      Rect coinRect = Rect.fromLTWH(coin.x, coin.y, coin.width, coin.height);
      if (olafRect.overlaps(coinRect)) {
        score += 10;
        coins.remove(coin);
      }
    }
  }

  void gameOver() {
    setState(() {
      isGameOver = true;
    });
    _timer.cancel();
  }

  // --- Rendering Helpers ---

  LinearGradient getBackgroundGradient() {
    switch (backgroundType) {
      case 0: // Glacier
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
        );
      case 1: // Mountain
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD7CCC8), Color(0xFF8D6E63)],
        );
      case 2: // Volcano
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFCCBC), Color(0xFFD84315)],
        );
      default:
        return const LinearGradient(colors: [Colors.blue, Colors.white]);
    }
  }

  Color getGroundColor() {
    switch (backgroundType) {
      case 0: return Colors.white; // Snow
      case 1: return const Color(0xFF5D4037); // Earth
      case 2: return const Color(0xFF3E2723); // Dark Rock
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scale game to fit screen while maintaining aspect ratio
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: gameWidth,
              height: gameHeight,
              child: GestureDetector(
                onTap: jump, // Tap anywhere to jump/start
                child: Container(
                  decoration: BoxDecoration(
                    gradient: getBackgroundGradient(),
                  ),
                  child: Stack(
                    children: [
                      // Background Elements (Decorations could go here)
                      Positioned(
                        top: 50,
                        right: 50,
                        child: Icon(
                          backgroundType == 2 ? Icons.local_fire_department : Icons.cloud,
                          size: 100,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),

                      // Ground
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: groundHeight,
                        child: Container(
                          color: getGroundColor(),
                          child: Row(
                            children: List.generate(20, (index) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                color: Colors.black12,
                              ),
                            )),
                          ),
                        ),
                      ),

                      // Olaf (The Viking)
                      Positioned(
                        left: olafX,
                        top: olafY,
                        width: olafWidth,
                        height: olafHeight,
                        child: const VikingWidget(),
                      ),

                      // Obstacles
                      ...obstacles.map((obs) => Positioned(
                        left: obs.x,
                        top: obs.y,
                        width: obs.width,
                        height: obs.height,
                        child: const SpikeWidget(),
                      )),

                      // Coins
                      ...coins.map((coin) => Positioned(
                        left: coin.x,
                        top: coin.y,
                        width: coin.width,
                        height: coin.height,
                        child: const CoinWidget(),
                      )),

                      // UI: Score
                      Positioned(
                        top: 30,
                        left: 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.yellow, size: 30),
                              const SizedBox(width: 10),
                              Text(
                                '$score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // UI: Start / Game Over Screen
                      if (!isPlaying || isGameOver)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isGameOver ? 'انتهت اللعبة!' : 'أولاف الفايكنج',
                                  style: const TextStyle(
                                    fontSize: 80,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (isGameOver)
                                  Text(
                                    'النقاط النهائية: $score',
                                    style: const TextStyle(fontSize: 40, color: Colors.yellow),
                                  ),
                                const SizedBox(height: 50),
                                ElevatedButton(
                                  onPressed: startGame,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                                    backgroundColor: Colors.orange,
                                  ),
                                  child: Text(
                                    isGameOver ? 'إعادة المحاولة' : 'ابدأ اللعب',
                                    style: const TextStyle(fontSize: 30, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Game Entities ---

enum EntityType { obstacle, coin }

class GameObject {
  double x;
  double y;
  double width;
  double height;
  EntityType type;

  GameObject({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
  });
}

// --- Custom Widgets for Graphics ---

class VikingWidget extends StatelessWidget {
  const VikingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Body
        Container(
          width: 40,
          height: 50,
          margin: const EdgeInsets.only(top: 30),
          decoration: BoxDecoration(
            color: Colors.brown,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        // Head
        Positioned(
          top: 0,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFCC80), // Skin tone
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Helmet
        Positioned(
          top: -5,
          child: Icon(Icons.security, size: 50, color: Colors.grey[700]),
        ),
        // Beard
        Positioned(
          top: 25,
          child: Container(
            width: 30,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange[900],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}

class SpikeWidget extends StatelessWidget {
  const SpikeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 60,
      child: CustomPaint(
        painter: SpikePainter(),
      ),
    );
  }
}

class SpikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    final path = Path();
    // Draw 3 spikes
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.2, 0);
    path.lineTo(size.width * 0.4, size.height);
    path.lineTo(size.width * 0.6, 0);
    path.lineTo(size.width * 0.8, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CoinWidget extends StatelessWidget {
  const CoinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.yellowAccent, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: const Center(
        child: Text(
          '\$',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }
}
