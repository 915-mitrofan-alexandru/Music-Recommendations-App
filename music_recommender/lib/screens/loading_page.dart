import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spotify_demo/firebase_services.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.withOpacity(0.5),
      body: const Center(child: CircularProgressIndicator(color: Colors.black)),
    );
  }
}
