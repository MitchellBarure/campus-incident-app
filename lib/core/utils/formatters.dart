import 'package:intl/intl.dart';

/// Date formats used across the app, kept in one place so they match.
class Formatters {
  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm');

  /// e.g. "6 Nov 2026"
  static String shortDate(DateTime date) => _shortDate.format(date);

  /// e.g. "6 Nov 2026, 14:05"
  static String dateTime(DateTime date) => _dateTime.format(date);

  /// "Amina Uwase" -> "Amina". Used for the "Hello, ..." greeting.
  static String firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(' ').first;
  }
}
