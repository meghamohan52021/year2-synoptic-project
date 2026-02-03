import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _database;

  // Constructor for dependency injection
  ReportService({FirebaseAuth? auth, FirebaseDatabase? database})
      : _auth = auth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance;

  Future<void> submitReport({
    required String title,
    required String? type,
    required String description,
  }) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    final String userId = currentUser.uid;
    final DatabaseReference reportRef = _database.ref().child('reports').child(userId).push();

    try {
      await reportRef.set({
        'title': title,
        'type': type,
        'description': description,
        'timestamp': ServerValue.timestamp,
        'userId': userId,
      });
    } catch (e) {
      // You can re-throw a custom exception if you want to categorize errors
      throw Exception('Failed to submit report to database: $e');
    }
  }
}