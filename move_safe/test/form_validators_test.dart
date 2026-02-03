//test/register_test.dart
// This file contains unit tests for the registration form validators.
import 'package:flutter_test/flutter_test.dart';


import 'package:move_safe/utils/form_validator.dart'; // Adjust path if needed

void main() {
  group('FormValidators', () {
    group('validateName', () {

      // Tests for name validation
      // A valid name should return null, while empty or null names should return an error message.
      test('should return null for a valid name', () {
        expect(FormValidators.validateName('John Doe'), isNull);
      });
      test('should return error message for empty name', () {
        expect(FormValidators.validateName(''), 'Please enter your name');
      });
      test('should return error message for null name', () {
        expect(FormValidators.validateName(null), 'Please enter your name');
      });
    });

    group('validateEmail', () {

      // Tests for email validation
      // A valid email should return null, while invalid ones should return an error message.
      test('should return null for a valid email', () {
        expect(FormValidators.validateEmail('test@example.com'), isNull);
      });
      test('should return error message for empty email', () {
        expect(FormValidators.validateEmail(''), 'Please enter your email');
      });
      test('should return error message for null email', () {
        expect(FormValidators.validateEmail(null), 'Please enter your email');
      });
      test('should return error message for invalid email format', () {
        expect(
          FormValidators.validateEmail('invalid-email'),
          'Please enter a valid email',
        );
        expect(
          FormValidators.validateEmail('test@.com'),
          'Please enter a valid email',
        );
        expect(
          FormValidators.validateEmail('test@com'),
          'Please enter a valid email',
        );
      });
    });

    group('validatePassword', () {
      // Tests for password validation
      // A valid password (6 or more characters) should return null, while invalid ones should return an error message.
      test('should return null for a valid password (>= 6 chars)', () {
        expect(FormValidators.validatePassword('password123'), isNull);
        expect(FormValidators.validatePassword('123456'), isNull); // Exactly 6
      });
      test('should return error message for empty password', () {
        expect(FormValidators.validatePassword(''), 'Please enter a password');
      });
      test('should return error message for null password', () {
        expect(
          FormValidators.validatePassword(null),
          'Please enter a password',
        );
      });
      test(
        'should return error message for password less than 6 characters',
        () {
          expect(
            FormValidators.validatePassword('short'),
            'Password must be at least 6 characters',
          ); // 5 chars
        },
      );
    });

    group('validateConfirmPassword', () {

      // Tests for confirm password validation
      // It should return null if the passwords match, an error message if they do not, and handle empty/null confirm passwords.
      test('should return null if passwords match', () {
        expect(
          FormValidators.validateConfirmPassword('password123', 'password123'),
          isNull,
        );
      });
      test('should return error message if passwords do not match', () {
        expect(
          FormValidators.validateConfirmPassword('password123', 'passwordABC'),
          'Passwords do not match',
        );
      });
      test('should return error message for empty confirm password', () {
        expect(
          FormValidators.validateConfirmPassword('', 'password123'),
          'Please confirm your password',
        );
      });
      test('should return error message for null confirm password', () {
        expect(
          FormValidators.validateConfirmPassword(null, 'password123'),
          'Please confirm your password',
        );
      });
    });

    group('validateDob', () {

      // Tests for date of birth validation
      // A valid date of birth should return null, while invalid formats or empty/null values should return an error message.
      test('should return null for a valid date of birth', () {
        // Simple validation only checks for non-empty string as per the current code
        expect(FormValidators.validateDob('01/01/2000'), isNull);
      });
      test('should return error message for empty date of birth', () {
        expect(
          FormValidators.validateDob(''),
          'Please enter your date of birth',
        );
      });
      test('should return error message for null date of birth', () {
        expect(
          FormValidators.validateDob(null),
          'Please enter your date of birth',
        );
      });
      
    });
  });
}
