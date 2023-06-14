import 'package:flutter/material.dart';
import 'dart:async';
import 'package:spotify_demo/screens/main_screen.dart';
import 'package:spotify_demo/screens/pick_genres.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spotify_demo/firebase_services.dart';

WebViewController controller = WebViewController();
int _stackIndex = 1;
var initUrl = FirebaseServices().initialUrl;

class LogInPage extends StatefulWidget {
  @override
  _LogInPageState createState() => _LogInPageState();

  static Future<void> logOutOfController() async {
    _stackIndex = 1;
    controller.loadRequest(Uri.parse('https://accounts.spotify.com/en/logout'));
    _stackIndex = 0;
    controller.loadRequest(Uri.parse(initUrl));
  }
}

class _LogInPageState extends State<LogInPage> {
  // Your Instagram config information in facebook developer site.
  // Variable for UI.
  bool _showSpotifySingUpWeb = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().whenComplete(() {
      print("completed");
      setState(() {});
    });
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
        if (request.url.startsWith(FirebaseServices.redirectUri)) {
          if (request.url.contains('error')) print('the url error');
          var startIndex = request.url.indexOf('code=');
          var endIndex = request.url.lastIndexOf('&');
          print(request.url);
          print(endIndex);
          print(startIndex);
          var code = request.url.substring(startIndex + 5, endIndex);
          print(request.url);
          print(code);
          setState(() => _stackIndex = 2);
          await _logIn(code);
          print("it logged in");
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      }, onPageStarted: (url) {
        print("Page started $url");
      }, onProgress: (int progress) {
        print("progressing");
      }, onPageFinished: (url) {
        setState(() => _stackIndex = 0);
        if (url.startsWith(FirebaseServices.redirectUri)) {
          setState(() => _stackIndex = 2);
        }
        if (url.startsWith(initUrl)) {
          setState(() => _stackIndex = 0);
        }
      }));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              backgroundColor: Colors.blueGrey,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                          onTap: () {
                            setState(() => _showSpotifySingUpWeb = true);
                          },
                          child: Container(
                              width: 220,
                              height: 220,
                              child: Image.asset(
                                  'assets/images/spotify_logo.png'))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                          ),
                          onPressed: () => setState(() => {
                                _stackIndex = 1,
                                controller.clearCache(),
                                controller.clearLocalStorage(),
                                _showSpotifySingUpWeb = true,
                                controller.loadRequest(Uri.parse(initUrl)),
                              }),
                          child: const Text(
                            'Log In With Spotify',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
        _showSpotifySingUpWeb
            ? Positioned(
                child: Scaffold(
                  backgroundColor: Colors.blueGrey,
                  body: IndexedStack(
                    index: _stackIndex,
                    children: <Widget>[
                      WebViewWidget(controller: controller),
                      // index 0
                      const Center(
                          child: Text('Loading open web page ...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)),
                      // index 1
                      const Center(child: Text('Logging in ...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))
                      // index 2
                    ],
                  ),
                ),
              )
            : Container()
      ],
    );
  }

  Future<void> _logIn(String code) async {
    setState(() => _stackIndex = 2);
    try {
      await FirebaseServices.logIn(code);
      if (FirebaseServices.userData["genres"].length == 0) {
        setState(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PickGenresPage()),
          );
        });
      } else {
        setState(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
