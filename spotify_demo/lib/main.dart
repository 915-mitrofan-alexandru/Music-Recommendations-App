import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:spotify_demo/screens/main_screen.dart';
import 'package:spotify_demo/screens/profilepage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spotify_demo/firebase_services.dart';
import 'package:spotify_demo/screens/log_in_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sign Up with Spotify',
      theme: ThemeData(
        primaryColor: Colors.black,
        //textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.black),
        visualDensity: VisualDensity.adaptivePlatformDensity
      ),
      home: FirebaseAuth.instance.currentUser != null ? MainPage() : LogInPage(),
    );
  }
}

