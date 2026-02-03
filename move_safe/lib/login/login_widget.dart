import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // For RichText tap recognizer
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:move_safe/home/home_widget.dart';
import 'package:move_safe/register/register_widget.dart';
import 'package:move_safe/loginBioID/login_BioID_widget.dart';


// Import your AppTheme and RegisterScreen
// Make sure these paths are correct in your project
//import 'package:move_safe/app_theme.dart'; // Assuming AppTheme is in a separate file

// If AppTheme and RegisterScreen are in the same file as ReportPageWidget or main.dart,
// you might not need explicit imports, but it's good practice for modularity.
// For this example, I'll assume they are in separate files.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeLoginName = '/login'; // named routing for login screen

  @override
  State<LoginScreen> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  bool _passwordVisible = false;
  bool _isLoading = false; // To show loading state during sign-in

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // --- Helper for TextStyles ---
  TextStyle get _commonFieldTextStyle => GoogleFonts.inter(
    letterSpacing: 0.0,
    color: Colors.black, // Assuming default text color
  );

  TextStyle get _commonHintTextStyle =>
      GoogleFonts.inter(letterSpacing: 0.0, color: Colors.grey[600]);

  // --- Helper for Input Decoration ---
  InputDecoration _buildInputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: _commonHintTextStyle,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF874CF4), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        // As per FlutterFlow: transparent border on focus
        borderSide: const BorderSide(color: Colors.transparent, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1,
        ), // Standard error border
        borderRadius: BorderRadius.circular(8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ), // Standard focused error
        borderRadius: BorderRadius.circular(8),
      ),
      suffixIcon: suffixIcon,
    );
  }

  // --- Form Field Widgets ---
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      decoration: _buildInputDecoration('Email'),
      style: _commonFieldTextStyle,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_passwordVisible,
      decoration: _buildInputDecoration(
        'Password',
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
      style: _commonFieldTextStyle,
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        // Firebase usually handles min length, but client-side validation is good
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF874CF4),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      onPressed: _isLoading ? null : _signIn, // Disable button when loading
      child: _isLoading
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : Text(
              'Sign In',
              style: GoogleFonts.interTight(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
    );
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Set loading to true
      });

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (mounted) {
          // Navigate to Home
          print('Login successful!');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided for that user.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        } else {
          message = 'Login failed: ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        print("Firebase Auth Error: ${e.code} - ${e.message}");
      } catch (e) {
        print("General error during login: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false; // Always set loading to false after attempt
        });
      }
    }
  }

  Widget _buildRegisterLink() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        children: [
          const TextSpan(text: 'Don\'t have an account? '),
          TextSpan(
            text: 'Register',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                print('Register tapped ...');
                // Navigate to Register Screen
                Navigator.pushReplacementNamed(context, '/register');
              },
          ),
        ],
      ),
    );
  }

Widget _buildBioIDLink() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        children: [
          const TextSpan(text: 'login with'),
          TextSpan(
            text: ' FaceID or Fingerprint',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                print('BioID tapped ...');
                // Navigate to Login Bio ID Screen
                Navigator.pushReplacementNamed(context, '/loginBioID');
              },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final logoStyle = GoogleFonts.leagueSpartan(
      color: Colors.white,
      fontSize: 60,
      fontWeight: FontWeight.bold,
    );

    final formBoxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black, width: 1),
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Unfocus on tap outside
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF874CF4),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints
                          .maxHeight, // Ensures column can center content vertically
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Centers content vertically in the available space
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Centers logo and form box horizontally
                        children: [
                          // Logo
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: Text(
                              'MoveSafe', // Or your app logo/name
                              style: logoStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Login Form Box
                          Center(
                            // Ensures the Container (form box) is horizontally centered
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth:
                                    400, // Max width for the form container
                              ),
                              decoration: formBoxDecoration,
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .stretch, // Fields stretch to fill container width
                                  children: [
                                    _buildEmailField(),
                                    const SizedBox(height: 16),
                                    _buildPasswordField(),
                                    const SizedBox(
                                      height: 24,
                                    ), // Space before button
                                    _buildSignInButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // "Don't have an account?" Text
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 24.0,
                              bottom: 16.0,
                            ),
                            child: _buildRegisterLink(),
                          ),

                          // "Login with FaceID or Fingerprint" Text
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 24.0,
                              bottom: 10.0,
                            ),
                            child: _buildBioIDLink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}