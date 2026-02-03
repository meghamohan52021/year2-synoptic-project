
import 'package:intl/intl.dart'; // You might need to add this to your pubspec.yaml: dependencies: intl: ^0.18.1

class FormValidators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }



  static String? validateDob(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your date of birth';
    }

    try {
      // Use DateFormat to parse the date string in "dd/MM/yyyy" format.
      // The format "dd/MM/yyyy" means:
      // dd - day of the month (e.g., 01, 15)
      // MM - month (e.g., 01, 12)
      // yyyy - year (e.g., 2023)
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final DateTime dob = formatter.parseStrict(value); // Use parseStrict for exact format matching
      final DateTime now = DateTime.now();

      // Calculate age by years.
      int age = now.year - dob.year;

      // Adjust age if the birthday hasn't occurred yet this year
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      const int minimumAge = 5;
      if (age < minimumAge) {
        return 'You must be at least $minimumAge years old.';
      }

    } on FormatException {
      return 'Please enter a valid date format (e.g., DD/MM/YYYY).';
    } catch (e) {
      // Catch any other potential errors during date processing
      return 'An error occurred while validating your date of birth.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
