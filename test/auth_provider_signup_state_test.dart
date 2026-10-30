import 'package:flutter_test/flutter_test.dart';
import 'package:dealio/data/providers/auth_provider.dart';

void main() {
  group('AuthProvider Sign Up Form State', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('initial state has empty sign up form values', () {
      expect(authProvider.signUpFormData.isEmpty, isTrue);
      expect(authProvider.signUpFirstName, isEmpty);
      expect(authProvider.signUpLastName, isEmpty);
      expect(authProvider.signUpEmail, isEmpty);
      expect(authProvider.signUpPassword, isEmpty);
      expect(authProvider.signUpConfirmPassword, isEmpty);
      expect(authProvider.tempEmail, isEmpty);
    });

    test('updateSignUpFormData updates fields and syncs tempEmail', () {
      authProvider.updateSignUpFormData(
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        password: 'Password123',
        confirmPassword: 'Password123',
      );

      expect(authProvider.signUpFormData.isEmpty, isFalse);
      expect(authProvider.signUpFirstName, equals('John'));
      expect(authProvider.signUpLastName, equals('Doe'));
      expect(authProvider.signUpEmail, equals('john@example.com'));
      expect(authProvider.signUpPassword, equals('Password123'));
      expect(authProvider.signUpConfirmPassword, equals('Password123'));
      expect(authProvider.tempEmail, equals('john@example.com'));
    });

    test('setting tempEmail directly updates signUpFormData.email', () {
      authProvider.tempEmail = 'test@domain.com';

      expect(authProvider.tempEmail, equals('test@domain.com'));
      expect(authProvider.signUpEmail, equals('test@domain.com'));
      expect(authProvider.signUpFormData.email, equals('test@domain.com'));
    });

    test('clearSignUpFormData resets all form values', () {
      authProvider.updateSignUpFormData(
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        password: 'SecurePassword1',
        confirmPassword: 'SecurePassword1',
      );

      authProvider.clearSignUpFormData();

      expect(authProvider.signUpFormData.isEmpty, isTrue);
      expect(authProvider.signUpFirstName, isEmpty);
      expect(authProvider.signUpLastName, isEmpty);
      expect(authProvider.signUpEmail, isEmpty);
      expect(authProvider.signUpPassword, isEmpty);
      expect(authProvider.signUpConfirmPassword, isEmpty);
    });

    test('SignUpFormData equality and copyWith works correctly', () {
      const data1 = SignUpFormData(
        firstName: 'Alex',
        lastName: 'Wong',
        email: 'alex@example.com',
        password: 'Pass',
        confirmPassword: 'Pass',
      );
      final data2 = const SignUpFormData().copyWith(
        firstName: 'Alex',
        lastName: 'Wong',
        email: 'alex@example.com',
        password: 'Pass',
        confirmPassword: 'Pass',
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));

      final data3 = data1.copyWith(email: 'different@example.com');
      expect(data1 == data3, isFalse);
    });

    test('updateSignUpFormData with null arguments is completely safe against copyWith errors', () {
      authProvider.updateSignUpFormData();

      expect(authProvider.signUpFormData.isEmpty, isTrue);
      expect(authProvider.signUpFirstName, equals(''));
      expect(authProvider.signUpLastName, equals(''));
      expect(authProvider.signUpEmail, equals(''));
      expect(authProvider.signUpPassword, equals(''));
      expect(authProvider.signUpConfirmPassword, equals(''));
    });

    test('accessing properties after clearSignUpFormData is never null or undefined', () {
      authProvider.updateSignUpFormData(firstName: 'Test');
      authProvider.clearSignUpFormData();

      expect(authProvider.signUpFormData, isNotNull);
      expect(authProvider.signUpFormData.firstName, equals(''));
      expect(authProvider.signUpFirstName, equals(''));
    });

    test('startOtpTimer with force: false does not reset already running timer', () {
      authProvider.startOtpTimer(seconds: 40);
      expect(authProvider.remainingSeconds, equals(40));
      expect(authProvider.isOtpTimerRunning, isTrue);

      // Attempt to start again without force: should NOT reset to 59
      authProvider.startOtpTimer(seconds: 59, force: false);
      expect(authProvider.remainingSeconds, equals(40));

      // With force: true, it should reset
      authProvider.startOtpTimer(seconds: 59, force: true);
      expect(authProvider.remainingSeconds, equals(59));

      authProvider.stopOtpTimer();
      expect(authProvider.remainingSeconds, equals(0));
    });

    test('register skips API call when resubmitting identical email with pending OTP', () async {
      // Simulate that an OTP was sent previously for user@example.com with 35s remaining
      authProvider.setPendingOtpForTesting('user@example.com', seconds: 35);
      expect(authProvider.isOtpPending, isTrue);
      expect(authProvider.remainingSeconds, equals(35));

      // Re-registering with the exact same email (even with different case or whitespace)
      final result = await authProvider.register(
        firstName: 'User',
        lastName: 'Test',
        email: '  USER@example.com  ',
        password: 'Password123',
        confirmPassword: 'Password123',
      );

      // Should return success without triggering a new network OTP call
      expect(result['success'], isTrue);
      expect(result['isExistingOtp'], isTrue);
      // Timer should NOT have been reset to 59s; it remains at existing state
      expect(authProvider.remainingSeconds, equals(35));

      authProvider.stopOtpTimer();
    });
  });
}

