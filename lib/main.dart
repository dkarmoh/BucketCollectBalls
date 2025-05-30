import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bucket Collect Balls',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
      home: const GameScreen(),
    );
  }
}