import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'bucket.dart';
import 'ball.dart';
import 'dart:math';

class GameController {
  late Bucket bucket; // Added 'late' to fix null safety error
  List<Ball> balls = [];
  int score = 0;
  int missedBalls = 0;
  final int maxMissed = 5;
  bool gameOver = false;
  bool isPlaying = false;
  double lastBallSpawn = 0;
  final double spawnInterval = 1.0;
  final Random random = Random();

  GameController(MediaQueryData mediaQuery) {
    final safeHeight = mediaQuery.size.height - mediaQuery.padding.bottom;
    bucket = Bucket(
      x: mediaQuery.size.width / 2 - (mediaQuery.size.width * 0.4 / 2),
      y: safeHeight - 250,
      width: mediaQuery.size.width * 0.4,
      height: mediaQuery.size.width * 0.2,
    );
    print('Initial bucket: x=${bucket.x}, y=${bucket.y}, width=${bucket.width}, height=${bucket.height}, screen=${mediaQuery.size}, padding=${mediaQuery.padding}, safeHeight=$safeHeight');
    _printSafeAreaDebug(mediaQuery);
  }

  void _printSafeAreaDebug(MediaQueryData mediaQuery) {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final viewPadding = view.viewPadding;
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    final safeHeight = mediaQuery.size.height - mediaQuery.padding.bottom;
    print('Safe area debug: viewPadding=$viewPadding, physicalSize=$physicalSize, devicePixelRatio=$devicePixelRatio, safeHeight=$safeHeight');
  }

  void startGame(MediaQueryData mediaQuery) {
    score = 0;
    missedBalls = 0;
    gameOver = false;
    isPlaying = true;
    balls.clear();
    lastBallSpawn = 0;
    final safeHeight = mediaQuery.size.height - mediaQuery.padding.bottom;
    bucket.x = mediaQuery.size.width / 2 - (mediaQuery.size.width * 0.4 / 2);
    bucket.y = safeHeight - 250;
    bucket.width = mediaQuery.size.width * 0.4;
    bucket.height = mediaQuery.size.width * 0.2;
    print('Game started, bucket reset to: x=${bucket.x}, y=${bucket.y}');
    _printSafeAreaDebug(mediaQuery);
  }

  void update(double deltaTime, Size size, AudioPlayer audioPlayer) {
    if (!isPlaying || gameOver) return;

    for (var ball in balls.toList()) {
      ball.update(deltaTime);
      if (ball.y > size.height) {
        balls.remove(ball);
        missedBalls++;
        audioPlayer.play(AssetSource('sounds/miss.mp3')).catchError((e) {
          print('Error playing miss sound: $e');
        });
        print('Ball missed, total missed: $missedBalls');
        if (missedBalls >= maxMissed) {
          gameOver = true;
          isPlaying = false;
          print('Game over');
        }
      } else if (bucket.rect.overlaps(ball.rect)) {
        balls.remove(ball);
        score++;
        audioPlayer.play(AssetSource('sounds/catch.mp3')).catchError((e) {
          print('Error playing catch sound: $e');
        });
        print('Ball caught, score: $score');
      }
    }

    lastBallSpawn += deltaTime;
    if (lastBallSpawn >= spawnInterval) {
      balls.add(Ball.createRandom(size.width, random, size.width * 0.025));
      lastBallSpawn = 0;
      print('Spawned new ball');
    }
  }

  void onPanUpdate(DragUpdateDetails details, MediaQueryData mediaQuery) {
    if (isPlaying && !gameOver) {
      bucket.x += details.delta.dx * 1.5; // Increased sensitivity
      if (bucket.x < 0) bucket.x = 0;
      if (bucket.x > mediaQuery.size.width - bucket.width) {
        bucket.x = mediaQuery.size.width - bucket.width;
      }
      print('Bucket moved to: x=${bucket.x}, y=${bucket.y}');
    }
  }

  void reset(MediaQueryData mediaQuery) {
    startGame(mediaQuery);
    print('Game reset');
  }

  void dispose() {}
}