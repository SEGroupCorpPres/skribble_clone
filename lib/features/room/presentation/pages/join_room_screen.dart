import 'package:flutter/material.dart';
import 'package:skribble_clone/core/widgets/main_button.dart';
import 'package:skribble_clone/features/paint/presentation/pages/paint_screen.dart';
import 'package:skribble_clone/features/room/presentation/widgets/custom_text_field.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => JoinRoomScreenState();
}

class JoinRoomScreenState extends State<JoinRoomScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _romNameController = TextEditingController();

  void joinRoom() {
    if (_nameController.text.isNotEmpty && _romNameController.text.isNotEmpty) {
      Map<String, String> data = {
        'nickname': _nameController.text,
        'roomName': _romNameController.text,
      };
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaintScreen(data: data, screenForm: 'joinRoom'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Join Room',
            style: TextStyle(color: Colors.black, fontSize: 30),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.08,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextField(
              controller: _nameController,
              hintText: 'Enter your name',
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextField(
              controller: _romNameController,
              hintText: 'Enter room name',
            ),
          ),
          const SizedBox(height: 20),
          MainButton(onPressed: () => joinRoom(), title: 'Join'),
        ],
      ),
    );
  }
}
