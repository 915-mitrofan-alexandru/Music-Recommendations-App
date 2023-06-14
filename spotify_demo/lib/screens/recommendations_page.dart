import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spotify_demo/components/rating_dialog.dart';
import 'package:spotify_demo/screens/profilepage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase_services.dart';
import 'log_in_screen.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({Key? key}) : super(key: key);

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late CardItem crt_item;

  @override
  initState() {
    super.initState();
    Firebase.initializeApp().whenComplete(() {
      setState(() {});
    });
  }

  Future<void> onRefresh() async {
    await FirebaseServices.updateRecommendations();
    setState(() {
    });
  }

  int checkTime() {
    TimeOfDay now = TimeOfDay.now();
    if (now.hour >= 18 || now.hour <= 3){
      return 1;
    }
    else if (now.hour <= 12 && now.hour >= 5){
      return 2;
    }
    else {
      return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
            padding: EdgeInsets.only(top: 15, left: 15, right: 15),
            children: <Widget>[
              checkTime() == 2 ? buildRecommendationCard(
                  "Good Morning!", "Songs to get you energised", Colors.blue, FirebaseServices.morningRecommendations) : Container(),
              checkTime() == 1 ? buildRecommendationCard("Good Evening!",
                  "Songs to get you ready for sleep", Colors.indigo, FirebaseServices.eveningRecommendations) : Container(),
              FirebaseServices.friendRecommendations.isNotEmpty ? buildRecommendationCard(
                  "From Your Friends",
                  "Songs your friends listened to that you might like",
                  Colors.teal, FirebaseServices.friendRecommendations) : Container(),
              buildRecommendationCard(
                  "Your Genres",
                  "Songs recommended for your genre preferences",
                  Colors.indigoAccent, FirebaseServices.normalRecommendations),
              buildRecommendationCard(
                  "Discover", "Less known songs you might like", Colors.brown, FirebaseServices.discoverRecommendations),
            ]));
  }

  Widget buildCard({required CardSong item}) => ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SongBlock(MediaQuery.of(context).size, item));

  Padding SongBlock(Size size, CardSong item) {
    return Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: InkWell(
            onTap: () async {
              final Uri url = Uri.parse(item.uri);
              if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
              }
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 0),
              height: size.height * 0.09,
              width: size.width,
              decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              child: Stack(children: <Widget>[
                Container(
                  width: size.width * 20,
                ),
                Positioned(
                    child: Image.network(item.image, fit: BoxFit.scaleDown)),
                Positioned(
                    top: size.height * 0.05,
                    left: size.width * 0.23,
                    right: size.width * 0.05,
                    child: Container(
                        margin: const EdgeInsets.symmetric(),
                        child: buildTitleData(item.title) // song title
                        )),
                Positioned(
                    top: size.height * 0.025,
                    left: size.width * 0.23,
                    right: size.width * 0.05,
                    child: Container(
                        margin: const EdgeInsets.symmetric(),
                        child: buildArtistData(item.artist) // song artist
                        ))
              ]),
            )));
  }

  Future<String?> openDialog(String text) => showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text("Alert Dialog"),
              content: Text(text),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text("Ok"),
                )
              ]));

  Text buildArtistData(String artist) {
    return Text(
      artist,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.normal, color: Colors.white),
    );
  }

  Future<String?> openRatingDialog() => showDialog<String>(
      context: context, builder: (context) => RatingDialog());

  Text buildTitleData(String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Padding buildRecommendationCard(
      String title, String subtitle, Color color, List<CardSong> lst) {
    return Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
                //height: MediaQuery.of(context).size.height,
                color: color,
                child: Column(children: <Widget>[
                  buildCardTitle(title, subtitle),
                  ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 10),
                    itemCount: lst.length,
                    itemBuilder: (context, index) =>
                        buildCard(item: lst[index]),
                  )
                ]))));
  }

  Padding buildCardTitle(String title, String subtitle) {
    return Padding(
        padding: const EdgeInsets.only(top: 20, left: 20),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ])));
  }
}
