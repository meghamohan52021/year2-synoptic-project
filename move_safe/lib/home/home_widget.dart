import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:move_safe/login/login_widget.dart';


// SOS call function
void main() => runApp(const HomePage());
_phoneCall() async {
  var url = Uri.parse("+441234567890");
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  } 
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // navigation route name
  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

// UI for home page
class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TextStyle _logoTextStyle(BuildContext context) {
    return GoogleFonts.leagueSpartan(
      color: Colors.white,
      fontSize: 40,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.0,
    );
  }

  TextStyle _sosButtonTextStyle(BuildContext context) {
    return GoogleFonts.interTight(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.0,
    );
  }

  TextStyle _navButtonTextStyle(BuildContext context) {
    return GoogleFonts.interTight(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.0,
    );
  }

  TextStyle _logoutTextStyle(BuildContext context) {
    return GoogleFonts.inter(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.0,
    );
  }

  Widget _buildNavButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(280, 50),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        elevation: 0,
      ),
      child: Text(text, style: _navButtonTextStyle(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF874CF4),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text('MoveSafe', style: _logoTextStyle(context)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          print('SOS Button pressed');
                          _phoneCall();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0000),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(100, 60),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 3,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text('SOS', style: _sosButtonTextStyle(context)),
                      ),
                    ],
                  ),
                ),

                // navigation buttons
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 20.0,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNavButton('TAXI TRACKING', () {
                            if (mounted) {
                              // Navigate to Taxi Tracking page
                              print('TAXI TRACKING Button Pressed');
                              Navigator.pushReplacementNamed(
                                context,
                                '/taxiTracking',
                              );
                            }
                          }),
                          const SizedBox(height: 16),
                          _buildNavButton('SAFE ROUTE MAP', () {
                            if (mounted) {
                              // Navigate to Safe Route Map page
                              print('SAFE ROUTE MAP Button Pressed');
                              Navigator.pushReplacementNamed(
                                context,
                                '/safeRouteMap',
                              );
                            }
                          }),
                          const SizedBox(height: 16),
                          _buildNavButton('LOCATION SHARING', () {
                            if (mounted) {
                              // navigate to location sharing page
                              print('LOCATION SHARING pressed');
                              Navigator.pushReplacementNamed (
                                context,
                                '/locationSharing',
                              );
                            }                    
                          }),
                          const SizedBox(height: 16),
                          _buildNavButton('REPORT', () {
                            print('REPORT pressed');
                            // navigate to Report page
                            Navigator.pushReplacementNamed(
                              context,
                              '/reportPage',
                            );
                          }),
                          const SizedBox(height: 16),
                          _buildNavButton('SELF-DEFENCE RESOURCES', () {
                            if (mounted) {
                              // Navigate to Self Defence Resources page
                              print('SELF DEFENCE Button Pressed');
                              Navigator.pushReplacementNamed(
                                context,
                                '/selfDefence',
                              );
                            }
                          }),
                          const SizedBox(height: 16),
                          _buildNavButton('MoveSafe Station', () {
                            print('MoveSafe Station pressed');                          
                            // navigation to MoveSafe Station page
                            Navigator.pushNamed(context, '/stations');
                          }),
                          const SizedBox(height: 16),
                          _buildNavButton('SETTINGS', () {
                            print('SETTINGS pressed');
                            // implement navigation to Settings page
                            Navigator.pushNamed(context, '/settings');
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          print('Logout tapped');
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Row(
                          children: [
                            Text('Logout', style: _logoutTextStyle(context)),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
