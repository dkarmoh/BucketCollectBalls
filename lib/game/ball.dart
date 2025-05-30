import 'package:flutter/material.dart';
import 'dart:math';

class Ball {
  double x;
  double y;
  double radius;
  double speed;

  Ball({required this.x, required this.y, required this.radius, required this.speed});

  void update(double deltaTime) {
    y += speed * deltaTime;
  }

  Rect get rect => Rect.fromCircle(center: Offset(x, y), radius: radius);

  static Ball createRandom(double maxWidth, Random random, double radius) {
    return Ball(
      x: random.nextDouble() * maxWidth,
      y: 0,
      radius: radius,
      speed: 100 + random.nextDouble() * 100,
    );
  }
}