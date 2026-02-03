import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class StationsMapPage extends StatefulWidget {
  @override
  _StationsMapPageState createState() => _StationsMapPageState();
}

class _StationsMapPageState extends State<StationsMapPage> {
  late GoogleMapController mapController;
  LatLng _userLocation = LatLng(-26.2034, 28.0756); // default to Makers Valley

  final List<Map<String, dynamic>> safeStations = [
    {
      "name": "Station 03",
      "lat": -26.2035,
      "lng": 28.0752,
      "distance": "0.0km"
    },
    {
      "name": "Station 10",
      "lat": -26.2042,
      "lng": 28.0768,
      "distance": "0.5km"
    },
    {
      "name": "Station 11",
      "lat": -26.2051,
      "lng": 28.0780,
      "distance": "1km"
    },
  ];

  final LatLng _center = LatLng(-26.2034, 28.0756); //Makers Valley center
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setUserLocation();
    _loadMarkers();
  }


  Future<void> _setUserLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _userLocation = LatLng(position.latitude, position.longitude);

    // distance form stations
    for (var station in safeStations) {
      double distanceInMeters = Geolocator.distanceBetween(
        _userLocation.latitude,
        _userLocation.longitude,
        station["lat"],
        station["lng"],
      );
      double distanceInKm = distanceInMeters / 1000;
      station["distance"] = "${distanceInKm.toStringAsFixed(1)} km";
    }

    setState(() {
      _loadMarkers();
    });
  } catch (e) {
    //if GPS fails
  }
}


  Future<void> _loadMarkers() async {
    _markers.clear();

    final BitmapDescriptor userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/user_icon.png',
    );


    //User marker
    _markers.add(Marker(
      markerId: MarkerId("user"),
      position: _userLocation,
      icon: userIcon,
      infoWindow: InfoWindow(title: "You"),
    ));

    final BitmapDescriptor stationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/move_station_icon.png',
    );

    //Station marker
    for (var station in safeStations) {
    _markers.add(Marker(
      markerId: MarkerId(station["name"]),
      position: LatLng(station["lat"], station["lng"]),
      icon: stationIcon,
      infoWindow: InfoWindow(title: station["name"]),
      ));
    }
  }

  void _openGoogleMaps(double lat, double lng) async {
    final Uri uri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&origin=${_userLocation.latitude},${_userLocation.longitude}&destination=$lat,$lng&travelmode=walking");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch Google Maps";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 16.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.15,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: safeStations.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Center(
                          child: Text(
                            "Swipe up for more stations near you",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }

                    final station = safeStations[index - 1];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      leading: Icon(Icons.emergency, color: Colors.red),
                      title: Text(station["name"],style: TextStyle(color: Colors.black87)),
                      subtitle: Text("${station["distance"]} away",style: TextStyle(color: Colors.black87)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => _openGoogleMaps(
                            station["lat"], station["lng"]),
                        child: Text("Directions",
                        style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
