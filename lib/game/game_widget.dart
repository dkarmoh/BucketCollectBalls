import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'game_controller.dart';

class GameWidget extends StatefulWidget {
  const GameWidget({Key? key}) : super(key: key);

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> with TickerProviderStateMixin {
  late GameController controller;
  late AnimationController animController;
  late AudioPlayer audioPlayer;
  bool initialized = false;
  Future<Map<String, ui.Image>>? _imageFuture;

  GameController get gameController => controller;
  bool get isGameOver => controller.gameOver;
  bool get isPlaying => controller.isPlaying;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(() {
      if (initialized) {
        setState(() {
          controller.update(1 / 60, MediaQuery.of(context).size, audioPlayer);
        });
      }
    });
    animController.forward();
    _imageFuture = _loadImages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      controller = GameController(MediaQuery.of(context));
      initialized = true;
      print('Game initialized with screen size: ${MediaQuery.of(context).size}, padding: ${MediaQuery.of(context).padding}');
    }
  }

  @override
  void dispose() {
    animController.dispose();
    controller.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      controller.startGame(MediaQuery.of(context));
      animController.forward(from: 0);
      print('Game started, isPlaying: ${controller.isPlaying}');
    });
  }

  void reset() {
    setState(() {
      controller.reset(MediaQuery.of(context));
      print('Game reset');
    });
  }

  Future<Map<String, ui.Image>> _loadImages() async {
    try {
      final bucketImage = await _loadImage('assets/images/bucket.png');
      final ballImage = await _loadImage('assets/images/ball.png');
      final bgImage = await _loadImage('assets/images/background.jpg');
      print('Images loaded: bucket=${bucketImage.width}x${bucketImage.height}, ball=${ballImage.width}x${ballImage.height}, bg=${bgImage.width}x${bgImage.height}');
      return {'bucket': bucketImage, 'ball': ballImage, 'background': bgImage};
    } catch (e) {
      print('Image loading failed: $e');
      return {};
    }
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await DefaultAssetBundle.of(context).load(path);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    print('Building GameWidget, screen size: ${mediaQuery.size}, safe area: ${mediaQuery.padding}');
    return FutureBuilder<Map<String, ui.Image>>(
      future: _imageFuture,
      builder: (context, snapshot) {
        return Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) => controller.onPanUpdate(details, mediaQuery),
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: GamePainter(
                    controller,
                    bucketImage: snapshot.data?['bucket'],
                    ballImage: snapshot.data?['ball'],
                    backgroundImage: snapshot.data?['background'],
                  ),
                  size: mediaQuery.size,
                ),
              ),
            ),
            if (!controller.isPlaying && !controller.gameOver)
              Center(
                child: ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blueAccent,
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                  ),
                  child: const Text('Play'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class GamePainter extends CustomPainter {
  final GameController controller;
  final ui.Image? bucketImage;
  final ui.Image? ballImage;
  final ui.Image? backgroundImage;

  GamePainter(this.controller, {this.bucketImage, this.ballImage, this.backgroundImage});

  @override
  void paint(Canvas canvas, Size size) {
    print('Painting, isPlaying: ${controller.isPlaying}, gameOver: ${controller.gameOver}, canvas size: $size');

    if (!controller.isPlaying && !controller.gameOver) {
      // Start screen background
      final startBgPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.7,
          colors: [Colors.teal.shade900, Colors.black],
          stops: [0.4, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), startBgPaint);
      print('Drew start screen background');
      return;
    }

    // In-game background
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
      print('Drew background image');
    } else {
      final gradientPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
      print('Drew gradient background');
    }

    print('Drawing bucket at: ${controller.bucket.rect}');
    if (bucketImage != null) {
      canvas.drawImageRect(
        bucketImage!,
        Rect.fromLTWH(0, 0, bucketImage!.width.toDouble(), bucketImage!.height.toDouble()),
        controller.bucket.rect,
        Paint(),
      );
      print('Drew bucket image');
    } else {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          controller.bucket.rect.translate(2, 2),
          const Radius.circular(10),
        ),
        shadowPaint,
      );
      final bucketPaint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          controller.bucket.rect,
          const Radius.circular(10),
        ),
        bucketPaint,
      );
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          controller.bucket.rect,
          const Radius.circular(10),
        ),
        borderPaint,
      );
      print('Drew bucket shape with border');
    }

    // Debug outline for bucket
    final debugPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(controller.bucket.rect, debugPaint);
    print('Drew bucket debug outline');

    for (var ball in controller.balls) {
      print('Drawing ball at: (${ball.x}, ${ball.y})');
      if (ballImage != null) {
        canvas.drawImageRect(
          ballImage!,
          Rect.fromLTWH(0, 0, ballImage!.width.toDouble(), ballImage!.height.toDouble()),
          Rect.fromCircle(center: Offset(ball.x, ball.y), radius: ball.radius),
          Paint(),
        );
      } else {
        canvas.drawCircle(
          Offset(ball.x, ball.y + 2),
          ball.radius,
          Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawCircle(
          Offset(ball.x, ball.y),
          ball.radius,
          Paint()
            ..color = Colors.redAccent
            ..style = PaintingStyle.fill,
        );
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Score: ${controller.score}  Missed: ${controller.missedBalls}',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.05,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));

    if (controller.gameOver) {
      final gameOverPainter = TextPainter(
        text: TextSpan(
          text: 'Game Over!\nTap to Restart',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: size.width * 0.08,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2))],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      gameOverPainter.layout(maxWidth: size.width - 40);
      gameOverPainter.paint(
        canvas,
        Offset(20, size.height / 2 - gameOverPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}