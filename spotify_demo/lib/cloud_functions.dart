import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudFunctions {
  static const authFunctionUrl = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/makeCustomToken'; //ex https://us-central1-signuptest-beb58.cloudfunctions.net/makeCustomToken
  static const addUserFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/addToUsers';
  static const addSongFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/addToSongs';
  static const sendRequestFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/addRequest';
  static const updateUserFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/updateUser';
  static const getCrtUserFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/getCrtUser';
  static const addRatingFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/addRating';
  static const logInSpotifyFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/logInSpotify';
  static const getUserDataSpotifyFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/getUserDataSpotify';
  static const getCrtPlayingSpotifyFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/getCrtPlayingSpotify';
  static const logInWithRefreshTokenSpotifyFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/logInWithRefreshTokenSpotify';
  static const changeRatingFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/changeRating';
  static const getRecommendationsFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/getUserRecommendations';
  static const setGenresFunction = 'https://us-central1-spotify-demo-43549.cloudfunctions.net/setGenres';

  static Future<dynamic> logInSpotify(String code) async {
    http.Response response = await http.post(
        Uri.parse('$logInSpotifyFunction?code=$code'));
    return json.decode(response.body)['data'];
  }

  static Future<dynamic> logInWithRefreshTokenSpotify(String refreshToken) async {
    http.Response response = await http.post(
        Uri.parse('$logInWithRefreshTokenSpotifyFunction?refresh_token=$refreshToken'));
    return json.decode(response.body)['data'];
  }

  static Future<dynamic> getUserDataSpotify(String accessToken) async {
    http.Response response = await http.get(
        Uri.parse('$getUserDataSpotifyFunction?access_token=$accessToken'));
    return json.decode(response.body)['data'];
  }

  static Future<dynamic> getUserRecommendations(String id) async {
    return await http.get(
        Uri.parse('$getRecommendationsFunction?id=$id'));
  }


  static Future<dynamic> getCrtPlayingSpotify(String accessToken) async {
    http.Response response = await http.get(
        Uri.parse('$getCrtPlayingSpotifyFunction?access_token=$accessToken'));
    return json.decode(response.body)['data'];
  }

  static Future<dynamic> customUserAuth(String id) async {
    http.Response response = await http.get(
        Uri.parse('$authFunctionUrl?spotifyToken=$id'));
    return json.decode(response.body)['customToken'];
  }

  static Future<void> setGenres(String id, String genres) async {
    await http.get(
        Uri.parse('$setGenresFunction?id=$id&genres=$genres'));
  }

  static Future<dynamic> addUser(dynamic userDataResponse, String song, String access_token, String refresh_token) async{
    var body ={
      'display_name': userDataResponse['display_name'],
      'country': userDataResponse['country'],
      'id': userDataResponse['id'],
      'access_token': access_token,
      'song': song,
      'refresh_token': refresh_token,
      'pfp_url': "none",
    };
    final jsonString = json.encode(body);
    final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    http.Response response = await http.post(Uri.parse(addUserFunction), headers: headers, body: jsonString);
    return response;
  }

  static Future<dynamic> updateUser(dynamic id, String song) async {
    http.Response response = await http.get(
        Uri.parse('$updateUserFunction?id=$id&song=$song'));
    return response;
  }

  static Future<dynamic> addSong(dynamic body) async {
      final jsonString = json.encode(body);
      final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
      await http.post(Uri.parse(addSongFunction), headers: headers, body: jsonString);
  }

  static Future<dynamic> getCrtUser(dynamic crtId) async {
    http.Response response = await http.get(
        Uri.parse('$getCrtUserFunction?id=$crtId'));
    return json.decode(response.body)['data'];
  }

  static Future<dynamic> addRating(dynamic body) async {
    final jsonString = json.encode(body);
    final headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    http.Response response = await http.post(Uri.parse(addRatingFunction), headers: headers, body: jsonString);
    return json.decode(response.body)["answer"];
  }

  static Future<dynamic> changeRating(String value, String id) async {
    http.Response response = await http.get(
        Uri.parse('$changeRatingFunction?id=$id&value=$value'));
    print(response.body);
    return json.decode(response.body)["answer"];
  }

}