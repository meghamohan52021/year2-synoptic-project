import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _database;

  // Constructor allows injecting FirebaseAuth and FirebaseDatabase for testing
  AuthService({FirebaseAuth? auth, FirebaseDatabase? database})
    : _auth = auth ?? FirebaseAuth.instance,
      _database = database ?? FirebaseDatabase.instance;

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String dob,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String? uid = userCredential.user?.uid;
      if (uid == null) {
        throw Exception(
          'User ID is null after successful registration. This should not happen.',
        );
      }

      // Store additional user data using the user's UID as the key
      await _database.ref().child('users').child(uid).set({
        'name': name,
        'dob': dob,
        'email': email,
        // Do NOT store the password here! Firebase Auth handles it securely.
      });

      return userCredential;
    } on FirebaseAuthException {
      rethrow; // Re-throw Firebase specific exceptions
    } catch (e) {
      rethrow; // Re-throw any other exceptions
    }
  }
}
