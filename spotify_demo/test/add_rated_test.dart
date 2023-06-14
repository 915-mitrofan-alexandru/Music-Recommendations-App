import 'package:spotify_demo/firebase_services.dart';
import 'package:test/test.dart';

void main() {
  test('rated song should be added to the ratedSongs list', () {
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
