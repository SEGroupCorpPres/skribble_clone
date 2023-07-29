import 'package:flutter/material.dart';
import 'package:skribble_clone/features/paint/presentation/pages/paint_screen.dart';
import 'package:skribble_clone/features/room/presentation/pages/create_room_screen.dart';

import 'features/home/presentation/pages/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scribble.io  Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      // home: PaintScreen(),
    );
  }
}
