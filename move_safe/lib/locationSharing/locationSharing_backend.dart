import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// location service class that handles all location sharing functionality:
// getting current deivce location
// saving and retrieving suer locations from firebase
// test users for developement
// calculating distances between users using the app
class LocationSharingService {
  // reference the firebase realtime database to store user locations
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref(
    'user_locations',
  );
  // firebase auth insrance for user authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // this is here for hardcoded test users for the system
  // unique id, name, email, base
  final List<Map<String, dynamic>> _testUsers = [
    {
      'id': 'test_user_1',
      'name': 'Clementine John',
      'email': 'clementine.john@example.com',
      // johannesburg base coordinates
      'latitude': -26.2041,
      'longitude': 28.0473,
      'offset_lat': 0.0015,
      'offset_lng': 0.0012,
    },
    {
      'id': 'test_user_2',
      'name': 'Amy Edward',
      'email': 'amy.edward@example.com',
      'latitude': -26.2041,
      'longitude': 28.0473,
      'offset_lat': -0.0018,
      'offset_lng': 0.0009,
    },
    {
      'id': 'test_user_3',
      'name': 'Marriot Ray',
      'email': 'marriot.ray@example.com',
      'latitude': -26.2041,
      'longitude': 28.0473,
      'offset_lat': 0.0007,
      'offset_lng': -0.0021,
    },
  ];

  // get the devices current location after user accepts permissions
  // this will return the position object, or null if permissions were denied
  Future<Position?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services disabled');
      }

      // check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      // handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      // get current user position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      rethrow;
    }
  }

  // create a coninuous strem of position updates
  Stream<Position> getLocationUpdates() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        // update every 5 meters
        distanceFilter: 5,
      ),
    );
  }

  // save the users current location to firebase
  Future<void> saveUserLocation(Position position) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // set display name if the user doesnt have one
      String userName = user.displayName ?? 'Anonymous';
      if (userName == 'Anonymous' || userName.trim().isEmpty) {
        // use email prefix
        userName =
            user.email?.split('@')[0] ?? 'User${user.uid.substring(0, 6)}';

        // update the users profile with display name
        await user.updateDisplayName(userName);
      }

      // save user data and location to firebase
      await _dbRef.child(user.uid).set({
        'userId': user.uid,
        'name': userName,
        'email': user.email,
        'latitude': position.latitude,
        'longitude': position.longitude,
        // firebase server timestamp
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      rethrow;
    }
  }

  // stream of nearby people within a certain radius
  // it will return a sorted list (nearest first)
  Stream<List<Map<String, dynamic>>> getNearbyPeopleStream(Position center) {
    return _dbRef.onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      final List<Map<String, dynamic>> results = [];

      // johannesburg center coordinates
      const double johannesburgLat = -26.2041;
      const double johannesburgLng = 28.0473;

      final johannesburgCenter = Position(
        latitude: -26.2041,
        longitude: 28.0473,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      for (final testUser in _testUsers) {
        final testLat = johannesburgCenter.latitude + testUser['offset_lat'];
        final testLng = johannesburgCenter.longitude + testUser['offset_lng'];

        // calculate distance from Johannesburg center point
        final distance = Geolocator.distanceBetween(
          johannesburgCenter.latitude,
          johannesburgCenter.longitude,
          testLat,
          testLng,
        );

        // only include if within 1km radius
        if (distance <= 1000) {
          results.add({
            'id': testUser['id'],
            'name': testUser['name'],
            'distance': distance < 1000
                ? '${distance.round()} m'
                : '${(distance / 1000).toStringAsFixed(1)} km',
            'latitude': testLat,
            'longitude': testLng,
          });
        }
      }

      if (data != null) {
        data.forEach((userId, userData) {
          if (userId == _auth.currentUser?.uid) return;

          // skip test users to avoid duplicates
          if (_testUsers.any((test) => test['id'] == userId)) return;

          final user = Map<String, dynamic>.from(userData as Map);

          if (user['name'] == null ||
              user['name'] == 'Anonymous' ||
              user['name'].toString().trim().isEmpty) {
            return;
          }

          // calculate distance from Johannesburg center point
          final distance = Geolocator.distanceBetween(
            johannesburgLat,
            johannesburgLng,
            user['latitude'],
            user['longitude'],
          );

          if (distance <= 1000) {
            results.add({
              'id': userId,
              'name': user['name'],
              'distance': distance < 1000
                  ? '${distance.round()} m'
                  : '${(distance / 1000).toStringAsFixed(1)} km',
              'latitude': user['latitude'],
              'longitude': user['longitude'],
            });
          }
        });
      }

      // sort by distance
      results.sort((a, b) {
        final distA = a['distance'].contains('km')
            ? double.parse(a['distance'].replaceAll(' km', '')) * 1000
            : double.parse(a['distance'].replaceAll(' m', ''));
        final distB = b['distance'].contains('km')
            ? double.parse(b['distance'].replaceAll(' km', '')) * 1000
            : double.parse(b['distance'].replaceAll(' m', ''));
        return distA.compareTo(distB);
      });

      return results;
    });
  }

  // remove user locations to prevent storing outdated locations
  Future<void> removeUserLocation() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _dbRef.child(user.uid).remove();
      }

      for (final testUser in _testUsers) {
        await _dbRef.child(testUser['id']).remove();
      }
    } catch (e) {
      rethrow;
    }
  }
}
