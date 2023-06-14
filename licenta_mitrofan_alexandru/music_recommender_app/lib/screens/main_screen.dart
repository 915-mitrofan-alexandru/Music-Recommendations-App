import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:spotify_demo/firebase_services.dart';
import 'package:spotify_demo/screens/rated_songs.dart';
import 'package:spotify_demo/screens/loading_page.dart';
import 'package:spotify_demo/screens/log_in_screen.dart';
import 'package:spotify_demo/screens/profilepage.dart';
import 'package:spotify_demo/screens/recommendations_page.dart';
import 'package:restart_app/restart_app.dart';

int _selectedIndex = 0;
bool _loading = true;

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late FirebaseFirestore database = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  _loadUser() async {
    await FirebaseServices.logInWithRefreshToken();
    setState(() {
      _loading = false;
    });
  }

  void nagivateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    ProfilePage(),
    RecommendationsPage(),
    RatedSongsPage(),
  ];

  final List<String> _pageTitles = [
    "Your Profile",
    "Song Recommendations",
    "Your Rated Songs"
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: 400.0,
              height: 800.0,
              child: Stack(
                children: <Widget>[
                  WillPopScope(
                      onWillPop: () async => false,
                      child: Scaffold(
                        resizeToAvoidBottomInset: false,
                        bottomNavigationBar: Container(
                          color: Colors.black,
                          child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: GNav(
                                  backgroundColor: Colors.black,
                                  color: Colors.white,
                                  activeColor: Colors.white,
                                  tabBackgroundColor: Colors.grey.shade700,
                                  gap: 8,
                                  onTabChange: (index) {
                                    nagivateBottomBar(index);
                                  },
                                  padding: EdgeInsets.all(16),
                                  tabs: const [
                                    GButton(
                                        icon: Icons.account_circle_rounded,
                                        text: 'Profile'),
                                    GButton(
                                        icon: Icons.music_note_rounded,
                                        text: 'Recommendations'),
                                    GButton(
                                        icon: Icons.star, text: 'Rated Songs'),
                                  ])),
                        ),
                        backgroundColor: Colors.blueGrey,
                        appBar: buildAppBar(),
                        body: _loading ? LoadingPage() : _pages[_selectedIndex],
                      )),
                ],
              ),
            ));
  }

  AppBar buildAppBar() {
    return AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        leading: IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: logOutDialog),
        title: Align(
          alignment: Alignment.centerRight,
            child: Text(_loading ? "Loading..." : _pageTitles[_selectedIndex]),
        ));
  }

  Future<String?> logOutDialog() => showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text("Do you wish to log out of your account?"),
              actions: [
                TextButton(
                  onPressed: () {
                    LogInPage.logOutOfController();
                    FirebaseServices.logOut();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogInPage()),
                    );
                  },
                  child: const Text("Yes"),
                ),
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text("Cancel"),
                )
              ]));
}
