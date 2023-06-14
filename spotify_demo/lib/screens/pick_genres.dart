import 'package:chips_choice_null_safety/chips_choice_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:spotify_demo/components/multi_select_chip.dart';
import 'dart:async';
import 'package:spotify_demo/screens/main_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spotify_demo/firebase_services.dart';

class PickGenresPage extends StatefulWidget {
  @override
  _PickGenresPageState createState() => _PickGenresPageState();
}

class _PickGenresPageState extends State<PickGenresPage> {
  int tag = 1;
  List<String> tags = [];
  List<String> options = [
    "Pop",
    "Dance",
    "Rock",
    "Hip Hop",
    "Country",
    "Indie",
    "Alt",
    "Metal",
    "Jazz",
    "Electronic",
    "House",
    "Rnb",
    "Soul",
    "Classical",
    "Reggae",
    "Latino",
    "Reggaeton",
    "Kpop"
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
                floatingActionButton: FloatingActionButton(
                  onPressed: () async {
                    await _setGenres(tags.join(","));
                  },
                  backgroundColor: Colors.lightBlue,
                  child: const Icon(Icons.navigate_next),
                ),
                backgroundColor: Colors.blueGrey,
                body: Padding(
                  padding: EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                          color: Colors.white,
                          child:Padding(
                          padding: const EdgeInsets.only(
                              top: 120, left: 30, bottom: 50, right: 30),
                          child:  Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const <Widget>[
                                    Text(
                                      "Pick Prefered Genres",
                                      style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    Text(
                                      "This will help us understand your music interests better",
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.black),
                                    ),
                                  ])))),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 30, left: 5, right: 5),
                    child:ChipsChoice<String>.multiple(
                        value: tags,
                        onChanged: (val) => setState(() {
                          tags = val;
                        }),
                        choiceItems: C2Choice.listFrom(
                            source: options,
                            value: (i, v) => v,
                            label: (i, v) => v),
                        choiceActiveStyle: const C2ChoiceStyle(
                            color: Colors.black,
                            backgroundColor: Colors.lightBlueAccent,
                            labelStyle: TextStyle(fontSize: 20),
                            borderColor: Colors.black,
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        choiceStyle: const C2ChoiceStyle(
                            color: Colors.black,
                            labelStyle: TextStyle(fontSize: 20),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                        wrapped: true,
                      )
                  )],
                  ),
                ))),
      ],
    );
  }

  Future<void> _setGenres(String genres) async {
    try {
      await FirebaseServices.setGenres(FirebaseServices.userData["id"], genres);
      // Change the variable status.
      setState(() {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
