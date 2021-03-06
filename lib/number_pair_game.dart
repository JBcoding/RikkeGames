import 'dart:math';

import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:jiggle/jiggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NumberPairGameTypes {
  tenGame,
  twinGame,
}


class NumberPairGame extends StatefulWidget {
  const NumberPairGame({Key? key, required this.type}) : super(key: key);

  final NumberPairGameTypes type;

  @override
  State<NumberPairGame> createState() => _NumberPairGameState(this.type);
}

class NumberTwinsBoardElement {
  int value = 0;
  String showValue = "";
  bool used = false;
  final JiggleController jiggleControllerCompletionAnimation = JiggleController();
  final JiggleController jiggleControllerErrorAnimation = JiggleController();

  NumberTwinsBoardElement(this.value, this.showValue);

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

class _NumberPairGameState extends State<NumberPairGame> with SingleTickerProviderStateMixin {
  List<List<NumberTwinsBoardElement>> board = List.empty();
  NumberTwinsBoardElement? selectedElement;
  int points = 0;
  int lastPairTime = 0;
  bool hasFirstMoveBeenMade = false;
  SharedPreferences? prefs;
  final JiggleController celebrationJiggleController = JiggleController();

  bool celebrationRunning = false;
  late final AnimationController _offsetCelebrationController = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  );
  late final Animation<Offset> _offsetCelebrationAnimation = Tween<Offset>(
    begin: const Offset(0.0, -2.5),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _offsetCelebrationController,
    curve: Curves.decelerate,
  ));

  late String title;
  late String description;
  late String highScoreKey;
  late double pieceWidth;

  _NumberPairGameState(NumberPairGameTypes type) {
    if (type == NumberPairGameTypes.tenGame) {
      title = "Matematik - 10'er venner - Et spil af Rikke Bj??rn";
      description = "Find 10'er venner! Kan du sl?? din rekord?";
      highScoreKey = "number_10_high_score";
      pieceWidth = 55;
    } else {
      title = "Matematik - Tvillingetal - Et spil af Rikke Bj??rn";
      description = "Find tvillingetal! Kan du sl?? din rekord?";
      highScoreKey = "number_twin_high_score";
      pieceWidth = 130;
    }
    _setupPrefs();
    _setupGame(type);
  }

  Future<void> _setupPrefs() async {
    SharedPreferences newPrefs = await SharedPreferences.getInstance();
    setState(() {
      prefs = newPrefs;
    });
  }

  String _getTwinGameShowString(int value) {
    if (value > 0) {
      return (value - 100).toString() + " + " + (value - 100).toString();
    } else {
      return "= " + ((-value + 10 - 100) * 2).toString();
    }
  }

  void _setupGame(NumberPairGameTypes type) {
    for (var column in board) {
      for (var element in column) {
        element.jiggleControllerErrorAnimation.dispose();
        element.jiggleControllerCompletionAnimation.dispose();
      }
    }
    if (type == NumberPairGameTypes.tenGame) {
      List<int> numbers = List.generate(6 * 3, (index) => Random().nextInt(9) + 1);
      numbers.addAll(List.generate(numbers.length, (index) => 10 - numbers[index]));
      numbers.shuffle();
      board = List.generate(6, (i) =>
          List.generate(6, (j) => NumberTwinsBoardElement(numbers[i * 6 + j], numbers[i * 6 + j].toString())));
    } else {
      List<int> numbers = List.generate(6 * 3, (index) => Random().nextInt(9) + 1 + 100);
      numbers.addAll(List.generate(numbers.length, (index) => - numbers[index] + 10));
      numbers.shuffle();
      board = List.generate(6, (i) =>
          List.generate(6, (j) => NumberTwinsBoardElement(numbers[i * 6 + j], _getTwinGameShowString(numbers[i * 6 + j]))));
    }
    selectedElement = null;
    hasFirstMoveBeenMade = false;
    points = 0;
    lastPairTime = DateTime.now().millisecondsSinceEpoch;
    celebrationRunning = false;
    if (celebrationJiggleController.isJiggling) {
      celebrationJiggleController.toggle();
    }
  }

  void _reload() {
    setState(() {
      _setupGame(widget.type);
    });
  }

  int _calculatePoints() {
    int millisSince = DateTime.now().millisecondsSinceEpoch - lastPairTime;
    if (millisSince < 100) {
      return 12;
    } else if (millisSince < 250) {
      return 11;
    } else if (millisSince < 500) {
      return 10;
    } else if (millisSince < 750) {
      return 9;
    } else if (millisSince < 1000) {
      return 8;
    } else if (millisSince < 1500) {
      return 7;
    } else if (millisSince < 2000) {
      return 6;
    } else if (millisSince < 3000) {
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
    if (board.any((column) => column.any((el) => el == element))) {
      // If not on the board, the controller have already been disposed
      element.jiggleControllerCompletionAnimation.toggle();
    }
  }

  Future<void> _playCompletionAnimation() async {
    setState(() {
      celebrationRunning = true;
    });
    celebrationJiggleController.toggle();
    _offsetCelebrationController.reset();
    _offsetCelebrationController.animateTo(1.0);
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
        int highScore = (prefs!.getInt(highScoreKey) ?? 0);
        highScore = max(points, highScore);
        await prefs!.setInt(highScoreKey, highScore);
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
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              description,
              style: const TextStyle(fontSize: 30),
            ),
            Container(
              height: 40,
            ),
            Text(
              'Points: $points   (bedste: ${prefs?.getInt(highScoreKey) ?? 0})',
              style: const TextStyle(fontSize: 30),
            ),
            Container(
              height: 40,
            ),
            Stack(
              children: [
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
                                child: SizedBox(
                                  width: pieceWidth,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: element.getColor(selectedElement),
                                    ),
                                    child: Text(element.showValue, style: const TextStyle(fontSize: 44),),
                                    onPressed: () async {
                                      if (!hasFirstMoveBeenMade) {
                                        hasFirstMoveBeenMade = true;
                                        lastPairTime = DateTime.now().millisecondsSinceEpoch;
                                      }
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
                        ),
                    ).toList(),
                  )).toList(),
                ),
                celebrationRunning ? SlideTransition(
                  position: _offsetCelebrationAnimation,
                  child: Row(
                    mainAxisAlignment : MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Jiggle(
                        jiggleController: celebrationJiggleController,
                        extent: 20,
                        duration: const Duration(milliseconds: 800),
                        child: const Image(
                          image: AssetImage('assets/img/cheer_2.png'),
                          height: 370,
                          width: 370,
                        ),
                      ),
                    ],
                  ),
                ) : const SizedBox(width: 0, height: 0,),
                celebrationRunning ? SlideTransition(
                  position: _offsetCelebrationAnimation,
                  child: Row(
                    mainAxisAlignment : MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Transform.rotate(
                        angle: -pi / 5,
                        child: Jiggle(
                          jiggleController: celebrationJiggleController,
                          extent: 30,
                          duration: const Duration(milliseconds: 1000),
                          child: const Image(
                            image: AssetImage('assets/img/cheer_3.png'),
                            height: 370,
                            width: 370,
                          ),
                        ),
                      ),
                      Container(
                        width: 180,
                      ),
                      Transform.rotate(
                        angle: pi / 5,
                        child: Jiggle(
                          jiggleController: celebrationJiggleController,
                          extent: 30,
                          duration: const Duration(milliseconds: 1000),
                          child: const Image(
                            image: AssetImage('assets/img/cheer_1.png'),
                            height: 370,
                            width: 370,
                          ),
                        ),
                      ),
                    ],
                  )
                ): const SizedBox(width: 0, height: 0,),
              ]
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _reload,
        tooltip: 'Pr??v igen',
        child: const Icon(Icons.restart_alt),
      ),
    );
  }
}
