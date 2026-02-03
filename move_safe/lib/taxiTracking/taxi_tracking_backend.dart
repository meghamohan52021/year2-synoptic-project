import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class TaxiInfo {
  final String id;
  final String modelPlate;
  final String phone;
  final String distance;
  final LatLng position;

  TaxiInfo({
    required this.id,
    required this.modelPlate,
    required this.phone,
    required this.distance,
    required this.position,
  });
}

class TaxiBackendService {
  // geographical bounds for Maker's Valley
  static const double _minLat = -26.208; 
  static const double _maxLat = -26.200;
  static const double _minLng = 28.045;
  static const double _maxLng = 28.055;

  // a reference user position within Maker's Valley for distance calculation
  static const LatLng _referenceUserPositionInMakersValley = LatLng(-26.2041, 28.0473);

  static final Random _random = Random();

  // generate a random LatLng within Maker's Valley bounds
  static LatLng _generateRandomTaxiPosition() {
    final lat = _minLat + _random.nextDouble() * (_maxLat - _minLat);
    final lng = _minLng + _random.nextDouble() * (_maxLng - _minLng);
    return LatLng(lat, lng);
  }

  // calculate distance in kilometers between two LatLng points (Haversine formula)
  static double _calculateDistance(LatLng pos1, LatLng pos2) {
    const R = 6371; // radius of the earth in km
    var lat1 = pos1.latitude;
    var lon1 = pos1.longitude;
    var lat2 = pos2.latitude;
    var lon2 = pos2.longitude;

    var dLat = _deg2rad(lat2 - lat1);
    var dLon = _deg2rad(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    var d = R * c; // distance in km
    return d;
  }

  static double _deg2rad(deg) {
    return deg * (pi / 180);
  }

  static Future<List<TaxiInfo>> fetchNearbyTaxis({LatLng? userPosition}) async {
    // use provided userPosition or the default reference for Maker's Valley
    final LatLng currentUserPosition = userPosition ?? _referenceUserPositionInMakersValley;

    // simulate a network call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // generate random taxi plates
    List<String> models = ['Toyota Quantum', 'Mercedes Sprinter', 'VW Crafter', 'Ford Transit', 'Nissan NV350'];
    List<String> platesPrefix = ['ABC', 'DEF', 'GHI', 'JKL', 'MNO'];
    List<String> phonePrefix = ['+27 82', '+27 73', '+27 61', '+27 72', '+27 84'];

    List<TaxiInfo> taxis = List.generate(5, (index) { // generate 5 random taxis
      LatLng taxiPos = _generateRandomTaxiPosition();
      double distanceKm = _calculateDistance(currentUserPosition, taxiPos);
      String distanceString = distanceKm < 1
          ? '${(distanceKm * 1000).toStringAsFixed(0)}m away'
          : '${distanceKm.toStringAsFixed(1)}km away';

      return TaxiInfo(
        id: 'taxi${index + 1}',
        modelPlate: '${models[_random.nextInt(models.length)]} - ${platesPrefix[_random.nextInt(platesPrefix.length)]} ${_random.nextInt(900) + 100} GP',
        phone: '${phonePrefix[_random.nextInt(phonePrefix.length)]} ${_random.nextInt(9000000) + 1000000}',
        distance: distanceString,
        position: taxiPos,
      );
    });
    return taxis;
  }
}
