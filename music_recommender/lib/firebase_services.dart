import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spotify_demo/randomiser_util.dart';
import 'package:spotify_demo/cloud_functions.dart';

import 'firebase_options.dart';

class CardItem {
  final String pfpUrl;
  final String usrId;
  final String displayName;

  const CardItem({
    required this.displayName,
    required this.usrId,
    required this.pfpUrl
  });
}

class CardSong {
  final String image;
  final String uri;
  final String title;
  final String artist;
  final String songId;
  final String ratingId;
  final String value;

  const CardSong({
    required this.image,
    required this.uri,
    required this.title,
    required this.artist,
    required this.songId,
    required this.ratingId,
    required this.value
  });
}

class FirebaseServices {

  static var userData;
  static var crtSongData;
  static var access_token = '';
  static var recommendations;
  static const genres = [
    'pop',
    'country',
    'dance',
    'electro',
    'rock',
    'indie',
    'metal',
    'alt',
    'reggae',
    'rap',
    'latin',
    'r&b'
  ];
  static var state = getRandomString(16);
  static const String appId = 'e12c282b765b42839fa392f294552d24'; //ex 202181494449441
  static const String appSecret = 'bf2218992a61497a881fa8ea7cf0441c'; //ex ec0660294c82039b12741caba60f440c
  static const String redirectUri = 'https://github.com/915-mitrofan-alexandru'; //ex https://github.com/loydkim
  String initialUrl = 'https://accounts.spotify.com/authorize?client_id=$appId&state=$state&redirect_uri=$redirectUri&scope=user-read-private user-read-email user-read-currently-playing&response_type=code&show_dialog=true';
  static const sendRequestFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/addRequest';
  static const acceptRequestFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/acceptRequest';
  static const denyRequestFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/denyRequest';

  late FirebaseFirestore database = FirebaseFirestore.instance;
  static List<CardItem> userFriends = [];
  static List<CardItem> userRequests = [];
  static List<CardSong> ratedSongs = [];
  static List<CardSong> morningRecommendations = [];
  static List<CardSong> eveningRecommendations = [];
  static List<CardSong> normalRecommendations = [];
  static List<CardSong> discoverRecommendations = [];
  static List<CardSong> friendRecommendations = [];

  static addCardItems() {
    var requests = userData['requests'];
    var friends = userData['friends'];
    if (friends == null || friends.length == 0){
      userFriends = [];
    }
    else{
      List<CardItem> friendList = [];
      friends.forEach((friend) =>
      {
        friendList.add(
            CardItem(displayName: friend["display_name"],
                usrId: friend["id"],
                pfpUrl: friend["pfp_url"])
        )
      });
      userFriends = friendList;
    }
    if (requests == null || requests.length == 0){
      userRequests = [];
    }
    else{
      List<CardItem> requestList = [];
      requests.forEach((request) =>
      {
        requestList.add(
            CardItem(displayName: request["display_name"],
                usrId: request["id"],
                pfpUrl: request["pfp_url"])
        )
      });
      userRequests = requestList;
    }
  }

  static addRatedSongs() {
    var ratings = userData['rated'];
    if (ratings == null || ratings.length == 0){
      ratedSongs = [];
    }
    else{
      List<CardSong> songList = [];
      ratings.forEach((ratedSong) =>
      {
        songList.add(
            CardSong(title: ratedSong["title"],
              artist: ratedSong["artist"],
              ratingId: ratedSong["id"],
              image: ratedSong["image"],
              songId: ratedSong["song"],
              value: ratedSong["rating"],
              uri: ratedSong["uri"])
        )
      });
      ratedSongs = songList;
    }
  }

  static List<CardSong> addToList(var lst){
    if (lst == null || lst.length == 0){
      return [];
    }
    List<CardSong> songList = [];
    lst.forEach((elem) =>
    {
      songList.add(
          CardSong(title: elem["title"],
              artist: elem["artist"],
              ratingId: "",
              image: elem["url"],
              songId: elem["id"],
              value: "",
              uri: elem["uri"])
      )
    });
    return songList;
  }

  static addRecommendedSongs() {
    friendRecommendations = addToList(recommendations["friend"]);
    discoverRecommendations = addToList(recommendations["discover"]);
    normalRecommendations = addToList(recommendations["normal"]);
    morningRecommendations = addToList(recommendations["morning"]);
    eveningRecommendations = addToList(recommendations["evening"]);
  }

  static Future<void> logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static Future<String> getGenres(String crtArtistUri) async {
    var lst = crtArtistUri.split(":");
    var crtNormalArtist = lst[lst.length - 1];
    final http.Response responseArtistData = await http.get(
      Uri.parse('https://api.spotify.com/v1/artists/$crtNormalArtist'),
      headers: {
        'Authorization': 'Bearer $access_token'
      },);
    var unfilteredGenres = json.decode(
        responseArtistData.body.toString())['genres'];
    String joined = '';
    unfilteredGenres.forEach((str) => joined = '$joined, $str');
    return joined;
  }

  static Future<dynamic> getAudioFeatures(String songId) async {
    final http.Response responseAudioFeatures = await http.get(
      Uri.parse('https://api.spotify.com/v1/audio-features/$songId'),
      headers: {
        'Authorization': 'Bearer $access_token'
      },);
    return json.decode(responseAudioFeatures.body.toString());
  }

  static Future<void> updateUser() async {
    var usrId = userData['id'];
    var responseCrtData = await CloudFunctions.getCrtPlayingSpotify(access_token);
    await addCrtPlayingSong(responseCrtData);
    print(userData);
    var updateUserRequest = await CloudFunctions.updateUser(usrId, crtSongData['crt_id']);
    userData['friends'] = json.decode(updateUserRequest.body)['friends'];
    userData['requests'] = json.decode(updateUserRequest.body)['requests'];
    userData['rated'] = json.decode(updateUserRequest.body)['rated'];
    userData['crt_rating'] = json.decode(updateUserRequest.body)['crt_rating'];
    await updateRecommendations();
    addCardItems();
    addRatedSongs();
  }

  static Future<void> updateRecommendations() async {
    var usrId = userData['id'];
    http.Response response = await CloudFunctions.getUserRecommendations(usrId);
    recommendations = json.decode(response.body);
    addRecommendedSongs();
  }

  static Future<String> sendRequest(String requestedId) async {
    var crtId = userData['id'];
    var url = '$sendRequestFunction?crt=$crtId&requested=$requestedId';
    final http.Response responseSendRequest = await http.post(
        Uri.parse(url));
    if (json.decode(responseSendRequest.body) != null) {
      return json.decode(responseSendRequest.body)["answer"];
    }
    else {
      return "internal server error";
    }
  }

  static Future<String> acceptRequest(String reqId) async {
    var crtId = userData['id'];
    var url = '$acceptRequestFunction?crt=$crtId&req=$reqId';
    final http.Response responseAcceptRequest = await http.post(
        Uri.parse(url));
    if (json.decode(responseAcceptRequest.body) != null) {
      return json.decode(responseAcceptRequest.body)["answer"];
    }
    else {
      return "internal server error";
    }
  }

  static Future<String> denyRequest(String reqId) async {
    var crtId = userData['id'];
    var url = '$denyRequestFunction?crt=$crtId&req=$reqId';
    final http.Response responseDenyRequest = await http.post(
        Uri.parse(url));
    if (json.decode(responseDenyRequest.body) != null) {
      return json.decode(responseDenyRequest.body)["answer"];
    }
    else {
      return "internal server error";
    }
  }

  static Future<dynamic> addRating(String rating) async {
    var body = {
      "user": userData['id'],
      "artist": crtSongData['crt_artist'],
      "title": crtSongData['crt_song'],
      "image": crtSongData['crt_image'],
      "uri": crtSongData['crt_uri'],
      "song": crtSongData['crt_id'],
      "rating": rating
    };
    return await CloudFunctions.addRating(body);
  }

  static Future<dynamic> changeRating(String id, String rating) async {
    return await CloudFunctions.changeRating(rating, id);
  }

  static Future<void> logInWithRefreshToken() async {
    var crtId = FirebaseAuth.instance.currentUser?.uid;

    var responseUserDatabase = await CloudFunctions.getCrtUser(crtId);

    try {
      var logInResponse = await CloudFunctions.logInWithRefreshTokenSpotify(responseUserDatabase["refresh_token"]);

      access_token = logInResponse['access_token'];
      var userDataResponse = await CloudFunctions.getUserDataSpotify(access_token);
      var songResponse = await CloudFunctions.getCrtPlayingSpotify(access_token);

      print(logInResponse['access_token']);
      var customToken = await CloudFunctions.customUserAuth(userDataResponse["id"]);
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      await addCrtPlayingSong(songResponse);
      print(logInResponse);
      var addUserResponse = await CloudFunctions.addUser(userDataResponse, crtSongData['crt_id'], access_token, responseUserDatabase["refresh_token"]);

      print(addUserResponse.body);
      userData = {
        'pfp': userDataResponse["images"].length!=0 ? userDataResponse["images"][0]['url'] : 'https://cdn.discordapp.com/attachments/1105216582495510610/1116754018409123990/no_pfp.png',
        'display_name': userDataResponse["display_name"],
        'id': userDataResponse["id"],
        'country': userDataResponse["country"],
        'friends': json.decode(addUserResponse.body)['friends'],
        'requests': json.decode(addUserResponse.body)['requests'],
        'rated': json.decode(addUserResponse.body)['rated'],
        'crt_rating': json.decode(addUserResponse.body)['crt_rating']
      };
      await updateRecommendations();
      addCardItems();
      addRatedSongs();
      // Change the variable status.
    } catch (e) {
      print(e.toString());
    }
  }

  static Future<void> addCrtPlayingSong(dynamic crtPlayingSong) async {
    var crtId = "0";
    var crtArtist = "";
    var crtTitle = "";
    var crtUrl = "";
    var crtUri = "";
    var crtPopularity = "";
    var crtYear = "";
    var crtEnergy = "";
    var crtDanceability = "";
    var crtLiveness = "";
    var crtAcousticness = "";
    var crtSpeechiness = "";
    var crtGenres = "";

    if (crtPlayingSong != "") {
      crtArtist = crtPlayingSong['item']['artists'][0]['name'];
      crtUrl = crtPlayingSong['item']['album']['images'][0]['url'];
      crtTitle = crtPlayingSong['item']['name'];
      crtId = crtPlayingSong['item']['id'];
      crtUri = crtPlayingSong['item']['uri'];
      crtGenres = await getGenres(crtPlayingSong['item']['artists'][0]['uri']);
      crtPopularity = crtPlayingSong['item']['popularity'].toString();
      var year = crtPlayingSong['item']['album']['release_date'];
      crtYear = year.split('-')[0];
      var audioFeatures = await getAudioFeatures(crtId);
      crtEnergy = (audioFeatures['energy'] * 100).toString();
      crtDanceability = (audioFeatures['danceability'] * 100).toString();
      crtLiveness = (audioFeatures['liveness'] * 100).toString();
      crtAcousticness = (audioFeatures['acousticness'] * 100).toString();
      crtSpeechiness = (audioFeatures['speechiness'] * 100).toString();
    }

    final body = {
      'title': crtTitle,
      'artist': crtArtist,
      'genres': crtGenres,
      'year': crtYear,
      'energy': crtEnergy,
      'danceability': crtDanceability,
      'liveness': crtLiveness,
      'acousticness': crtAcousticness,
      'speechiness': crtSpeechiness,
      'url': crtUrl,
      'uri': crtUri,
      'popularity': crtPopularity,
      'id': crtId
    };

    await CloudFunctions.addSong(body);

    crtSongData = {
      'crt_artist': crtArtist,
      'crt_song': crtTitle,
      'crt_uri': crtUri,
      'crt_id': crtId,
      'crt_image': crtUrl,
    };

  }
  static Future<void> setGenres(String id, String genres)async {
    await CloudFunctions.setGenres(id, genres);
  }

  static Future<void> logIn(String code) async {

    // sign into spotify with cloud function
    var logInResponse = await CloudFunctions.logInSpotify(code);
    access_token = logInResponse["access_token"];

    // get spotify user data
    var userDataResponse = await CloudFunctions.getUserDataSpotify(access_token);

    // create custom token and then log user into firebase
    var customToken = await CloudFunctions.customUserAuth(userDataResponse["id"]);
    await FirebaseAuth.instance.signInWithCustomToken(customToken);

    // get currently playing song data
    var crtPlayingResponse = await CloudFunctions.getCrtPlayingSpotify(access_token);
    await addCrtPlayingSong(crtPlayingResponse);

    // add user to database and get friends
    final http.Response responseDatabase = await CloudFunctions.addUser(userDataResponse, crtSongData['crt_id'], access_token, logInResponse["refresh_token"]);
    print(responseDatabase.body);
    userData = {
      'pfp': userDataResponse["images"].length!=0 ? userDataResponse["images"][0]['url'] : 'https://cdn.discordapp.com/attachments/1105216582495510610/1116754018409123990/no_pfp.png',
      'display_name': userDataResponse["display_name"],
      'id': userDataResponse["id"],
      'country': userDataResponse["country"],
      'friends': json.decode(responseDatabase.body)['friends'],
      'requests': json.decode(responseDatabase.body)['requests'],
      'rated': json.decode(responseDatabase.body)['rated'],
      'genres': json.decode(responseDatabase.body)['genres'],
      'crt_rating': json.decode(responseDatabase.body)['crt_rating']
    };
    await updateRecommendations();
    addCardItems();
    addRatedSongs();
  }
}