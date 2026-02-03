// lib/landing_page.dart

import 'package:flutter/material.dart';
// import login test page


class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({super.key});

  @override
  State<LandingPageWidget> createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Accessing the theme data provided by MaterialApp in main.dart
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        // backgroundColor is now handled by ThemeData's scaffoldBackgroundColor
        // which is defined in AppTheme and applied in main.dart
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Text('MoveSafe', style: textTheme.headlineLarge),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      child: Text(
                        'Your Trusted Companion On Every Route.',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to Login Screen
                                print('Login Button pressed ...');
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              // Style is inherited from ElevatedButtonThemeData
                              // defined in AppTheme and applied in main.dart
                              child: const Text('Login'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to Register Screen
                                print('Sign Up Button pressed ...');
                                Navigator.pushReplacementNamed(context, '/register');
                              },
                              // Style is inherited from ElevatedButtonThemeData
                              child: const Text('Sign Up'),
                            ),
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
    );
  }
}
