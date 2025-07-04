import 'package:flutter/material.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(RiderGame());
}

class RiderGame extends StatelessWidget {
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
