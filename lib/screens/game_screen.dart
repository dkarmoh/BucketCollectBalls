import 'package:flutter/material.dart';
import '../game/game_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _gameWidgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bucket Collect Balls'),
        backgroundColor: Colors.blueAccent.withOpacity(0.8),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          final state = _gameWidgetKey.currentState;
          if (state != null && state is State<GameWidget>) {
            final widgetState = state as dynamic;
            if (widgetState.isGameOver == true) {
              widgetState.reset();
            }
          }
        },
        child: GameWidget(key: _gameWidgetKey),
      ),
    );
  }
}