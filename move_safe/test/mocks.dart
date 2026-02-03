// test/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:move_safe/services/auth_service.dart'; // Adjust import path

// Annotate the classes you want to mock.
// We need to mock FirebaseAuth and FirebaseDatabase for AuthService,
// and AuthService itself if you were testing a higher-level component
// that uses AuthService (e.g., a BLoC/Provider for RegisterScreen).
@GenerateMocks([
  FirebaseAuth,
  UserCredential, // Often needed to mock return values of auth methods
  User, // Often needed to mock user properties like UID
  FirebaseDatabase,
  DatabaseReference, // For FirebaseDatabase.ref()
  AuthService, // Mock AuthService for widget/integration tests
])
void main() {} // This file can be empty, its purpose is just annotations
