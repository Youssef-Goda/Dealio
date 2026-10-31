import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/features/checkout/screens/checkout_status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _RestoringAuthProvider extends AuthProvider {
  bool ready = false;
  bool loggedIn = true;
  final String restoredUserId = 'user-123';

  @override
  bool get isInitialized => ready;

  @override
  bool get isLoggedIn => loggedIn;

  @override
  String? get token => 'test-access-token';

  @override
  String get userId => restoredUserId;

  void finishRestore() {
    ready = true;
    notifyListeners();
  }
}

class _CheckoutProviderStub extends CheckoutProvider {
  int verificationCalls = 0;
  String? receivedOrderId;
  String? receivedToken;
  bool failFirstVerification = false;

  @override
  Future<String> verifyPaymentStatus(
    String orderId, {
    String? accessToken,
  }) async {
    verificationCalls++;
    receivedOrderId = orderId;
    receivedToken = accessToken;
    if (failFirstVerification && verificationCalls == 1) {
      throw Exception('Temporary network failure');
    }
    return 'paid';
  }
}

void main() {
  testWidgets(
    'checkout status waits for auth restore before verifying the returned order',
    (tester) async {
      const orderId = 'd85f3f65-fc56-4b31-8de9-c80ae1abf011';
      final auth = _RestoringAuthProvider();
      final checkout = _CheckoutProviderStub();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<CheckoutProvider>.value(value: checkout),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: CheckoutStatusScreen(orderId: orderId),
          ),
        ),
      );

      await tester.pump();

      expect(
        find.text('Checking with Paymob servers. Please wait.'),
        findsOneWidget,
      );
      expect(checkout.verificationCalls, 0);

      auth.finishRestore();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(checkout.verificationCalls, 1);
      expect(checkout.receivedOrderId, orderId);
      expect(checkout.receivedToken, 'test-access-token');
      expect(auth.userId, 'user-123');
      expect(find.text('Payment Confirmed! 🎉'), findsOneWidget);
    },
  );

  testWidgets(
    'missing session is shown as unable to verify, not payment failed',
    (tester) async {
      const orderId = 'd85f3f65-fc56-4b31-8de9-c80ae1abf011';
      final auth = _RestoringAuthProvider()
        ..ready = true
        ..loggedIn = false;
      final checkout = _CheckoutProviderStub();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<CheckoutProvider>.value(value: checkout),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: CheckoutStatusScreen(orderId: orderId),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Unable to Verify Payment'), findsOneWidget);
      expect(find.text('Payment Failed'), findsNothing);
      expect(checkout.verificationCalls, 0);
    },
  );

  test('persisted JWT session is restored when status URL cold-starts', () async {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'accessToken': 'persisted-access-token',
      'refreshToken': 'persisted-refresh-token',
      'userData':
          '{"id":"user-123","role":"user","accessToken":"persisted-access-token","refreshToken":"persisted-refresh-token"}',
    });

    final auth = AuthProvider();
    await auth.loadUserData();

    expect(auth.isInitialized, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.userId, 'user-123');
    expect(auth.token, 'persisted-access-token');
  });

  test(
    '403 authorization denial does not expire the authenticated session',
    () {
      var expired = false;
      final previousHandler = ApiService.onSessionExpired;
      ApiService.onSessionExpired = (_) => expired = true;
      addTearDown(() => ApiService.onSessionExpired = previousHandler);

      final result = ApiService.processResponse(
        http.Response('{"success":false,"message":"Access denied"}', 403),
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], 403);
      expect(expired, isFalse);
    },
  );

  testWidgets('retry re-verifies the same order and Home keeps the user', (
    tester,
  ) async {
    const orderId = 'd85f3f65-fc56-4b31-8de9-c80ae1abf011';
    final auth = _RestoringAuthProvider()..ready = true;
    final checkout = _CheckoutProviderStub()..failFirstVerification = true;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<CheckoutProvider>.value(value: checkout),
          ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ],
        child: MaterialApp(
          home: const CheckoutStatusScreen(orderId: orderId),
          routes: {'/home': (_) => const Scaffold(body: Text('Home'))},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Unable to Verify Payment'), findsOneWidget);
    expect(checkout.verificationCalls, 1);

    await tester.tap(find.text('Try Again'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(checkout.verificationCalls, 2);
    expect(checkout.receivedOrderId, orderId);
    expect(checkout.receivedToken, 'test-access-token');
    expect(find.text('Payment Confirmed! 🎉'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.userId, 'user-123');

    await tester.tap(find.text('Continue Shopping'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.userId, 'user-123');
  });
}
