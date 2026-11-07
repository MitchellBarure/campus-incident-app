/// Form validators.
///
/// Each function follows Flutter's validator rule: return null when the
/// value is valid, or an error message to show under the field.
/// They are plain functions (no widgets), so they are easy to unit test.
class Validators {
  /// Firebase Auth rejects passwords shorter than 6 characters.
  static const int minPasswordLength = 6;

  // A simple "something@something.something" check. Firebase does the
  // strict check when signing in, this just catches obvious typos early.
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// A field that just must not be empty, e.g. "Title is required".
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    return null;
  }

  // Limits for the Report Incident form.
  static const int maxTitleLength = 80;
  static const int minDescriptionLength = 10;

  static String? incidentTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }
    if (value.trim().length > maxTitleLength) {
      return 'Title must be $maxTitleLength characters or fewer';
    }
    return null;
  }

  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe the issue';
    }
    if (value.trim().length < minDescriptionLength) {
      return 'Please add a bit more detail (at least '
          '$minDescriptionLength characters)';
    }
    return null;
  }

  static String? location(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please say where the issue is';
    }
    return null;
  }

  /// Checks the "confirm password" field matches the first password.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
