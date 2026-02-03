import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'taxi_tracking_backend.dart';

class TaxiTrackingPage extends StatefulWidget {
  const TaxiTrackingPage({super.key});

  static String routeName = 'TaxiTracking';
  static String routePath = '/taxiTracking';

  @override
  State<TaxiTrackingPage> createState() => _TaxiTrackingPageState();
}

class _TaxiTrackingPageState extends State<TaxiTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _initialMapCenter = LatLng(-26.2041, 28.0473);
  static const LatLng _userLocation = LatLng(-26.2041, 28.0473);

  late BitmapDescriptor userIcon;
  late BitmapDescriptor taxiIcon;
  
  // cache for generated custom taxi marker bitmaps
  final Map<String, BitmapDescriptor> _taxiMarkerBitmaps = {};
  bool _mapAssetsReady = false; // True when all icons and custom markers are loaded

  final ValueNotifier<double> _sheetExtentNotifier = ValueNotifier(0.25);
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  List<TaxiInfo> _taxiData = [];

  // helper function to convert a Widget to a BitmapDescriptor
  Future<BitmapDescriptor> _createBitmapFromWidget(Widget widget, BuildContext context) async {
    final GlobalKey globalKey = GlobalKey();
    final Completer<BitmapDescriptor> completer = Completer();

    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -1000, 
        top: -1000,
        child: RepaintBoundary(
          key: globalKey,
          child: Material(
            type: MaterialType.transparency, 
            child: widget,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // wait for the frame to render
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        RenderRepaintBoundary boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final devicePixelRatio = MediaQuery.of(globalKey.currentContext!).devicePixelRatio;
        ui.Image image = await boundary.toImage(pixelRatio: devicePixelRatio);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();
        completer.complete(BitmapDescriptor.fromBytes(pngBytes));
      } catch (e) {
        completer.completeError(e);
      } finally {
        overlayEntry.remove(); 
      }
    });

    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    _loadMapAssets();
    _sheetController.addListener(() {
      _sheetExtentNotifier.value = _sheetController.size;
    });
  }

  Future<void> _loadMapAssets() async {
    // load base user icon
    userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)),
      'assets/icons/user_icon.png',
    );
    // load base taxi icon (might be used if custom generation fails or for other UI)
    taxiIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)), 
      'assets/icons/taxi_icon.png',
    );

    _taxiData = await TaxiBackendService.fetchNearbyTaxis(userPosition: _userLocation);

    _mapAssetsReady = true;
    if (mounted) setState(() {});  
  }

  Set<Marker> _createMarkers() {
    if (!_mapAssetsReady) {
      return {}; 
    }

    Set<Marker> markers = {};

    // user marker
    markers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: _userLocation,
        icon: userIcon,
      ),
    );

    // taxi markers
    for (var taxi in _taxiData) {
      BitmapDescriptor iconToUse = _taxiMarkerBitmaps[taxi.id] ?? taxiIcon; // Use custom if available, else generic
      markers.add(
        Marker(
          markerId: MarkerId(taxi.id),
          position: taxi.position,
          icon: iconToUse,
          infoWindow: InfoWindow(title: taxi.modelPlate, snippet: 'Phone: ${taxi.phone}'),
        ),
      );
    }

    return markers;
  }

  void _centerOnUser() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      const CameraPosition(target: _userLocation, zoom: 18.0),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ensure map assets are loaded and taxi bitmaps aren't already fully generated
    if (_mapAssetsReady && _taxiMarkerBitmaps.length != _taxiData.length) {
      _generateAllTaxiMarkerBitmaps(); 
    }
    // _generateAllTaxiMarkerBitmaps calls setState if new bitmaps are generated.
  }
  Future<void> _generateAllTaxiMarkerBitmaps() async {
    for (var taxi in _taxiData) {
      if (!_taxiMarkerBitmaps.containsKey(taxi.id)) {
        final String plateNumber = taxi.modelPlate.split(' - ').last;
        final taxiMarkerWidget = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset('assets/icons/taxi_icon.png', width: 100, height: 100),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                plateNumber,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
        _taxiMarkerBitmaps[taxi.id] = await _createBitmapFromWidget(taxiMarkerWidget, context); 
      }
    }
  if (mounted) setState(() {});
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (!_mapAssetsReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialMapCenter,
                zoom: 17.0,
              ),
              myLocationButtonEnabled: false,
              markers: _createMarkers(),
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              padding: const EdgeInsets.only(bottom: 150),
            ),

            _buildBackButton(context),
            _buildDraggableSheet(),

            // (Re-center FAB)
            ValueListenableBuilder<double>(
              valueListenable: _sheetExtentNotifier,
              builder: (context, extent, _) {
                final sheetHeight = extent * screenHeight;
                return Positioned(
                  right: 16,
                  bottom: sheetHeight + 16,
                  child: FloatingActionButton(
                    onPressed: _centerOnUser,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x33000000),
              offset: Offset(0, 2),
            )
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.25,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                blurRadius: 8.0,
                color: Color(0x33000000),
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(top: 8.0),
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
                  'Swipe up for more taxis near you',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF424242),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ..._taxiData.map((taxi) => _buildTaxiListItem(taxi)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxiListItem(TaxiInfo taxi) {
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
            const Icon(Icons.local_taxi, color: Colors.black, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taxi.modelPlate,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: ${taxi.phone}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF424242),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    taxi.distance,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF874CF4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
