// test/unit/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:move_safe/services/auth_service.dart'; // Adjust import path
import 'mocks.mocks.dart'; // Import the generated mocks

void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseDatabase mockFirebaseDatabase;
    late MockDatabaseReference mockDatabaseReference;
    late MockUserCredential mockUserCredential;
    late MockUser mockUser;
    late AuthService authService;

    // Set up mocks before each test
    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseDatabase = MockFirebaseDatabase();
      mockDatabaseReference = MockDatabaseReference();
      mockUserCredential = MockUserCredential();
      mockUser = MockUser();

      // Configure mock behaviors for common scenarios
      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => mockUserCredential);

      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_uid'); // Provide a dummy UID

      when(mockFirebaseDatabase.ref()).thenReturn(mockDatabaseReference);
      when(mockDatabaseReference.child(any)).thenReturn(mockDatabaseReference);
      // Default mock for set, to allow it to pass for successful tests
      when(mockDatabaseReference.set(any)).thenAnswer((_) async => {});

      authService = AuthService(
        auth: mockFirebaseAuth,
        database: mockFirebaseDatabase,
      );
    });

    // Tests for the registerWithEmailAndPassword method
    // This method should create a user, save their data to the database, and handle various exceptions.
    test(
      'registerWithEmailAndPassword successfully registers user and saves data',
      () async {
        // Act
        final result = await authService.registerWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
          name: 'Test User',
          dob: '01/01/2000',
        );

        // Assert
        expect(
          result,
          mockUserCredential,
        ); // Check if UserCredential is returned

        // Verify that Firebase Auth's createUserWithEmailAndPassword was called correctly
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);

        // Verify that Firebase Database's set method was called with the correct data
        verify(mockFirebaseDatabase.ref()).called(1);
        verify(mockDatabaseReference.child('users')).called(1);
        verify(mockDatabaseReference.child('test_uid')).called(1); // Check UID
        verify(
          mockDatabaseReference.set({
            'name': 'Test User',
            'dob': '01/01/2000',
            'email': 'test@example.com',
          }),
        ).called(1);
      },
    );


    // Tests for error handling in registerWithEmailAndPassword method
    // These tests ensure that the method throws appropriate exceptions for various error scenarios.
    test(
      'registerWithEmailAndPassword throws FirebaseAuthException on weak password',
      () async {
        // Arrange
        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'weak-password',
            message: 'Password is too weak.',
          ),
        );

        // Act & Assert
        await expectLater(
          // Use await expectLater for async exceptions
          authService.registerWithEmailAndPassword(
            email: 'test@example.com',
            password: '123', // Weak password
            name: 'Test User',
            dob: '01/01/2000',
          ),
          throwsA(
            isA<FirebaseAuthException>(),
          ), // Expect a FirebaseAuthException
        );

        // Verify that Firebase Auth was called
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: '123',
          ),
        ).called(1);
        // Verify that database interactions were NOT called if auth failed early
        verifyNever(mockFirebaseDatabase.ref());
      },
    );


  // Test for email already in use scenario 
    test(
      'registerWithEmailAndPassword throws FirebaseAuthException on email already in use',
      () async {
        // Arrange
        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Email already exists.',
          ),
        );

        // Act & Assert
        await expectLater(
          // Use await expectLater for async exceptions
          authService.registerWithEmailAndPassword(
            email: 'existing@example.com',
            password: 'password123',
            name: 'Test User',
            dob: '01/01/2000',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );

        // Verify that Firebase Auth was called
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'existing@example.com',
            password: 'password123',
          ),
        ).called(1);
        verifyNever(mockFirebaseDatabase.ref());
      },
    );

    // Test for null user scenario  
    test(
      'registerWithEmailAndPassword throws generic Exception if UID is null',
      () async {
        // Arrange
        when(
          mockUserCredential.user,
        ).thenReturn(null); // Simulate null user after auth

        // Act & Assert
        await expectLater(
          // Use await expectLater for async exceptions
          authService.registerWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
            name: 'Test User',
            dob: '01/01/2000',
          ),
          throwsA(isA<Exception>()),
        );

        // Verify that Firebase Auth was called, but database was not due to null UID
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
        verifyNever(mockFirebaseDatabase.ref());
      },
    );


    // Test for database write failure scenario 
    test(
      'registerWithEmailAndPassword throws Exception on database write failure',
      () async {
        // Arrange
        when(mockDatabaseReference.set(any)).thenThrow(
          FirebaseException(plugin: 'database', message: 'Network Error'),
        );

        // Act & Assert (using expectLater for async exceptions)
        await expectLater(
          authService.registerWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
            name: 'Test User',
            dob: '01/01/2000',
          ),
          throwsA(isA<Exception>()), // Expect an Exception from AuthService
        );

        // Verify both auth and database operations were attempted
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
        
        verify(mockDatabaseReference.set(argThat(isA<Map>()))).called(1);
      },
    );
  });
}
