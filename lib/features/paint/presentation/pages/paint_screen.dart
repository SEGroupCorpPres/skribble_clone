import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:skribble_clone/features/home/presentation/pages/home_screen.dart';
import 'package:skribble_clone/features/paint/data/remote/models/touch_points.dart';
import 'package:skribble_clone/features/paint/domain/entities/my_custom_pointer.dart';
import 'package:skribble_clone/features/paint/presentation/pages/final_leaderboard_screen.dart';
import 'package:skribble_clone/features/paint/presentation/pages/waiting_lobby_screen.dart';
import 'package:skribble_clone/features/sidebar/presentation/pages/player_scoreboard_drawer.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class PaintScreen extends StatefulWidget {
  final Map<String, String> data;
  final String screenForm;

  const PaintScreen({super.key, required this.data, required this.screenForm});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  late io.Socket _socket;
  Map? dataOfRoom = {};
  List<TouchPoints> points = [];
  StrokeCap strokeType = StrokeCap.round;
  Color selectedColor = Colors.black;
  double opacity = 1;
  double strokeWidth = 2;
  List<Widget> textBlankWidget = [];
  ScrollController _scrollController = ScrollController();
  TextEditingController _controller = TextEditingController();
  List<Map> messages = [];
  int guessedUserCtr = 0;
  int _start = 60;
  late Timer _timer;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map> scoreboard = [];
  bool isTextInputReadOnly = false;
  int maxPoints = 0;
  String winner = '';
  bool isShowFinalLeaderboard = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    connect();
    print('data ${widget.data}');
    print(widget.data['nickname']);
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer time) {
      if (_start == 0) {
        _socket.emit('change-turn', dataOfRoom!['roomName']);
        setState(() {
          _timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void renderTextBlank(String text) {
    textBlankWidget.clear();
    for (int i = 0; i < text.length; i++) {
      textBlankWidget.add(const Text(
        '_',
        style: TextStyle(fontSize: 30),
      ));
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _socket.dispose();
    _timer.cancel();
  }

  void connect() {
    _socket = io.io(
      "http://192.168.43.252:3000",
      io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket.connect();

    if (widget.screenForm == 'createForm') {
      _socket.emit('create-game', widget.data);
    } else {
      _socket.emit('join-game', widget.data);
    }
    _socket.onConnect((data) {
      print('connected');
      _socket.on('updateRoom', (roomData) {
        print(roomData['word']);
        setState(() {
          renderTextBlank(roomData['word']);
          dataOfRoom = roomData;
        });
        if (roomData['isJoined'] != true) {
          //  start the timer
          startTimer();
        }
        scoreboard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreboard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString(),
            });
          });
        }
      });

      _socket.on(
        'notCorrectGame',
        (data) => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
            (route) => false),
      );
      _socket.on('points', (point) {
        if (point['details'] != null) {
          setState(() {
            points.add(
              TouchPoints(
                paint: Paint()
                  ..strokeCap = strokeType
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth,
                points: Offset(
                  (point['details']['dx']).toDouble(),
                  (point['details']['dy']).toDouble(),
                ),
              ),
            );
          });
        } else {
          print('data: ${point['details']} = nul');
        }
      });

      _socket.on('msg', (msgData) {
        setState(() {
          messages.add(msgData);
          guessedUserCtr = msgData['guessedUserCtr'];
        });
        if (guessedUserCtr == dataOfRoom!['players'].length - 1) {
          _socket.emit('change-turn', dataOfRoom!['roomName']);
        }
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 40,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      });

      _socket.on('change-turn', (data) {
        String oldWord = dataOfRoom!['word'];
        showDialog(
            context: context,
            builder: (context) {
              Future.delayed(const Duration(seconds: 3), () {
                setState(() {
                  dataOfRoom = data;
                  renderTextBlank(data['word']);
                  isTextInputReadOnly = false;
                  guessedUserCtr = 0;
                  _start = 60;
                  points.clear();
                });
                Navigator.pop(context);
                _timer.cancel();
                startTimer();
              });
              return AlertDialog(
                title: Center(
                  child: Text('Word was $oldWord'),
                ),
              );
            });
      });

      _socket.on('updateScore', (roomData) {
        scoreboard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreboard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString(),
            });
          });
        }
      });

      _socket.on('show-leaderboard', (roomPlayers) {
        scoreboard.clear();
        for (int i = 0; i < roomPlayers.length; i++) {
          setState(() {
            scoreboard.add({
              'username': roomPlayers[i]['nickname'],
              'points': roomPlayers[i]['points'].toString(),
            });
          });
          if (maxPoints < int.parse(scoreboard[i]['points'])) {
            winner = scoreboard[i]['username'];
            maxPoints = int.parse(scoreboard[i]['points']);
          }
        }
        setState(() {
          _timer.cancel();
          isShowFinalLeaderboard = true;
        });
      });
      _socket.on('color-change', (colorString) {
        int color = int.parse(colorString, radix: 16);
        Color newColor = Color(color);
        setState(() {
          selectedColor = newColor;
        });
      });

      _socket.on('stroke-width', (value) {
        setState(() {
          strokeWidth = value.toDouble();
        });
      });
      _socket.on('clear-screen', (data) {
        setState(() {
          points.clear();
          print('$points -> cleared');
        });
      });

      _socket.on('user-disconnected', (data) {
        scoreboard.clear();
        for (int i = 0; i < data['players'].length; i++) {
          setState(() {
            scoreboard.add({
              'username': data['players'][i]['nickname'],
              'points': data['players'][i]['points'].toString(),
            });
          });
        }
      });

      _socket.on('closeInput', (_) {
        _socket.emit('updateScore', widget.data['roomName']);
        setState(() {
          isTextInputReadOnly = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    void selectColor() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                String colorString = color.toString();
                String valueString = colorString.split('(0x')[1].split(')')[0];
                print(colorString);
                print(valueString);
                Map map = {'color': valueString, 'roomName': dataOfRoom!['roomName']};
                _socket.emit('color-change', map);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: PlayerScore(userData: scoreboard),
      body: dataOfRoom != null
          ? dataOfRoom!['isJoined'] != true
              ? !isShowFinalLeaderboard
                  ? Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: width,
                              height: height * 0.55,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  print(details.localPosition);
                                  _socket.emit('paint', {
                                    'details': {
                                      'dx': details.localPosition.dx,
                                      'dy': details.localPosition.dy,
                                    },
                                    'roomName': widget.data['roomName'],
                                  });
                                },
                                onPanStart: (details) {
                                  print(details.localPosition);
                                  _socket.emit('paint', {
                                    'details': {
                                      'dx': details.localPosition.dx,
                                      'dy': details.localPosition.dy,
                                    },
                                    'roomName': widget.data['roomName'],
                                  });
                                },
                                onPanEnd: (details) {
                                  print(details.velocity);
                                  _socket.emit('paint', {
                                    'details': null,
                                    'roomName': widget.data['roomName'],
                                  });
                                },
                                child: SizedBox.expand(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: MyCustomPinter(pointList: points),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(onPressed: () => selectColor(), icon: Icon(Icons.color_lens, color: selectedColor)),
                                Expanded(
                                  child: Slider(
                                    min: 1.0,
                                    max: 10,
                                    label: "Stroke width $strokeWidth",
                                    activeColor: selectedColor,
                                    value: strokeWidth,
                                    onChanged: (double value) {
                                      Map map = {'value': value, 'roomName': dataOfRoom!['roomName']};
                                      _socket.emit('stroke-width', map);
                                    },
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _socket.emit('clean-screen', dataOfRoom!['roomName']);
                                  },
                                  icon: Icon(Icons.layers_clear, color: selectedColor),
                                ),
                              ],
                            ),
                            dataOfRoom!['turn']['nickname'] != widget.data['nickname']
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: textBlankWidget,
                                  )
                                : Center(child: Text(dataOfRoom!['word'], style: const TextStyle(fontSize: 30))),
                            SizedBox(
                              height: height * 0.3,
                              child: ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  var msg = messages[index].values;
                                  return ListTile(
                                    title: Text(
                                      msg.elementAt(0),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      msg.elementAt(1),
                                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        dataOfRoom!['turn']['nickname'] != widget.data['nickname']
                            ? Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  child: TextField(
                                    readOnly: isTextInputReadOnly,
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        Map map = {
                                          'username': widget.data['nickname'],
                                          'msg': value.trim(),
                                          'word': dataOfRoom!['word'],
                                          'roomName': widget.data['roomName'],
                                          'guessedUserCtr': guessedUserCtr,
                                          'totalTime': 60,
                                          'timeTaken': 60 - _start
                                        };
                                        _socket.emit('msg', map);
                                        _controller.clear();
                                      }
                                    },
                                    autocorrect: false,
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.transparent),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.transparent),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      filled: true,
                                      fillColor: const Color(0xFFF5F5FA),
                                      hintText: 'Your Guess',
                                      hintStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),
                              )
                            : Container(),
                        SafeArea(
                          child: IconButton(
                            onPressed: () => scaffoldKey.currentState!.openDrawer(),
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                  : FinalLeaderboard(
                      winner: winner,
                      scoreboard: scoreboard,
                    )
              : WaitingLobbyScreen(
                  occupancy: dataOfRoom!['occupancy'],
                  noOfPlayers: dataOfRoom!['players'].length,
                  lobbyName: dataOfRoom!['roomName'],
                  players: dataOfRoom!['players'],
                )
          : const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: () {},
          elevation: 7,
          backgroundColor: Colors.white,
          child: Text(
            '$_start',
            style: const TextStyle(color: Colors.black, fontSize: 22),
          ),
        ),
      ),
    );
  }
}
