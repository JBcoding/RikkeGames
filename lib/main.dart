import 'package:flutter/material.dart';

import 'number_pair_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Matematik - Spil af Rikke Bjørn",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainMenu(title: "Matematik - Spil af Rikke Bjørn"),
    );
  }
}

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
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
              "Vælg det spil du vil spille!",
              style: TextStyle(fontSize: 30),
            ),
            Container(
              height: 40,
            ),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromRGBO(25, 103, 210, 1),
                ),
                child: const Text("10'er venner!", style: TextStyle(fontSize: 44),),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NumberPairGame(type: NumberPairGameTypes.tenGame,)),
                  );
                },
              ),
            ),
            Container(
              height: 5,
            ),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromRGBO(25, 103, 210, 1),
                ),
                child: const Text("Tvillingetal!", style: TextStyle(fontSize: 44),),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NumberPairGame(type: NumberPairGameTypes.twinGame,)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
