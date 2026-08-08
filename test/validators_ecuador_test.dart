import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/utils/validators/validators.dart';

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

    // Email Validation Tests
    group('Email Validation Tests', () {
      test('Valid email: user@example.com', () {
        expect(Validators.isValidEmail('user@example.com'), true);
      });

      test('Valid email: juan.garcia@gmail.com', () {
        expect(Validators.isValidEmail('juan.garcia@gmail.com'), true);
      });

      test('Valid email: test.mail+tag@domain.co.uk', () {
        expect(Validators.isValidEmail('test.mail+tag@domain.co.uk'), true);
      });

      test('Valid email: contact@empresa.ec', () {
        expect(Validators.isValidEmail('contact@empresa.ec'), true);
      });

      test('Invalid: empty string', () {
        expect(Validators.isValidEmail(''), false);
      });

      test('Invalid: no @ symbol', () {
        expect(Validators.isValidEmail('invalidemail.com'), false);
      });

      test('Invalid: no domain', () {
        expect(Validators.isValidEmail('user@'), false);
      });

      test('Invalid: no local part', () {
        expect(Validators.isValidEmail('@example.com'), false);
      });

      test('Invalid: multiple @ symbols', () {
        expect(Validators.isValidEmail('user@@example.com'), false);
      });

      test('Invalid: spaces in email', () {
        expect(Validators.isValidEmail('user @example.com'), false);
      });

      test('Invalid: no extension', () {
        expect(Validators.isValidEmail('user@example'), false);
      });

      test('Invalid: special chars in domain', () {
        expect(Validators.isValidEmail('user@exam ple.com'), false);
      });
    });

    // Name Validation Tests
    group('Name Validation Tests', () {
      test('Valid name: Juan García', () {
        expect(Validators.isValidName('Juan García'), true);
      });

      test('Valid name: María José', () {
        expect(Validators.isValidName('María José'), true);
      });

      test('Valid name: José Luis Pérez', () {
        expect(Validators.isValidName('José Luis Pérez'), true);
      });

      test('Valid name: Ana', () {
        expect(Validators.isValidName('Ana'), true);
      });

      test('Valid name: with accents Ángela Álvarez', () {
        expect(Validators.isValidName('Ángela Álvarez'), true);
      });

      test('Valid name: with ñ Peña Nieto', () {
        expect(Validators.isValidName('Peña Nieto'), true);
      });

      test('Valid name: with ü Müller', () {
        expect(Validators.isValidName('Müller'), true);
      });

      test('Invalid: contains numbers', () {
        expect(Validators.isValidName('Juan123'), false);
      });

      test('Invalid: contains special chars', () {
        expect(Validators.isValidName('Juan@García'), false);
      });

      test('Invalid: only spaces', () {
        expect(Validators.isValidName('   '), false);
      });

      test('Invalid: empty string', () {
        expect(Validators.isValidName(''), false);
      });

      test('Invalid: contains symbols', () {
        expect(Validators.isValidName('Juan-García!'), false);
      });
    });

    // Age Validation Tests
    group('Age Validation Tests', () {
      test('Valid age: 25', () {
        expect(Validators.isValidAge('25'), true);
      });

      test('Valid age: 1 minimum', () {
        expect(Validators.isValidAge('1'), true);
      });

      test('Valid age: 120 maximum', () {
        expect(Validators.isValidAge('120'), true);
      });

      test('Valid age: 18', () {
        expect(Validators.isValidAge('18'), true);
      });

      test('Valid age: 65', () {
        expect(Validators.isValidAge('65'), true);
      });

      test('Invalid: 0 below minimum', () {
        expect(Validators.isValidAge('0'), false);
      });

      test('Invalid: 121 above maximum', () {
        expect(Validators.isValidAge('121'), false);
      });

      test('Invalid: negative number', () {
        expect(Validators.isValidAge('-5'), false);
      });

      test('Invalid: non-numeric', () {
        expect(Validators.isValidAge('twenty-five'), false);
      });

      test('Invalid: empty string', () {
        expect(Validators.isValidAge(''), false);
      });

      test('Invalid: decimal number', () {
        expect(Validators.isValidAge('25.5'), false);
      });

      test('Invalid: very large number', () {
        expect(Validators.isValidAge('999'), false);
      });
    });

    // Password Validation Tests
    group('Password Validation Tests', () {
      test('Valid password: SecurePass123!', () {
        expect(Validators.isValidPassword('SecurePass123!'), true);
      });

      test('Valid password: MyPassword@2024', () {
        expect(Validators.isValidPassword('MyPassword@2024'), true);
      });

      test('Valid password: Complex\$Pass99', () {
        expect(Validators.isValidPassword('Complex\$Pass99'), true);
      });

      test('Valid password: Secure&Pass01', () {
        expect(Validators.isValidPassword('Secure&Pass01'), true);
      });

      test('Valid password: TestPassword*88', () {
        expect(Validators.isValidPassword('TestPassword*88'), true);
      });

      test('Valid password: Strong?Pass777', () {
        expect(Validators.isValidPassword('Strong?Pass777'), true);
      });

      test('Valid password: Super%Pass444', () {
        expect(Validators.isValidPassword('Super%Pass444'), true);
      });

      test('Invalid: too short Pass1!', () {
        expect(Validators.isValidPassword('Pass1!'), false);
      });

      test('Invalid: no uppercase', () {
        expect(Validators.isValidPassword('password123!'), false);
      });

      test('Invalid: no number', () {
        expect(Validators.isValidPassword('SecurePass!'), false);
      });

      test('Invalid: no special char', () {
        expect(Validators.isValidPassword('SecurePass123'), false);
      });

      test('Invalid: empty string', () {
        expect(Validators.isValidPassword(''), false);
      });

      test('Invalid: spaces in password', () {
        expect(Validators.isValidPassword('Secure Pass!1'), false);
      });
    });

    // String Length Validation Tests
    group('String Length Validation Tests', () {
      test('isNotEmpty: valid string', () {
        expect(Validators.isNotEmpty('hello'), true);
      });

      test('isNotEmpty: empty string', () {
        expect(Validators.isNotEmpty(''), false);
      });

      test('isNotEmpty: only spaces', () {
        expect(Validators.isNotEmpty('   '), false);
      });

      test('hasMinLength: meets minimum', () {
        expect(Validators.hasMinLength('hello', 5), true);
      });

      test('hasMinLength: below minimum', () {
        expect(Validators.hasMinLength('hi', 5), false);
      });

      test('hasMaxLength: within maximum', () {
        expect(Validators.hasMaxLength('hello', 10), true);
      });

      test('hasMaxLength: exceeds maximum', () {
        expect(Validators.hasMaxLength('hello world', 5), false);
      });

      test('hasValidLength: within range', () {
        expect(Validators.hasValidLength('hello', 3, 10), true);
      });

      test('hasValidLength: below range', () {
        expect(Validators.hasValidLength('hi', 3, 10), false);
      });

      test('hasValidLength: exceeds range', () {
        expect(Validators.hasValidLength('hello world!!!', 3, 10), false);
      });

      test('hasValidLength: exact minimum', () {
        expect(Validators.hasValidLength('abc', 3, 10), true);
      });

      test('hasValidLength: exact maximum', () {
        expect(Validators.hasValidLength('abcdefghij', 3, 10), true);
      });
    });
  });
}
