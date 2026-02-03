import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'safe_route_map_backend.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_webservice2/directions.dart' as gm_directions;


class SafeRouteMapPage extends StatefulWidget {
  const SafeRouteMapPage({super.key});

  static String routeName = 'SafeRouteMap';
  static String routePath = '/safeRouteMap';

  @override
  State<SafeRouteMapPage> createState() => _SafeRouteMapWidgetState();
}

class _SafeRouteMapWidgetState extends State<SafeRouteMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _isWalkingModeSelected = true; // default to walking mode
  String _currentUserIconAsset = 'assets/icons/user_icon.png'; // default user icon
  
  final ValueNotifier<double> _sheetExtentNotifier = ValueNotifier(0.0); // Initially hidden
  final DraggableScrollableController _sheetController = DraggableScrollableController(); // controller for the sheet
  // bool _showRouteSheet = false; // Will be controlled by _routeDetails != null

  late BitmapDescriptor _userMarkerBitmap;
  bool _userMarkerBitmapReady = false;
  bool _isInitialPositionFinalized = false; 

  // Route display state
  Polyline? _routePolyline;
  Marker? _destinationMarker;
  gm_directions.Route? _routeDetails; // To store distance, duration, etc.
  String? _destinationAddressString;
  bool _isLoadingRoute = false;


  late LatLng _targetUserPosition; // random spot

  // method to generate a random position within the defined bounds
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _sheetController.addListener(() { // listen to sheet scroll changes
      _sheetExtentNotifier.value = _sheetController.size;
    });
    // initially sheet small or hidden if no route
    if (_routeDetails == null) {
       _sheetExtentNotifier.value = 0.0; // Minimized/hidden
    }

    // the map won't build until ready.
    _targetUserPosition = const LatLng(0,0); 
    _finalizeInitialPositionAndLoadIcon();
  }

  Future<void> _finalizeInitialPositionAndLoadIcon() async {
    // determine the user's position
    LatLng randomPosition = SafeRouteMapBackend.initializeRandomUserPosition();
    LatLng positionToSet;
    try {
      LatLng snappedPosition = await SafeRouteMapBackend.snapToRoad(randomPosition);
      positionToSet = snappedPosition;
    } catch (e) {
      print("Error snapping to road: $e. Using the original random position.");
      positionToSet = randomPosition; 
    }

    if (mounted) {
      setState(() {
        _targetUserPosition = positionToSet;
        _isInitialPositionFinalized = true;
      });
    }

    _loadUserMarkerIcon(); 
  }

  Future<void> _loadUserMarkerIcon() async {
    if (!mounted) return;
    setState(() {
      _userMarkerBitmapReady = false; 
    });
    _userMarkerBitmap = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(64, 64)), 
      _currentUserIconAsset,
    );
    if (mounted) {
      setState(() {
        _userMarkerBitmapReady = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _sheetController.dispose();
    _sheetExtentNotifier.dispose();
    super.dispose();
  }

  // helper method to build the mode selection icons
  Widget _buildModeIcon(IconData iconData, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF874CF4) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          
        ),
        child: Icon(
          iconData,
          color: isSelected ? Colors.white : const Color(0xFF874CF4),
          size: 24,
        ),
      ),
    );
  }

  Future<void> _findAndDisplayRoute(String searchValue) async {
    if (searchValue.isEmpty) return;

    setState(() {
      _isLoadingRoute = true;
      _clearRoute(); // clearing previous route
    });

    final destinationPlace = await SafeRouteMapBackend.geocodeAddress(searchValue);

    if (destinationPlace?.geometry?.location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find location: $searchValue')),
        );
        setState(() => _isLoadingRoute = false);
      }
      return;
    }

    final destLocation = destinationPlace!.geometry!.location;
    final destinationLatLng = LatLng(destLocation.lat, destLocation.lng);
    _destinationAddressString = destinationPlace.formattedAddress ?? searchValue;

    final travelMode = _isWalkingModeSelected ? gm_directions.TravelMode.walking : gm_directions.TravelMode.bicycling;

    final directionsResponse = await SafeRouteMapBackend.getDirections(
      _targetUserPosition, 
      destinationLatLng,
      travelMode,
    );

    if (directionsResponse != null && directionsResponse.routes.isNotEmpty) {
      final route = directionsResponse.routes.first;
      
      List<LatLng> points = [];
      if (route.overviewPolyline.points.isNotEmpty) {
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> decodedResult = polylinePoints.decodePolyline(route.overviewPolyline.points);
        points = decodedResult.map((point) => LatLng(point.latitude, point.longitude)).toList();
      } else {
        print("Warning: Overview polyline points string is empty.");
      }

      setState(() {
        _routePolyline = Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: const Color(0xFF874CF4),
          width: 5,
        );
        _destinationMarker = Marker(
          markerId: const MarkerId('destination'),
          position: destinationLatLng,
          infoWindow: InfoWindow(title: _destinationAddressString ?? 'Destination'),
        );
        _routeDetails = route;
        _isLoadingRoute = false;
        _animateToRouteBounds(directionsResponse.routes.first.bounds);
      });
      // animate sheet after setState has built the sheet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sheetController.isAttached && _routeDetails != null) {
          _sheetController.animateTo(0.25, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not find a route.')));
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  // build the main widget tree
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (!_isInitialPositionFinalized || !_userMarkerBitmapReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Google Map background
            _buildGoogleMap(),
            
            // loading indicator for route search
            if (_isLoadingRoute)
              const Center(child: CircularProgressIndicator()),


            // positioned search bar & mode selection
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 180,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10, 
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0.0, 5.0),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back Button
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, '/home');
                              }
                            },
                          ),
                        ),
                        Row(
                          children: [
                            _buildModeIcon(
                                Icons.directions_walk, _isWalkingModeSelected,
                                () {
                              setState(() {
                                _isWalkingModeSelected = true;
                                _currentUserIconAsset = 'assets/icons/user_icon.png';
                                _loadUserMarkerIcon(); // reload marker icon
                              });
                            }),
                            const SizedBox(width: 16),
                            _buildModeIcon(
                                Icons.directions_bike, !_isWalkingModeSelected,
                                () {
                              setState(() {
                                _isWalkingModeSelected = false;
                                _currentUserIconAsset = 'assets/icons/user_bike_icon.png'; // change to bike icon
                                _loadUserMarkerIcon(); // reload marker icon
                              });
                            }),
                          ],
                        ),
                      ],
                    ),
                    // search bar
                    TextFormField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search here',
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade600),
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF874CF4), size: 24),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Color(0xFF874CF4), width: 1.5),
                        ),
                      ),
                      onFieldSubmitted: (String searchValue) {
                        // when search is submitted, show the sheet
                        _findAndDisplayRoute(searchValue);
                      },
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.black), // Changed text color to black
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24, 
              right: 16, 
              child: FloatingActionButton(
                onPressed: _centerOnTargetPosition,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black),
              ),
            ),

            // draggable sheet for route details
            if (_routeDetails != null) _buildRouteDetailsSheet(),
          ],
        ),
      ),
    );
  }

  // method to centre map 
  void _centerOnTargetPosition() async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _targetUserPosition, zoom: 17.0), // Consistent zoom
    ));
  }

  void _animateToRouteBounds(gm_directions.Bounds? bounds) async {
    if (bounds == null || !_mapController.isCompleted) return;
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(bounds.southwest.lat, bounds.southwest.lng),
          northeast: LatLng(bounds.northeast.lat, bounds.northeast.lng),
        ),
        50.0, 
      ),
    );
  }

  Set<Marker> _createMapMarkers() {
    Set<Marker> markers = {};
    if (_userMarkerBitmapReady) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_marker'),
          position: _targetUserPosition,
          icon: _userMarkerBitmap,
          anchor: const Offset(0.5, 0.5), // centre the icon on the coordinate
        ),
      );
    }
    if (_destinationMarker != null) {
      markers.add(_destinationMarker!);
    }
    return markers;
  }

  // build the Google Map widget
  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _targetUserPosition, // randomised position
        zoom: 17.0, 
      ),
      onMapCreated: (GoogleMapController controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
        }
      },
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: false, 
      markers: _createMapMarkers(),
      polylines: _routePolyline != null ? {_routePolyline!} : {},
    );
  }

  Widget _buildRouteDetailsSheet() {
    if (_routeDetails == null) return const SizedBox.shrink();

    String distance = "N/A";
    String duration = "N/A";

    if (_routeDetails!.legs.isNotEmpty) {
      distance = _routeDetails!.legs.first.distance.text;
      duration = _routeDetails!.legs.first.duration.text;
    }

    return DraggableScrollableSheet(
      key: const ValueKey('route_details_sheet'), // key for stability
      controller: _sheetController,
      initialChildSize: 0.25,
      minChildSize: 0.1,   
      maxChildSize: 0.5,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              Center( 
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Safest routes listed below',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('Route 1 - ${_destinationAddressString ?? 'Destination'}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Time estimation: $duration', style: GoogleFonts.inter(fontSize: 16)),
              const SizedBox(height: 4),
              Text('Distance: $distance', style: GoogleFonts.inter(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _clearRoute,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: Text('Clear Route', style: GoogleFonts.inter(color: Colors.white)),
              )
            ],
          ),
        );
      },
    );
  }

  void _clearRoute() {
    setState(() {
      _routePolyline = null;
      _destinationMarker = null;
      _routeDetails = null;
      _destinationAddressString = null;
      _searchController.clear();
      if (_sheetController.isAttached) {
         _sheetController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }
}
