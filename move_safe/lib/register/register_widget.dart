import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the newly created files
import 'package:move_safe/utils/form_validator.dart';
import 'package:move_safe/services/auth_service.dart'; 
// Placeholder for your LoginPage, replace with actual import if you have one
// import 'package:your_app_name/screens/login_page.dart';

class RegisterScreen extends StatefulWidget {
  // Added an optional AuthService parameter for testability
  final AuthService? authService;

  const RegisterScreen({super.key, this.authService});

  static const String routeRegisterName =
      '/register'; // named routing for register screen

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Use the injected AuthService if available
  late final AuthService _authService;

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Text Editing Controllers
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Focus Nodes
  late FocusNode _nameFocusNode;
  late FocusNode _dobFocusNode;
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _confirmPasswordFocusNode;

  // Password Visibility
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _authService =
        widget.authService ?? AuthService(); // Initialize AuthService

    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _nameFocusNode = FocusNode();
    _dobFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _dobFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  // --- Helper for TextStyles ---
  TextStyle get _commonFieldTextStyle => GoogleFonts.inter(
    letterSpacing: 0.0,
    color: Colors.black,
    
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
        //  transparent border on focus
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
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      autofocus: true, // As per FlutterFlow
      textCapitalization: TextCapitalization.words,
      keyboardType: TextInputType.name,
      decoration: _buildInputDecoration('Name'),
      style: _commonFieldTextStyle,
      textInputAction: TextInputAction.next,
      // Use the new FormValidators class
      validator: (value) => FormValidators.validateName(value),
    );
  }

  Widget _buildDobField() {
    return TextFormField(
      controller: _dobController,
      focusNode: _dobFocusNode,
      keyboardType: TextInputType.datetime,
      decoration: _buildInputDecoration('Date of Birth'),
      style: _commonFieldTextStyle,
      textInputAction: TextInputAction.next,
      // Use the new FormValidators class
      validator: (value) => FormValidators.validateDob(value),
      onTap: () async {
        // Optionally show a date picker
        FocusScope.of(context).requestFocus(_dobFocusNode); // Keep focus
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        // Format date as you need e.g., using intl package
        _dobController.text = pickedDate != null
            ? "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}"
            : '';
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      decoration: _buildInputDecoration('Email'),
      style: _commonFieldTextStyle,
      textInputAction: TextInputAction.next,
      // Use the new FormValidators class
      validator: (value) => FormValidators.validateEmail(value),
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
      textInputAction: TextInputAction.next,
      // Use the new FormValidators class
      validator: (value) => FormValidators.validatePassword(value),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: !_confirmPasswordVisible,
      decoration: _buildInputDecoration(
        'Confirm Password',
        suffixIcon: IconButton(
          icon: Icon(
            _confirmPasswordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _confirmPasswordVisible = !_confirmPasswordVisible;
            });
          },
        ),
      ),
      style: _commonFieldTextStyle,
      textInputAction: TextInputAction.done,
      // Use the new FormValidators class, passing the password from the first field
      validator: (value) => FormValidators.validateConfirmPassword(
        value,
        _passwordController.text,
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF874CF4),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          try {
            // Use the injected AuthService here
            await _authService.registerWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
              name: _nameController.text,
              dob: _dobController.text,
            );

            if (mounted) {
              print('Registration successful!');
              // Navigate to Authentication Screen 
              Navigator.pushReplacementNamed(context, '/authentication');
            }
          } on FirebaseAuthException catch (e) {
            String message;
            if (e.code == 'weak-password') {
              message = 'The password provided is too weak.';
            } else if (e.code == 'email-already-in-use') {
              message = 'An account already exists for that email.';
            } else {
              message = 'Registration failed: ${e.message}';
            }
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
            print("Firebase Auth Error: ${e.code} - ${e.message}");
          } catch (error) {
            print("Error saving to Firebase: $error");
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to register: $error')),
              );
            }
          }
        }
      },
      //  the 'child' property for the Text widget
      child: Text(
        'Sign Up',
        style: GoogleFonts.interTight(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        children: [
          const TextSpan(text: 'Already have an account? '),
          TextSpan(
            text: 'Login',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                print('Login tapped ...');
                // Navigate to Login Screen
                Navigator.pushReplacementNamed(context, '/login');
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
              // Used to ensure centering works with SingleChildScrollView
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints
                          .maxHeight, // Ensures column can center content
                    ),
                    child: IntrinsicHeight(
                      // Column takes needed height
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // As per FlutterFlow
                        children: [
                          // Logo
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: Text(
                              'MoveSafe',
                              style: logoStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Form Box Container (wrapped in Padding as per FF structure)
                          Padding(
                            padding: const EdgeInsets.all(
                              24.0,
                            ), // Outer padding for the form box
                            child: Container(
                              width: double
                                  .infinity, // Important if parent column is CrossAxisAlignment.center
                              decoration: formBoxDecoration,
                              padding: const EdgeInsets.all(
                                16.0,
                              ), // Inner padding for form elements
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildNameField(),
                                    const SizedBox(height: 16),
                                    _buildDobField(),
                                    const SizedBox(height: 16),
                                    _buildEmailField(),
                                    const SizedBox(height: 16),
                                    _buildPasswordField(),
                                    const SizedBox(height: 16),
                                    _buildConfirmPasswordField(),
                                    const SizedBox(
                                      height: 24,
                                    ), // Space before button
                                    _buildSignUpButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // "Already have an account?" Text
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 24.0,
                              bottom: 16.0,
                            ), // FF: (0,24,0,0) for the Row
                            child: _buildLoginLink(),
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
