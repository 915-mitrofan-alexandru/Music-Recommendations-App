// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotify_demo/components/rating_dialog.dart';
import 'package:spotify_demo/firebase_services.dart';

import 'package:spotify_demo/main.dart';
import 'package:spotify_demo/screens/profilepage.dart';

void main() {
  // widget testing
  testWidgets('Title widget has the correct text ', (tester) async {
    await tester.pumpWidget(const TitleWithCustomText(text: 'test_title',));
    final titleFinder = find.text('test_title');
    expect(titleFinder, findsOneWidget);
  });

  // unit testing
  test('Rated song is added to the ratedSongs list', () {
    FirebaseServices.userData = {};
    FirebaseServices.userData['rated'] = [
      {
        'title': 'title_test',
        'artist': 'artist_test',
        'id': 'id_test',
        'image': 'image_test',
        'song': 'song_test',
        'rating': 'rating_test',
        'uri': 'uri_test'
      }
    ];
    expect(FirebaseServices.ratedSongs, []);
    FirebaseServices.addRatedSongs();
    expect(FirebaseServices.ratedSongs[0].title, 'title_test');
  });
}
