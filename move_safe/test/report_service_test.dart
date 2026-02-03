import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:move_safe/services/report_service.dart';
import 'mocks.mocks.dart';

void main() {
  group('ReportService', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseDatabase mockFirebaseDatabase;
    late MockDatabaseReference mockDatabaseReference;
    late ReportService reportService;

  // Setting up the mock data and services before each test
    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirebaseDatabase = MockFirebaseDatabase();
      mockDatabaseReference = MockDatabaseReference();

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_uid');

      when(mockFirebaseDatabase.ref()).thenReturn(mockDatabaseReference);
      when(mockDatabaseReference.child(any)).thenReturn(mockDatabaseReference);
      when(mockDatabaseReference.push()).thenReturn(mockDatabaseReference);
      when(mockDatabaseReference.set(any)).thenAnswer((_) async => {});
     

      reportService = ReportService(
        auth: mockFirebaseAuth,
        database: mockFirebaseDatabase,
      );
    });


// Testign the submitReport method of ReportService, making sure it correctly interacts with Firebase services.
    test('submitReport successfully sends data to Firebase', () async {
      // Arrange
      const String testTitle = 'Test Issue';
      const String testType = 'Safety Concern';
      const String testDescription = 'This is a test description.';
      const String testUserId = 'test_user_uid';

      // Act
      await reportService.submitReport(
        title: testTitle,
        type: testType,
        description: testDescription,
      );

      // Assert
      verify(mockFirebaseAuth.currentUser).called(1);
      verify(mockUser.uid).called(1);

      verify(mockFirebaseDatabase.ref()).called(1);
      verify(mockDatabaseReference.child('reports')).called(1);
      verify(mockDatabaseReference.child(testUserId)).called(1);
      verify(mockDatabaseReference.push()).called(1);

      
      verify(
        mockDatabaseReference.set(
          argThat(
            allOf(
              containsPair('title', testTitle),
              containsPair('type', testType),
              containsPair('description', testDescription),
              containsPair('userId', testUserId),
              // Match the actual ServerValue.timestamp structure
              containsPair('timestamp', ServerValue.timestamp),
            ),
          ),
        ),
      ).called(1);
   
    });


    // Testing the error handling of submitReport when the user is not logged in
    test('submitReport throws Exception if user is not logged in', () async {
      // Arrange
      when(
        mockFirebaseAuth.currentUser,
      ).thenReturn(null); // Simulate no logged-in user

      // Act & Assert
      await expectLater(
        reportService.submitReport(
          title: 'Test Title',
          type: 'Other',
          description: 'Description',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not logged in.'),
          ),
        ),
      );

      verify(mockFirebaseAuth.currentUser).called(1);
      verifyNever(mockFirebaseDatabase.ref());
    });

// Testing the error handling of submitReport when there is a failure in writing to the database
    test('submitReport throws Exception on database write failure', () async {
      // Arrange
      when(mockDatabaseReference.set(any)).thenThrow(
        FirebaseException(plugin: 'database', message: 'Network Error'),
      );

      // Act & Assert
      await expectLater(
        reportService.submitReport(
          title: 'Failing Report',
          type: 'Other',
          description: 'This should fail',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to submit report to database'),
          ),
        ),
      );

      verify(mockFirebaseAuth.currentUser).called(1);
      verify(mockUser.uid).called(1);
      verify(mockDatabaseReference.set(argThat(isA<Map>()))).called(1);
    });


// Testing the submitReport method with a null type, ensuring it handles null values correctly  
    test('submitReport handles null type gracefully', () async {
      // Arrange
      const String testTitle = 'Test Issue with Null Type';
      const String? testType = null;
      const String testDescription =
          'This is a test description with a null type.';
      const String testUserId = 'test_user_uid';

      // Act
      await reportService.submitReport(
        title: testTitle,
        type: testType,
        description: testDescription,
      );

      // Assert
      final captured =
          verify(mockDatabaseReference.set(captureAny)).captured.single
              as Map<String, dynamic>;
      expect(captured['title'], testTitle);
      expect(captured['type'], isNull);
      expect(captured['description'], testDescription);
      expect(captured['userId'], testUserId);
    });
  });
}
