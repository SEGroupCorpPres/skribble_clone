import 'package:flutter/material.dart';
import 'package:skribble_clone/core/widgets/main_button.dart';
import 'package:skribble_clone/features/paint/presentation/pages/paint_screen.dart';
import 'package:skribble_clone/features/room/presentation/widgets/custom_text_field.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _romNameController = TextEditingController();
  late String? _maxRoundsValue = null;
  late String? _maxRomSizeValue = null;

  void createRoom() {
    if (_nameController.text.isNotEmpty
        && _romNameController.text.isNotEmpty
        && _maxRoundsValue != null
        && _maxRomSizeValue != null) {
      Map<String, String> data = {
        'nickname': _nameController.text,
        'roomName': _romNameController.text,
        'occupancy': _maxRomSizeValue!,
        'maxRounds': _maxRoundsValue!,
      };
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaintScreen(data: data, screenForm: 'createForm',),
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
            'Create Room',
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
          DropdownButton<String>(
            focusColor: const Color(0xFFF5F6FA),
            items: <String>['2', '5', '10', '15']
                .map<DropdownMenuItem<String>>(
                  (String value) => DropdownMenuItem(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                )
                .toList(),
            hint: Text(
             _maxRoundsValue ?? 'Select max rounds',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: (String? value) {
              setState(() {
                _maxRoundsValue = value;
              });
            },
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            focusColor: const Color(0xFFF5F6FA),
            items: <String>['2', '3', '4', '5', '6', '7', '8']
                .map<DropdownMenuItem<String>>(
                  (String value) => DropdownMenuItem(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                )
                .toList(),
            hint: Text(
              _maxRomSizeValue ?? 'Select room size',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: (String? value) {
              setState(() {
                _maxRomSizeValue = value;
              });
            },
          ),
          const SizedBox(height: 30),
          MainButton(onPressed: () => createRoom(), title: 'Create'),
        ],
      ),
    );
  }
}
