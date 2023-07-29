import 'package:flutter/material.dart';
import 'package:skribble_clone/core/widgets/main_button.dart';
import 'package:skribble_clone/features/room/presentation/pages/create_room_screen.dart';
import 'package:skribble_clone/features/room/presentation/pages/join_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Create/Join a room to play!',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
            ),
          ),
          // 18wMtc8oRiFEf0IG
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MainButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateRoomScreen(),
                  ),
                ),
                title: 'Create',
              ),
              MainButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const JoinRoomScreen(),
                  ),
                ),
                title: 'Join',
              ),
            ],
          )
        ],
      ),
    );
  }
}
