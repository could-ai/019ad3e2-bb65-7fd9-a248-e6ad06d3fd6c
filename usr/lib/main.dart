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
  late Timer _timer;
  double olafY = 400; // موقع أولاف العمودي
  double olafX = 100; // موقع أولاف الأفقي
  List<Obstacle> obstacles = [];
  List<Coin> coins = [];
  int score = 0;
  bool isGameOver = false;
  double scrollX = 0; // للتمرير الخلفية
  int backgroundType = 0; // 0: جليدي، 1: جبال، 2: بركان
  Random random = Random();

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    isGameOver = false;
    score = 0;
    olafY = 400;
    obstacles.clear();
    coins.clear();
    scrollX = 0;
    backgroundType = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    if (isGameOver) return;

    setState(() {
      // تحديث التمرير
      scrollX += 2;
      if (scrollX > 1360) {
        scrollX = 0;
        backgroundType = (backgroundType + 1) % 3;
      }

      // تحديث العوائق
      for (var obstacle in obstacles) {
        obstacle.x -= 5;
      }
      obstacles.removeWhere((obstacle) => obstacle.x < -50);

      // تحديث العملات
      for (var coin in coins) {
        coin.x -= 5;
      }
      coins.removeWhere((coin) => coin.x < -50);

      // إضافة عوائق وعملات عشوائياً
      if (random.nextDouble() < 0.02) {
        obstacles.add(Obstacle(1360, random.nextDouble() * 800 + 100));
      }
      if (random.nextDouble() < 0.03) {
        coins.add(Coin(1360, random.nextDouble() * 800 + 100));
      }

      // التحقق من التصادم مع العوائق
      for (var obstacle in obstacles) {
        if (olafX + 50 > obstacle.x && olafX < obstacle.x + 50 &&
            olafY + 50 > obstacle.y && olafY < obstacle.y + 50) {
          gameOver();
        }
      }

      // التحقق من جمع العملات
      for (var coin in coins) {
        if (olafX + 50 > coin.x && olafX < coin.x + 50 &&
            olafY + 50 > coin.y && olafY < coin.y + 50) {
          score += 10;
          coins.remove(coin);
          break;
        }
      }
    });
  }

  void gameOver() {
    isGameOver = true;
    _timer.cancel();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتهت اللعبة'),
        content: Text('نقاطك: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startGame();
            },
            child: const Text('إعادة اللعب'),
          ),
        ],
      ),
    );
  }

  void jump() {
    if (!isGameOver) {
      setState(() {
        olafY -= 100;
        if (olafY < 0) olafY = 0;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          olafY += 100;
          if (olafY > 800) olafY = 800;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: jump,
        child: Container(
          width: 1360,
          height: 960,
          decoration: BoxDecoration(
            color: backgroundType == 0
                ? Colors.lightBlueAccent
                : backgroundType == 1
                    ? Colors.green[200]
                    : Colors.redAccent,
          ),
          child: Stack(
            children: [
              // رسم أولاف
              Positioned(
                left: olafX,
                top: olafY,
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.orange,
                  child: const Center(child: Text('O', style: TextStyle(fontSize: 30, color: Colors.white))),
                ),
              ),
              // رسم العوائق
              ...obstacles.map((obstacle) => Positioned(
                left: obstacle.x,
                top: obstacle.y,
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey,
                  child: const Center(child: Text('⚠', style: TextStyle(fontSize: 30))),
                ),
              )),
              // رسم العملات
              ...coins.map((coin) => Positioned(
                left: coin.x,
                top: coin.y,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('¢', style: TextStyle(fontSize: 20, color: Colors.white))),
                ),
              )),
              // عرض النقاط
              Positioned(
                top: 20,
                left: 20,
                child: Text(
                  'النقاط: $score',
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Obstacle {
  double x, y;
  Obstacle(this.x, this.y);
}

class Coin {
  double x, y;
  Coin(this.x, this.y);
}