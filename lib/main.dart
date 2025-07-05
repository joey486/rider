import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(RiderGame());
}

class RiderGame extends StatelessWidget {
  const RiderGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rider Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
