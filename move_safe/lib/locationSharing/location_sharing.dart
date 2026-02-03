import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:move_safe/locationSharing/locationSharing_backend.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class LocationSharingPage extends StatefulWidget {
  const LocationSharingPage({super.key});

  @override
  State<LocationSharingPage> createState() => _LocationSharingPageState();
}

class _LocationSharingPageState extends State<LocationSharingPage> {
  final LocationSharingService _locationService = LocationSharingService();
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  final Completer<GoogleMapController> _mapController = Completer();

  // johannesburg central coordinates
  static const LatLng _initialMapCenter = LatLng(-26.2041, 28.0473);
  static const LatLng _userLocation = LatLng(-26.2041, 28.0473);

  final ValueNotifier<double> _sheetExtentNotifier = ValueNotifier(0.4);
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadCustomIcons();
    _sheetController.addListener(() {
      _sheetExtentNotifier.value = _sheetController.size;
    });
  }

  late BitmapDescriptor userIcon;
  late BitmapDescriptor user1Icon;
  late BitmapDescriptor user2Icon;
  late BitmapDescriptor user3Icon;
  bool _iconsLoaded = false;

  Future<void> _loadCustomIcons() async {
    userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)),
      'assets/icons/user_icon.png',
    );
    user1Icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)),
      'assets/icons/user2_icon.png',
    );
    user2Icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)),
      'assets/icons/user3_icon.png',
    );
    user3Icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)),
      'assets/icons/user4_icon.png',
    );
    setState(() {
      _iconsLoaded = true;
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      // created a position object with johannesburg coordinates
      final position = Position(
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

      await _locationService.saveUserLocation(position);
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // center the map on johannesburg 
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(target: _userLocation, zoom: 15.0),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Location error: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Set<Marker> _createMarkers(List<Map<String, dynamic>> nearbyPeople) {
    if (!_iconsLoaded) return {};

    Set<Marker> markers = {};

    // current user marker at johannesburg center point
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _userLocation,
        icon: userIcon,
        infoWindow: const InfoWindow(title: 'You'),
      ),
    );

    // nearby test user markers
    for (var person in nearbyPeople) {
      BitmapDescriptor icon;
      switch (person['id']) {
        case 'test_user_1':
          icon = user1Icon;
          break;
        case 'test_user_2':
          icon = user2Icon;
          break;
        case 'test_user_3':
          icon = user3Icon;
          break;
        default:
          icon = user1Icon;
      }

      markers.add(
        Marker(
          markerId: MarkerId(person['id'] ?? person['name']),
          position: LatLng(person['latitude'], person['longitude']),
          icon: icon,
          infoWindow: InfoWindow(
            title: person['name'],
            snippet: person['distance'],
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Stack(
          children: [
            // map widget
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _locationService.getNearbyPeopleStream(_currentPosition!),
              builder: (context, snapshot) {
                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _initialMapCenter,
                    zoom: 15.0,
                  ),
                  myLocationButtonEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  markers: _iconsLoaded
                      ? _createMarkers(snapshot.data ?? [])
                      : {},
                  padding: EdgeInsets.only(bottom: screenHeight * 0.4),
                );
              },
            ),

            // loading and error indicators
            if (_isLoading) _buildLoadingIndicator(),
            if (_errorMessage != null) _buildErrorDisplay(),

            // back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: _buildBackButton(),
            ),

            Stack(
              children: [
                _buildPeopleSheet(),

                ValueListenableBuilder<double>(
                  valueListenable: _sheetExtentNotifier,
                  builder: (context, extent, child) {
                    final sheetHeight = screenHeight * extent;
                    return Positioned(
                      bottom: sheetHeight + 16,
                      left: 16,
                      child: _buildReportButton(),
                    );
                  },
                ),

                ValueListenableBuilder<double>(
                  valueListenable: _sheetExtentNotifier,
                  builder: (context, extent, child) {
                    final sheetHeight = screenHeight * extent;
                    return Positioned(
                      bottom: sheetHeight + 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: _centerOnUser,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _centerOnUser() async {
    try {
      if (!_mapController.isCompleted) return;

      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(-26.2041, 28.0473),
            zoom: 18.0,
            bearing: 0,
            tilt: 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error centering map: $e');
    }
  }

  Widget _buildBackButton() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Color(0x33000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        iconSize: 24,
        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
      ),
    );
  }

  Widget _buildReportButton() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF0000),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: TextButton(
          onPressed: () => _showSafetyDialog(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'REPORT',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Color _getRandomColor(String seed) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }

  Widget _buildPeopleSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 8.0,
                color: Color(0x33000000),
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _locationService.getNearbyPeopleStream(_currentPosition!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorSheet(snapshot.error.toString());
              }

              if (!snapshot.hasData) {
                return _buildLoadingSheet();
              }

              final people = snapshot.data!;
              return Column(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'People near you (${people.length})',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF424242),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: people.length,
                      itemBuilder: (context, index) =>
                          _buildPersonCard(people[index]),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPersonCard(Map<String, dynamic> person) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getPersonColor(person['name']),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(person['name']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person['name'],
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    person['distance'],
                    style: GoogleFonts.inter(
                      color: const Color(0xFF874CF4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message_outlined),
                  color: Colors.blue[600],
                  onPressed: () =>
                      _showActionSnackbar('Message sent to ${person['name']}'),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined),
                  color: Colors.green[600],
                  onPressed: () =>
                      _showActionSnackbar('Calling ${person['name']}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPersonColor(String name) {
    final colors = [
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.teal[400]!,
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  String _getInitials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();

  void _showActionSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSafetyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text(
          'This would trigger emergency protocols and notify your emergency contacts',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showActionSnackbar('Emergency alert sent');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSheet(String error) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Error loading nearby people',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    error.replaceAll('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSheet() {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Finding people near you...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _initLocation, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
