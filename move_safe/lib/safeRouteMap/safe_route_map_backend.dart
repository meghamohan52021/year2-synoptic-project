import 'dart:math';
import 'dart:convert'; // json.decode
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http; 
import 'package:google_maps_webservice2/places.dart' as gm_places;
import 'package:google_maps_webservice2/directions.dart' as gm_directions;

class SafeRouteMapBackend {
  // define the bounds for the random position within Maker's Valley
  static const double _minLat = -26.3;
  static const double _maxLat = -26.1;
  static const double _minLng = 27.9;
  static const double _maxLng = 28.2;

  // method to generate a random user position within the defined bounds
  static LatLng initializeRandomUserPosition() {
    final random = Random();
    final lat = _minLat + random.nextDouble() * (_maxLat - _minLat);
    final lng = _minLng + random.nextDouble() * (_maxLng - _minLng);
    return LatLng(lat, lng);
  }

  static const String _googleApiKey = 'AIzaSyAo8WXb-OZWqbboPiwkd--OacBxmrvJRA0';

  static final gm_places.GoogleMapsPlaces _places = gm_places.GoogleMapsPlaces(apiKey: _googleApiKey);
  static final gm_directions.GoogleMapsDirections _directions = gm_directions.GoogleMapsDirections(apiKey: _googleApiKey);

  static Future<gm_places.PlacesSearchResult?> geocodeAddress(String address) async {
    try {
      gm_places.PlacesSearchResponse response = await _places.searchByText(address);
      if (response.isOkay && response.results.isNotEmpty) {
        return response.results.first;
      }
      print('Geocoding: No results found for "$address". Status: ${response.status}');
      return null;
    } catch (e) {
      print('Error during geocoding: $e');
      return null;
    }
  }


  static Future<LatLng> snapToRoad(LatLng originalPosition) async {
    final String path = '${originalPosition.latitude},${originalPosition.longitude}';
    //interpolate parameter is false as we only want the closest road point for a single coordinate
    final String url =
        'https://roads.googleapis.com/v1/snapToRoads?path=$path&interpolate=false&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['snappedPoints'] != null && data['snappedPoints'].isNotEmpty) {
          final snappedPoint = data['snappedPoints'][0]['location'];
          return LatLng(snappedPoint['latitude'], snappedPoint['longitude']);
        } else {
          print('SnapToRoad: No snapped points found. Response: ${response.body}');
          return originalPosition; // return original if no snap point found
        }
      } else {
        print('SnapToRoad API error: ${response.statusCode} - ${response.body}');
        return originalPosition; // return original on API error
      }
    } catch (e) {
      print('Error calling SnapToRoad API: $e');
      return originalPosition; // return original on exception
    }
  }

  static Future<gm_directions.DirectionsResponse?> getDirections(
    LatLng origin, 
    LatLng destination,
    gm_directions.TravelMode travelMode,
  ) async {
    try {
      gm_directions.DirectionsResponse response = await _directions.directionsWithLocation(
        gm_directions.Location(lat: origin.latitude, lng: origin.longitude),
        gm_directions.Location(lat: destination.latitude, lng: destination.longitude),
        travelMode: travelMode,
      );
      if (response.isOkay) {
        return response;
      }
      print('Directions API Error: ${response.status} - ${response.errorMessage}');
      return null;
    } catch (e) {
      print('Error fetching directions: $e');
      return null;
    }
  }
}