import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';                
import 'package:firebase_auth/firebase_auth.dart'; 
import "package:http/http.dart" as http; 
import 'dart:convert'; 
import 'package:firebase_database/firebase_database.dart'; 

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});
  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // file picker for chrome
  PlatformFile? _imagePicked;
  Future<void> _pickImage() async {
    try{
      // opens files
      FilePickerResult? result = await FilePicker.platform.pickFiles( 
        allowMultiple:false,
        type: FileType.custom, 
        allowedExtensions: ['jpeg', 'png', 'pdf', 'docx']
      );
      // if file wasnt selected
      if (result == null) {
        return;
      }
      // change icon when added
      setState(() {
        _imagePicked = result.files.first;
      });
      print('file picker works');
    }  catch(e){
      // if file picker doesnt work
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      print('file picker doesnt work');
    }
  }

  // uploading
  Future<void> _uploadImage() async {
    // if file was not picked
    if (_imagePicked == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload image of Authentication ID.')));
      print('authenticate button clicked, but no file uploaded');
      return;
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    } 
    // uploading to clodinary, making http post request
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dlzkt9fkh/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'preset-for-file-upload'
      ..files.add(http.MultipartFile.fromBytes('file', _imagePicked!.bytes!, filename: _imagePicked!.name,));
    
    final response = await request.send();

    if (response.statusCode == 200) {
      // getting the url from response
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      final secureUrl = jsonMap['secure_url'];

      // adding authentication id url to the firebase , under the current user
      final _auth = FirebaseAuth.instance;
      User? firebaseUser = _auth.currentUser;
      final firebaseID = firebaseUser!.uid;
      final databaseReference = FirebaseDatabase.instance.ref();
      databaseReference.child('users').child('$firebaseID').child('Authentication ID').set(secureUrl);
    } else {
      // error handling
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error. Failed to upload ID")));
    }
  } 

  // UI for authenticate id page
  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF7F4FEB), 
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          actions: const [],
          centerTitle: false,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0, 0),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: const AlignmentDirectional(0, 0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 10),
                      child: Text(
                        'MoveSafe',
                        style: GoogleFonts.leagueSpartan(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 80,
                          letterSpacing: 0.0,
                          fontStyle: FontStyle.normal, 
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const AlignmentDirectional(0, 0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
                      child: Container(
                        width: 324.9,
                        height: 435.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 4,
                              color: Color(0x33000000),
                              offset: Offset(0, 2),
                            )
                          ],
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          border: Border.all(
                            color: Colors.black,
                            width: 4,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Align(
                                  alignment: const AlignmentDirectional(0, -1),
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(40, 50, 40, 0),
                                    child: Text(
                                      'Upload an ID document to verify your identity',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 19,
                                        letterSpacing: 0.0,
                                        fontStyle: FontStyle.normal,
                                        textStyle: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(23, 2, 23, 3),
                                  child: Text(
                                    'Valid forms of ID: Driver’s License, Passport, Birth Certificate, Utility Bill',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      letterSpacing: 0.0,
                                      fontStyle: FontStyle.normal,
                                      textStyle: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    print('Icon pressed');
                                    _pickImage();
                                  },
                                  child: _imagePicked != null
                                    ? const Icon(
                                      Icons.check_circle,  
                                      color: Colors.green,
                                      size: 150,
                                      )
                                    : const Icon(
                                      Icons.drive_folder_upload_rounded, 
                                      color: Color(0xFFBDBDBD),
                                      size: 150,
                                      ),
                                ),
                                Align(
                                  alignment: const AlignmentDirectional(0, 0),
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(0, 3, 0, 0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _uploadImage(); 
                                      },
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(130, 42),
                                        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                                        backgroundColor: const Color(0xFF424242),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Authenticate',
                                        style: GoogleFonts.interTight(
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle: FontStyle.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: const AlignmentDirectional(0, 0),
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.fromSTEB(23, 20, 23, 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: const AlignmentDirectional(0, 0),
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional.fromSTEB(15, 0, 0, 0),
                                            child: Text(
                                              'Already have an account?',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 15,
                                                letterSpacing: 0.0,
                                                fontStyle: FontStyle.normal,
                                                textStyle: TextStyle(color: Colors.black),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: const AlignmentDirectional(0, 0),
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional.fromSTEB(5, 0, 15, 0),
                                            child: InkWell(
                                              onTap: () {
                                                print('Login clicked');
                                                Navigator.pushReplacementNamed(context, '/login');     
                                              },
                                              child: Text(
                                                'Login',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  letterSpacing: 0.0,
                                                  fontStyle: FontStyle.normal,
                                                  textStyle: TextStyle(color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}