// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:move_safe/firebase_options.dart';
import 'package:move_safe/locationSharing/location_sharing.dart';
import 'package:move_safe/reportPage/report_page.dart';
import 'app_theme.dart';
import 'landing/landing_page_widget.dart'; // import landing page
import 'home/home_widget.dart'; // import home page
import 'register/register_widget.dart'; // import register page
import 'login/login_widget.dart'; // import login page
import 'loginBioID/login_BioID_widget.dart'; // import login BioID page
import 'selfDefence/self_defence.dart'; // import self defence page
import 'authentication/authentication_widget.dart'; // import authentication page
import 'locationSharing/location_sharing.dart'; // import location sharing page 
// import report page
import 'reportPage/report_page.dart'; // import report page
import 'taxiTracking/taxi_tracking_widget.dart'; // import taxi tracking page
import 'taxiTracking/constants.dart';
import 'safeRouteMap/safe_route_map_widget.dart'; // import safe route map page

import 'settings/settings_page.dart'; 
import 'stations/stations_map.dart';



void main() async {
  // <--- MUST be async!
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // <--- MUST await!
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // Your root widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoveSafe App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme, // Apply the theme from app_theme.dart
      home:
          const LandingPageWidget(), // Set your landing page as the home screen
      routes: {
        '/home': (context) => const HomePage(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/loginBioID': (context) => const LoginAuthScreen(),
        '/selfDefence': (context) => const SelfDefenceResourcesPage(),
        '/taxiTracking': (context) => const TaxiTrackingPage(),
        '/safeRouteMap': (context) => const SafeRouteMapPage(),
        '/authentication': (context)=> const AuthenticationPage(),
        '/locationSharing': (context) => const LocationSharingPage(),
        '/reportPage': (context)=> const ReportPageWidget(),
        '/map': (context) => const TaxiTrackingPage(),
        '/settings': (context) => const SettingsPage(),
        '/stations': (context) => StationsMapPage(),
        // add more named routes as needed
      },
    );
  }
}