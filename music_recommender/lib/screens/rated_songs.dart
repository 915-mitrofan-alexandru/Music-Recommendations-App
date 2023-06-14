import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spotify_demo/components/rating_dialog.dart';
import 'package:spotify_demo/screens/profilepage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase_services.dart';
import 'log_in_screen.dart';

class RatedSongsPage extends StatefulWidget {
  const RatedSongsPage({Key? key}) : super(key: key);

  @override
  State<RatedSongsPage> createState() => _RatedSongsPageState();
}

class _RatedSongsPageState extends State<RatedSongsPage> {
  late CardItem crt_item;

  @override
  initState() {
    super.initState();
    Firebase.initializeApp().whenComplete(() {
      setState(() {});
    });
  }

  Future<void> onRefresh() async {
    await FirebaseServices.updateUser();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
                padding: EdgeInsets.only(top: 20, left: 15, right: 15),
                itemCount: FirebaseServices.ratedSongs.length,
                itemBuilder: (context, index) =>
                    buildCard(
                        item: FirebaseServices.ratedSongs[index]),
              ));
  }

  Widget buildCard({required CardSong item}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SongBlock(MediaQuery.of(context).size, item)
      );

  Padding SongBlock(Size size, CardSong item) {
    return Padding(
        padding: EdgeInsets.only(bottom: 15),
        child: InkWell(
        onTap: () async {
          final Uri url = Uri.parse(item.uri);
          if (!await launchUrl(url)) {
          throw Exception('Could not launch $url');
          }
        },
        child: Container(
      margin: EdgeInsets.only(bottom: 0),
      height: size.height * 0.10,
      width: size.width,
      child: Stack(children: <Widget>[
        Container(
          height: size.height * 0.10,
          width: size.width * 20,
          decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.all(Radius.circular(15))),
        ),
        Positioned(
            child: Image.network(item.image)),
        Positioned(
            top: size.height*0.05,
            left: size.width*0.25,
            right: size.width*0.25,
            child: Container(
                margin: const EdgeInsets.symmetric(),
                child: buildTitleData(item.title) // song title
            )),
        Positioned(
            top: size.height*0.025,
            left: size.width*0.25,
            right: size.width*0.25,
            child: Container(
                margin: const EdgeInsets.symmetric(),
                child: buildArtistData(item.artist) // song artist
            )),
        Positioned(
          top: size.height*0.02,
          left: size.width*0.7,
          child: TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
              shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
            ),
            onPressed: () async {
              final rating = await openRatingDialog();
              if (rating == null || rating.isEmpty) return;
              String responseText;
                responseText = await FirebaseServices.changeRating(item.ratingId, rating);
                await openDialog(responseText);
                await FirebaseServices.updateUser();
                setState(() {});

            },
            child: Text("${item.value}/5",
                style: TextStyle(color: Colors.black)),
          ),
        ),
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
}