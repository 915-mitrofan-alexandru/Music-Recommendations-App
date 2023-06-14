import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spotify_demo/components/rating_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase_services.dart';
import 'log_in_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController textController;
  late CardItem crt_item;

  @override
  initState() {
    super.initState();
    textController = TextEditingController();
    Firebase.initializeApp().whenComplete(() {
      setState(() {});
    });
  }

  Future<void> onRefresh() async {
    await FirebaseServices.updateUser();
    setState(() {});
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(children: <Widget>[
          profileHeader(size),
          FirebaseServices.crtSongData['crt_id'] != "0"
              ? crtPlayingBlock(size)
              : nothingPlaying(size),
          titleWithAddFriend(),
          Container(
              height: FirebaseServices.userFriends.length == 0 ? size.height * 0.01 : size.height * 0.2,
              child: ListView.separated(
                padding: EdgeInsets.only(top: 10, left: 8),
                scrollDirection: Axis.horizontal,
                itemCount: FirebaseServices.userFriends.length,
                separatorBuilder: (context, _) => SizedBox(width: 10),
                itemBuilder: (context, index) => buildCard(
                    item: FirebaseServices.userFriends[index], isFriend: true),
              )),
          titleOfRequests(),
          Container(
              height: size.height * 0.12,
              child: ListView.separated(
                padding: EdgeInsets.only(top: 10, left: 8, bottom: 10),
                scrollDirection: Axis.horizontal,
                itemCount: FirebaseServices.userRequests.length,
                separatorBuilder: (context, _) => SizedBox(width: 10),
                itemBuilder: (context, index) => buildCard(
                    item: FirebaseServices.userRequests[index],
                    isFriend: false),
              ))
        ]));
  }

  Widget buildCard({required CardItem item, required bool isFriend}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
            onTap: !isFriend
                ? () async {
                    crt_item = item;
                    final response = await seeRequestDialog(item);
                    await openDialog(response!);
                  }
                : () {},
            child: Container(
              width: 110,
              padding: EdgeInsets.all(10),
              color: Colors.black87,
              child: Column(children: [
                isFriend
                    ? Expanded(
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                Image.network(item.pfpUrl, fit: BoxFit.cover)))
                    : const Text("see request",
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(item.displayName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(item.usrId,
                    style: TextStyle(fontSize: 12, color: Colors.grey))
              ]),
            )),
      );

  Padding titleWithAddFriend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          FirebaseServices.userFriends.isEmpty
              ? const TitleWithCustomText(text: "No friends yet")
              : const TitleWithCustomText(text: "Friends"),
          const Spacer(),
          TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
              shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
            ),
            onPressed: () async {
              final friendId = await openFriendDialog();
              if (friendId == null || friendId.isEmpty) return;
              String responseText =
                  await FirebaseServices.sendRequest(friendId);
              await openDialog(responseText);
            },
            child:
                const Text("Add Friend", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Padding titleOfRequests() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, top: 15.0, bottom: 10.0),
      child: Row(
        children: [
          FirebaseServices.userRequests.isEmpty
              ? const TitleWithCustomText(text: "No requests received yet")
              : const TitleWithCustomText(text: "Incoming Requests"),
        ],
      ),
    );
  }

  SizedBox profileHeader(Size size) {
    return SizedBox(
      height: size.height * 0.20,
      width: size.width,
      child: Stack(children: <Widget>[
        Container(
          height: size.height * 0.20 - 25,
          width: size.width,
          decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36))),
          child: buildProfilePicture(),
        ),
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                        offset: const Offset(0, 10),
                        blurRadius: 50,
                        color: Colors.black.withOpacity(0.23))
                  ]),
              child: Column(children: [
                Container(
                    margin: const EdgeInsets.symmetric(),
                    child: buildUserData()),
                Container(
                    margin: const EdgeInsets.symmetric(), child: buildUserID()),
              ]),
            ))
      ]),
    );
  }

  Future<String?> seeRequestDialog(CardItem item) => showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text("Incoming Request from ${item.displayName}"),
              content: const Text("Accept request?"),
              actions: [
                TextButton(
                  onPressed: acceptRequest,
                  child: const Text("Accept"),
                ),
                TextButton(
                  onPressed: denyRequest,
                  child: const Text("Deny"),
                )
              ]));

  Container crtPlayingBlock(Size size) {
    return Container(
      margin: const EdgeInsets.only(top: 25, left: 10, right: 10, bottom: 10),
      height: size.height * 0.15,
      width: size.width,
      child: Stack(children: <Widget>[
        Container(
          height: size.height * 0.15,
          width: size.width * 20,
          decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
      Positioned(
            left: 10,
            right: 260,
            top: 20,
            bottom: 20,
            child: InkWell(
                onTap: () async {
                  final Uri url = Uri.parse(FirebaseServices.crtSongData['crt_uri']);
                  if (!await launchUrl(url)) {
                    throw Exception('Could not launch $url');
                  }
                },
                child: Image.network(FirebaseServices.crtSongData["crt_image"]))),
        Positioned(
            left: 275,
            right: 5,
            top: 5,
            bottom: 70,
            child: Image.asset("assets/images/ezgif-4-482924aef2.gif")),
        Positioned(
            bottom: 0,
            top: 80,
            left: 120,
            right: 100,
            child: Container(
                margin: const EdgeInsets.symmetric(),
                child: buildTitleData() // song title
                )),
        Positioned(
            bottom: 20,
            top: 60,
            left: 120,
            right: 100,
            child: Container(
                margin: const EdgeInsets.symmetric(),
                child: buildArtistData() // song artist
                )),
        Positioned(
            bottom: 20,
            top: 20,
            left: 120,
            right: 0,
            child: Container(
                margin: const EdgeInsets.symmetric(),
                child: buildCrtPlaying() // song artist
                )),
        Positioned(
          left: 290,
          top: 60,
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
              if (FirebaseServices.userData['crt_rating'] == null || FirebaseServices.userData['crt_rating']['id'] == '') {
                responseText = await FirebaseServices.addRating(rating);
                await openDialog(responseText);
                await FirebaseServices.updateUser();
                setState(() {});
              } else {
                responseText = await FirebaseServices.changeRating(FirebaseServices.userData['crt_rating']['id'], rating);
                await openDialog(responseText);
                await FirebaseServices.updateUser();
                setState(() {});
              }
            },
            child: FirebaseServices.userData['crt_rating'] == null || FirebaseServices.userData['crt_rating']['id'] == ''
                ? const Text("Rate", style: TextStyle(color: Colors.black))
                : Text("${FirebaseServices.userData['crt_rating']['rating']}/5",
                    style: TextStyle(color: Colors.black)),
          ),
        ),
      ]),
    );
  }

  Container nothingPlaying(Size size) {
    return Container(
      margin: const EdgeInsets.only(top: 25, left: 10, right: 10, bottom: 10),
      height: size.height * 0.05,
      width: size.width,
      child: Stack(children: <Widget>[
        Container(
          height: size.height * 0.05,
          width: size.width * 20,
          decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
        Center(
            child: Container(
                margin: const EdgeInsets.symmetric(),
                child: noCrtPlaying() // song artist
                )),
      ]),
    );
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

  Padding buildLogOutButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: ElevatedButton(
          onPressed: () => setState(() => {_logOut()}),
          child: const Text(
            'Log out',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Future<String?> openFriendDialog() => showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text("Add Friend"),
              content: TextField(
                autofocus: true,
                decoration:
                    const InputDecoration(hintText: 'Enter Your Friend\'s ID'),
                controller: textController,
              ),
              actions: [
                TextButton(
                  onPressed: submit,
                  child: const Text("Add"),
                ),
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text("Cancel"),
                )
              ]));

  Future<String?> openRatingDialog() => showDialog<String>(
      context: context, builder: (context) => RatingDialog());

  Future<void> submit() async {
    Navigator.of(context).pop(textController.text);
    await FirebaseServices.updateUser();
  }

  Future<void> acceptRequest() async {
    var response = await FirebaseServices.acceptRequest(crt_item.usrId);
    Navigator.of(context).pop(response);
    await FirebaseServices.updateUser();
  }

  Future<void> denyRequest() async {
    var response = await FirebaseServices.denyRequest(crt_item.usrId);
    Navigator.of(context).pop(response);
    await FirebaseServices.updateUser();
  }

  Center buildUserData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          '${FirebaseServices.userData['display_name']}',
          style: const TextStyle(
              fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  Center buildUserID() {
    return Center(
      child: Text(
        'ID: ${FirebaseServices.userData['id']}',
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Text buildCrtPlaying() {
    return const Text(
      'CURRENTLY PLAYING',
      style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    );
  }

  Text noCrtPlaying() {
    return const Text(
      'NO SONG CURRENTLY PLAYING',
      style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    );
  }

  Text buildTitleData() {
    return Text(
      '${FirebaseServices.crtSongData["crt_song"]}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Text buildArtistData() {
    return Text(
      '${FirebaseServices.crtSongData["crt_artist"]}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.normal, color: Colors.white),
    );
  }

  Padding buildProfilePicture() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 40, top: 5),
        child: CircleAvatar(
            radius: 15,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              backgroundImage: NetworkImage(FirebaseServices.userData['pfp']),
              radius: 42,
            )));
  }

  Padding buildCountry() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 40, top: 5),
        child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                  "https://raw.githubusercontent.com/lipis/flag-icons/7136fa0b8feec48db39cc1b49777c518426a0704/flags/1x1/${FirebaseServices.userData["country"].toString().toLowerCase()}.svg"),
              radius: 60,
            )));
  }

  Future<void> _logOut() async {
    LogInPage.logOutOfController();
    FirebaseServices.logOut;
    setState(() => {
          Navigator.pop(
            context,
          )
        });
  }
}

class TitleWithCustomText extends StatelessWidget {
  const TitleWithCustomText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 24,
        child: Stack(
          alignment: Alignment.center,
            children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              text,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.only(right: 5),
              height: 7,
              color: Colors.black.withOpacity(0.2),
            ),
          )
        ]));
  }
}
