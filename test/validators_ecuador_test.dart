import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/validators/validators.dart';

void main() {
  group('Ecuador Phone Validation Tests', () {
    // Test local Ecuador format: 0963522505
    group('Local Ecuador Format (09XXXXXXXX)', () {
      test('Valid local format: 0963522505', () {
        expect(Validators.isValidPhone('0963522505'), true);
      });

      test('Valid with spaces: 09 6352 2505', () {
        expect(Validators.isValidPhone('09 6352 2505'), true);
      });

      test('Valid with dashes: 09-6352-2505', () {
        expect(Validators.isValidPhone('09-6352-2505'), true);
      });

      test('Invalid: 8 digits instead of 10', () {
        expect(Validators.isValidPhone('0963522'), false);
      });

      test('Invalid: 12 digits', () {
        expect(Validators.isValidPhone('096352250505'), false);
      });

      test('Invalid: starts with 08', () {
        expect(Validators.isValidPhone('0863522505'), false);
      });

      test('Invalid: starts with 07', () {
        expect(Validators.isValidPhone('0763522505'), false);
      });

      test('Invalid: empty string', () {
        expect(Validators.isValidPhone(''), false);
      });

      test('Invalid: only spaces', () {
        expect(Validators.isValidPhone('   '), false);
      });
    });

    // Test international Ecuador format with +593
    group('International Ecuador Format (+593XXXXXXXXX)', () {
      test('Valid international: +593963522505', () {
        expect(Validators.isValidPhone('+593963522505'), true);
      });

      test('Valid international without +: 593963522505', () {
        expect(Validators.isValidPhone('593963522505'), true);
      });

      test('Valid international with spaces: +593 963 522 505', () {
        expect(Validators.isValidPhone('+593 963 522 505'), true);
      });

      test('Valid international with dashes: +593-963-522-505', () {
        expect(Validators.isValidPhone('+593-963-522-505'), true);
      });

      test('Invalid: wrong country code +591 (Bolivia)', () {
        expect(Validators.isValidPhone('+591963522505'), false);
      });

      test('Invalid: wrong country code +56 (Chile)', () {
        expect(Validators.isValidPhone('+56963522505'), false);
      });

      test('Invalid: 8 digits after country code', () {
        expect(Validators.isValidPhone('+59396352250'), false);
      });
    });

    // Test invalid international formats (specifically rejecting US +1)
    group('Invalid International Formats', () {
      test('Reject US format: +11234567890', () {
        expect(Validators.isValidPhone('+11234567890'), false);
      });

      test('Reject US format without +: 11234567890', () {
        expect(Validators.isValidPhone('11234567890'), false);
      });

      test('Reject Colombia: +573105555555', () {
        expect(Validators.isValidPhone('+573105555555'), false);
      });

      test('Reject Peru: +51987654321', () {
        expect(Validators.isValidPhone('+51987654321'), false);
      });

      test('Reject invalid prefix: +593123', () {
        expect(Validators.isValidPhone('+593123'), false);
      });
    });

    // Test normalization to LOCAL format
    group('Phone Normalization (LOCAL Format)', () {
      test('Normalize local format: 0963522505 → 0963522505', () {
        final result = Validators.normalizePhoneNumber('0963522505');
        expect(result, '0963522505');
      });

      test('Normalize with spaces: 09 6352 2505 → 0963522505', () {
        final result = Validators.normalizePhoneNumber('09 6352 2505');
        expect(result, '0963522505');
      });

      test('Normalize with dashes: 09-6352-2505 → 0963522505', () {
        final result = Validators.normalizePhoneNumber('09-6352-2505');
        expect(result, '0963522505');
      });

      test('Normalize international +: +593963522505 → 0963522505', () {
        final result = Validators.normalizePhoneNumber('+593963522505');
        expect(result, '0963522505');
      });

      test('Normalize international no +: 593963522505 → 0963522505', () {
        final result = Validators.normalizePhoneNumber('593963522505');
        expect(result, '0963522505');
      });

      test('Normalize international with spaces: +593 963 522 505 → 0963522505', () {
        final result = Validators.normalizePhoneNumber('+593 963 522 505');
        expect(result, '0963522505');
      });

      test('Normalize mixed: +593-963-522-505 → 0963522505', () {
        final result = Validators.normalizePhoneNumber('+593-963-522-505');
        expect(result, '0963522505');
      });
    });

    // Test conversion to INTERNATIONAL format
    group('Phone International Format Conversion', () {
      test('Convert local to international: 0963522505 → +593963522505', () {
        final result = Validators.getInternationalFormat('0963522505');
        expect(result, '+593963522505');
      });

      test('Convert with spaces: 09 6352 2505 → +593963522505', () {
        final result = Validators.getInternationalFormat('09 6352 2505');
        expect(result, '+593963522505');
      });

      test('Convert already international: +593963522505 → +593963522505', () {
        final result = Validators.getInternationalFormat('+593963522505');
        expect(result, '+593963522505');
      });

      test('Convert no + international: 593963522505 → +593963522505', () {
        final result = Validators.getInternationalFormat('593963522505');
        expect(result, '+593963522505');
      });
    });

    // Test conversion to LOCAL format
    group('Phone Local Format Conversion', () {
      test('Convert international to local: +593963522505 → 0963522505', () {
        final result = Validators.getLocalFormat('+593963522505');
        expect(result, '0963522505');
      });

      test('Convert no + to local: 593963522505 → 0963522505', () {
        final result = Validators.getLocalFormat('593963522505');
        expect(result, '0963522505');
      });

      test('Already local: 0963522505 → 0963522505', () {
        final result = Validators.getLocalFormat('0963522505');
        expect(result, '0963522505');
      });

      test('With spaces: +593 963 522 505 → 0963522505', () {
        final result = Validators.getLocalFormat('+593 963 522 505');
        expect(result, '0963522505');
      });
    });

    // Test other validators (should still work)
    group('Other Validators', () {
      test('Valid email', () {
        expect(Validators.isValidEmail('user@example.com'), true);
      });

      test('Invalid email', () {
        expect(Validators.isValidEmail('invalid-email'), false);
      });

      test('Valid name', () {
        expect(Validators.isValidName('Juan García'), true);
      });

      test('Invalid name - numbers', () {
        expect(Validators.isValidName('Juan123'), false);
      });

      test('Valid age', () {
        expect(Validators.isValidAge('25'), true);
      });

      test('Invalid age - under 1', () {
        expect(Validators.isValidAge('0'), false);
      });

      test('Valid password', () {
        expect(Validators.isValidPassword('SecurePass123!'), true);
      });

      test('Invalid password - too short', () {
        expect(Validators.isValidPassword('Pass1!'), false);
      });
    });
  });
}
