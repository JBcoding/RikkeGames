import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jiggle/controller.dart';
import 'package:jiggle/jiggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matematik - tal tvillinger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NumberTwins(title: 'Matematik - tal tvillinger (Et spil fra Rikke B)'),
    );
  }
}

class NumberTwins extends StatefulWidget {
  const NumberTwins({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<NumberTwins> createState() => _NumberTwinsState();
}

class NumberTwinsBoardElement {
  int value = 0;
  bool used = false;
  final JiggleController jiggleControllerCompletionAnimation = JiggleController();
  final JiggleController jiggleControllerErrorAnimation = JiggleController();

  NumberTwinsBoardElement(this.value);

  Color getColor(NumberTwinsBoardElement? selectedElement) {
    if (this == selectedElement) {
      return const Color.fromRGBO(0, 0, 110, 1);
    } else if (used) {
      return const Color.fromRGBO(0, 180, 0, 1);
    } else if (jiggleControllerErrorAnimation.isJiggling) {
      return const Color.fromRGBO(210, 0, 0, 1);
    }
    return const Color.fromRGBO(0, 0, 220, 1);
  }
}

class _NumberTwinsState extends State<NumberTwins> {
  List<List<NumberTwinsBoardElement>> board = List.empty();
  NumberTwinsBoardElement? selectedElement;
  int points = 0;
  int lastPairTime = 0;
  SharedPreferences? prefs;

  _NumberTwinsState() {
    _setupPrefs();
    _setupGame();
  }

  Future<void> _setupPrefs() async {
    SharedPreferences newPrefs = await SharedPreferences.getInstance();
    setState(() {
      prefs = newPrefs;
    });
  }

  void _setupGame() {
    List<int> numbers = List.generate(6 * 3, (index) => Random().nextInt(9) + 1);
    numbers.addAll(List.generate(numbers.length, (index) => 10 - numbers[index]));
    numbers.shuffle();
    board = List.generate(6, (i) => List.generate(6, (j) => NumberTwinsBoardElement(numbers[i * 6 + j])));
    selectedElement = null;
    points = 0;
    lastPairTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _reload() {
    setState(() {
      _setupGame();
    });
  }

  int _calculatePoints() {
    int millisSince = DateTime.now().millisecondsSinceEpoch - lastPairTime;
    if (millisSince < 3000) {
      return 5;
    } else if (millisSince < 5000) {
      return 4;
    } else if (millisSince < 10000) {
      return 2;
    } else if (millisSince < 20000) {
      return 2;
    }
    return 1;
  }

  NumberTwinsBoardElement _getRandomBoardElement() {
    return board[Random().nextInt(board.length)][Random().nextInt(board[0].length)];
  }

  Future<void> _turnOffToggleInTheFuture(NumberTwinsBoardElement element) async {
    await Future.delayed(const Duration(seconds: 5));
    element.jiggleControllerCompletionAnimation.toggle();
  }

  Future<void> _playCompletionAnimation() async {
    while (_isDone()) {
      NumberTwinsBoardElement element = _getRandomBoardElement();
      while (element.jiggleControllerCompletionAnimation.isJiggling) {
        element = _getRandomBoardElement();
      }
      element.jiggleControllerCompletionAnimation.toggle();
      _turnOffToggleInTheFuture(element);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  bool _isDone() {
    return board.every((column) => column.every((element) => element.used));
  }

  Future<void> _validMove(NumberTwinsBoardElement element) async {
    setState(() {
      selectedElement?.used = true;
      element.used = true;
      selectedElement = null;
      points += _calculatePoints();
      lastPairTime = DateTime.now().millisecondsSinceEpoch;
    });
    if (_isDone()) {
      if (prefs != null) {
        int highScore = (prefs!.getInt('number_twin_high_score') ?? 0);
        highScore = max(points, highScore);
        await prefs!.setInt('number_twin_high_score', highScore);
      }
      _playCompletionAnimation();
    }
  }

  Future<void> _invalidMove(NumberTwinsBoardElement element) async {
    setState(() {
      element.jiggleControllerErrorAnimation.toggle();
      selectedElement!.jiggleControllerErrorAnimation.toggle();
    });
    points -= 1;
    points = max(points, 0);
    NumberTwinsBoardElement? oldSelectedElement = selectedElement;
    selectedElement = null;
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      element.jiggleControllerErrorAnimation.toggle();
      oldSelectedElement!.jiggleControllerErrorAnimation.toggle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Vælg 2 tal så deres sum tilsammen er 10:',
              style: TextStyle(fontSize: 30),
            ),
            Container(
              height: 40,
            ),
            Text(
              'Points: $points   (bedste: ${prefs?.getInt('number_twin_high_score') ?? 0})',
              style: const TextStyle(fontSize: 30),
            ),
            Container(
              height: 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: board.map((column) => Column(
                children: column.map((element) =>
                    Jiggle(
                      jiggleController: element.jiggleControllerCompletionAnimation,
                      extent: 360,
                      duration: const Duration(milliseconds: 5000),
                      child: Jiggle(
                        jiggleController: element.jiggleControllerErrorAnimation,
                        extent: 25,
                        duration: const Duration(milliseconds: 300),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: FittedBox(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: element.getColor(selectedElement),
                              ),
                              child: Text('${element.value}', style: const TextStyle(fontSize: 44),),
                              onPressed: () async {
                                if (element.used) {
                                  return;
                                }
                                if (selectedElement == element) {
                                  setState(() {
                                    selectedElement = null;
                                  });
                                } else if (selectedElement == null) {
                                  setState(() {
                                    selectedElement = element;
                                  });
                                } else {
                                  if (element.value + selectedElement!.value == 10) {
                                    _validMove(element);
                                  } else {
                                    _invalidMove(element);
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                ).toList(),
              )).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reload,
        tooltip: 'Prøv igen',
        child: const Icon(Icons.restart_alt),
      ),
    );
  }
}
