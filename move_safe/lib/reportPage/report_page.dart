import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Still needed for actual FirebaseAuth.instance in ReportService's default
import 'package:firebase_database/firebase_database.dart'; // Still needed for actual FirebaseDatabase.instance in ReportService's default
import 'package:move_safe/services/report_service.dart'; 

// ReportTheme for styling

class ReportTheme {
  static const Color primaryColor = Color(0xFF874CF4);
  static const Color secondaryBackgroundColor = Colors.white;
  static const Color accentColor = Color(0xFF874CF4); // Used for borders, icons
  static const Color textColorOnPrimary = Colors.white;
  static const Color primaryTextColor =
      Colors.black; // Default text color on secondary background
  static const Color secondaryTextColor =
      Colors.grey; // For hint text or secondary info
  static const Color errorColor = Colors.red;
  static const Color textFieldFillColor = Color(0xFFD8D8D8);

  static TextStyle bodyMedium(BuildContext context) {
    return GoogleFonts.inter(
      color: primaryTextColor,
      fontWeight: FontWeight.normal,
      fontSize: 14,
    );
  }

  static TextStyle labelMedium(BuildContext context) {
    return GoogleFonts.inter(
      color: secondaryTextColor,
      fontWeight: FontWeight.normal,
      fontSize: 12,
    );
  }

  static TextStyle get titleLargeWhite {
    return GoogleFonts.inter(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 20,
      letterSpacing: 0.0,
    );
  }
}

class ReportPageWidget extends StatefulWidget {
  const ReportPageWidget({super.key});

  static String routeName = 'ReportPage';
  static String routePath = '/reportPage';

  @override
  State<ReportPageWidget> createState() => _ReportPageWidgetState();
}

class _ReportPageWidgetState extends State<ReportPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController textController1;
  late FocusNode textFieldFocusNode1;
  String? textController1Validator(String? val) {
    if (val == null || val.isEmpty) {
      return 'Title cannot be empty';
    }
    return null;
  }

  late TextEditingController textController2;
  late FocusNode textFieldFocusNode2;
  String? textController2Validator(String? val) {
    if (val == null || val.isEmpty) {
      return 'Description cannot be empty';
    }
    return null;
  }

  String? dropDownValue;
  final List<String> dropDownOptions = [
    'Safety Concern',
    'Crime Incident',
    'Transportation Issue',
    'Road/Vehicle Hazard',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();

  // <--- NEW: Instance of ReportService
  late ReportService _reportService;

  @override
  void initState() {
    super.initState();
    textController1 = TextEditingController();
    textFieldFocusNode1 = FocusNode();

    textController2 = TextEditingController();
    textFieldFocusNode2 = FocusNode();

    _reportService = ReportService();
  }

  @override
  void dispose() {
    textController1.dispose();
    textFieldFocusNode1.dispose();

    textController2.dispose();
    textFieldFocusNode2.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      String title = textController1.text;
      String? type = dropDownValue;
      String description = textController2.text;

      try {
        // <--- Call the submitReport method from the ReportService
        await _reportService.submitReport(
          title: title,
          type: type,
          description: description,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted successfully!')),
          );
          // Optionally, navigate back to the homepage after successful submission
          // Navigator.pop(context);
          // Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } catch (e) {
        // Log the error for debugging purposes
        print('Error submitting report: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Accessing the current theme

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: ReportTheme.primaryColor,
        appBar: AppBar(
          backgroundColor: ReportTheme.primaryColor,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),
          title: Text('Report an Issue', style: ReportTheme.titleLargeWhite),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: ReportTheme.secondaryBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 5.0,
                            ),
                            child: Text(
                              'Issue Title',
                              style: ReportTheme.bodyMedium(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: TextFormField(
                              controller: textController1,
                              focusNode: textFieldFocusNode1,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: true,
                                labelStyle: ReportTheme.labelMedium(context),
                                hintText: 'Enter title of the issue',
                                hintStyle: ReportTheme.labelMedium(context),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: ReportTheme.accentColor,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: ReportTheme.errorColor,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: ReportTheme.errorColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: ReportTheme.textFieldFillColor,
                              ),
                              style: ReportTheme.bodyMedium(context),
                              cursorColor: ReportTheme.primaryTextColor,
                              validator: textController1Validator,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 5.0,
                            ),
                            child: Text(
                              'Type of Issue',
                              style: ReportTheme.bodyMedium(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: DropdownButtonFormField<String>(
                              value: dropDownValue,
                              items: dropDownOptions
                                  .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: ReportTheme.bodyMedium(context),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropDownValue = newValue;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Select...',
                                hintStyle: ReportTheme.labelMedium(context),
                                filled: true,
                                fillColor: ReportTheme.textFieldFillColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: ReportTheme.accentColor,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: ReportTheme.accentColor,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: ReportTheme.secondaryTextColor,
                                size: 24,
                              ),
                              dropdownColor: ReportTheme.textFieldFillColor,
                              validator: (value) => value == null
                                  ? 'Please select an issue type'
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 10.0,
                              bottom: 5.0,
                            ),
                            child: Text(
                              'Description',
                              style: ReportTheme.bodyMedium(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: TextFormField(
                              controller: textController2,
                              focusNode: textFieldFocusNode2,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: true,
                                labelStyle: ReportTheme.labelMedium(context),
                                hintText: 'Describe the issue in detail',
                                hintStyle: ReportTheme.labelMedium(context),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: ReportTheme.accentColor,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: ReportTheme.errorColor,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: ReportTheme.errorColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: ReportTheme.textFieldFillColor,
                              ),
                              style: ReportTheme.bodyMedium(context),
                              maxLines: 8,
                              cursorColor: ReportTheme.primaryTextColor,
                              validator: textController2Validator,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ElevatedButton(
                              onPressed: _submitReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ReportTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                                textStyle: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ReportTheme.textColorOnPrimary,
                                ),
                                foregroundColor: ReportTheme.textColorOnPrimary,
                              ),
                              child: const Text('Submit Report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}