import 'package:campus_incident_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.required', () {
    test('rejects empty and whitespace-only values', () {
      expect(Validators.required(null, 'Title'), 'Title is required');
      expect(Validators.required('', 'Title'), 'Title is required');
      expect(Validators.required('   ', 'Title'), 'Title is required');
    });

    test('accepts text', () {
      expect(Validators.required('Broken tap', 'Title'), isNull);
    });
  });

  group('Validators.name', () {
    test('rejects empty and too-short names', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('A'), isNotNull);
    });

    test('accepts a normal name', () {
      expect(Validators.name('Mitchell'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects empty and badly formatted emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('mitchell'), isNotNull);
      expect(Validators.email('mitchell@alu'), isNotNull);
      expect(Validators.email('mit chell@alu.edu'), isNotNull);
    });

    test('accepts a valid email, ignoring surrounding spaces', () {
      expect(Validators.email('m.barure@alustudent.com'), isNull);
      expect(Validators.email('  m.barure@alustudent.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty and short passwords', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
    });

    test('accepts a password of the minimum length', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('report form validators', () {
    test('incidentTitle requires text and limits length', () {
      expect(Validators.incidentTitle(''), isNotNull);
      expect(Validators.incidentTitle('a' * 81), isNotNull);
      expect(Validators.incidentTitle('Broken window'), isNull);
    });

    test('description needs at least 10 characters', () {
      expect(Validators.description(''), isNotNull);
      expect(Validators.description('Broken'), isNotNull);
      expect(Validators.description('The window is cracked.'), isNull);
    });

    test('location is required', () {
      expect(Validators.location('  '), isNotNull);
      expect(Validators.location('Library'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects an empty or different confirmation', () {
      expect(Validators.confirmPassword('', 'secret1'), isNotNull);
      expect(
        Validators.confirmPassword('secret2', 'secret1'),
        'Passwords do not match',
      );
    });

    test('accepts a matching confirmation', () {
      expect(Validators.confirmPassword('secret1', 'secret1'), isNull);
    });
  });
}
