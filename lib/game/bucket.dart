import 'package:flutter/material.dart';

class Bucket {
  double x;
  double y;
  double width;
  double height;

  Bucket({required this.x, required this.y, required this.width, required this.height});

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}