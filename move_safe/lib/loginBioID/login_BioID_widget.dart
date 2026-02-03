//importing flutter package for UI
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // for PlatformException
import 'package:local_auth/local_auth.dart'; // biometric authentication

// widget for login screen to handle authentication state
class LoginAuthScreen extends StatefulWidget {
  //constructor with key parameter for widget
  const LoginAuthScreen({super.key});

  static const String routeBioIDName = '/loginBioID'; // named routing for login bio id screen

  @override
  State<LoginAuthScreen> createState() => _LoginAuthScreenState();
}

class _LoginAuthScreenState extends State<LoginAuthScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<void> _authenticateUser() async {
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to login',
        options: const AuthenticationOptions(
          stickyAuth: true, // keep auth dialog open on app switch
          biometricOnly: true, // only allow biometrics, no device PIN/Pattern
        ),
      );
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during authentication: ${e.message}')),
        );
      }
      print('Error during authentication: $e');
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      print('Login successful!');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print('Authentication failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed. Please try again.')),
      );
    }
  }

Widget _buildLoginLink() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
        children: [
          const TextSpan(text: 'login with'),
          TextSpan(
            text: ' Email & Password',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                print('Login tapped ...');
                // Navigate to Login Bio ID Screen
                Navigator.pushReplacementNamed(context, '/login');
              },
          ),
        ],
      ),
    );
  }

  @override
  //creates and returns UI layout of login page
  Widget build(BuildContext context) {
    return Scaffold(
    //sets scaffold background structure to purple background
      backgroundColor: const Color(0xFF874CF4), 
      //content to centre of screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          //puts move safe title in the centre
          children: [
            const Text(
              'MoveSafe',
              //may need to change text style
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            //sets 50px between app title and white box
            const SizedBox(height: 50),

            // white container card for login box
            Container(
              //space inside box
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
              //space outside box
              margin: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                color: Colors.white,
                //rounded borders
                borderRadius: BorderRadius.circular(16),
                //black border
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan Face or Fingerprint',
                    //text for biometric scan or face ID - in light grey
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 25),

                  // biometric icons to show where to scan - Fingerprint icon is now tappable
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.face_6, size: 64, color: Colors.black87), // Face ID icon (can be made tappable similarly)
                      const SizedBox(width: 40),
                      GestureDetector(
                        onTap: _authenticateUser,
                        child: const Icon(Icons.fingerprint, size: 64, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  //login button
                  ElevatedButton(
                    onPressed: _authenticateUser, // calls the authentication method
                    //currently a placeholder with print text and need to replace with image
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      //button text and styling for login
                      'Login',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Sign up link
                  RichText(
                    text: TextSpan(
                      text: "Don’t have an account? ",
                      style: const TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: "sign up",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),

                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacementNamed(context, '/register');
                            },
                        ),
                      ],
                    ),
                  ),  

                  // "Login with Email & Password" Link
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 24.0,
                      bottom: 10.0,
                    ),
                    child: _buildLoginLink(), 
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
