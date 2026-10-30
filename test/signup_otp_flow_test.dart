import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:dealio/data/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/features/auth/screens/register_screen.dart';
import 'package:dealio/features/auth/screens/otp_screen.dart';

void main() {
  testWidgets('RegisterScreen prepopulates controllers from AuthProvider saved values',
      (WidgetTester tester) async {
    final authProvider = AuthProvider();
    authProvider.updateSignUpFormData(
      firstName: 'Emily',
      lastName: 'Rose',
      email: 'emily@example.com',
      password: 'SecretPassword123',
      confirmPassword: 'SecretPassword123',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Emily'), findsOneWidget);
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('emily@example.com'), findsOneWidget);
  });

  testWidgets('OtpScreen displays email and tapping email pops back to RegisterScreen',
      (WidgetTester tester) async {
    final authProvider = AuthProvider();
    authProvider.updateSignUpFormData(
      firstName: 'Emily',
      lastName: 'Rose',
      email: 'emily@example.com',
      password: 'SecretPassword123',
      confirmPassword: 'SecretPassword123',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
          ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ChangeNotifierProvider<WishlistProvider>(create: (_) => WishlistProvider()),
        ],
        child: MaterialApp(
          routes: {
            '/register': (_) => const RegisterScreen(),
            '/otp': (_) => const OtpScreen(),
          },
          home: const RegisterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify RegisterScreen is showing
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('emily@example.com'), findsOneWidget);

    // Push OtpScreen
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/otp');
    await tester.pumpAndSettle();

    // Verify OtpScreen is showing
    expect(find.text('Verification Code'), findsOneWidget);
    expect(find.text('emily@example.com'), findsOneWidget);

    // Tap email in OtpScreen to edit email
    await tester.tap(find.text('emily@example.com'));
    await tester.pumpAndSettle();

    // Verify we are back on RegisterScreen and data is preserved
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Emily'), findsOneWidget);
    expect(find.text('Rose'), findsOneWidget);
    expect(find.text('emily@example.com'), findsOneWidget);

    authProvider.stopOtpTimer();
  });

  testWidgets(
      'RegisterScreen renders without crash when AuthProvider is clean and uninitialized',
      (WidgetTester tester) async {
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets(
      'OtpScreen preserves ongoing timer state and does not forcibly restart to 59s',
      (WidgetTester tester) async {
    final authProvider = AuthProvider();
    authProvider.setPendingOtpForTesting('emily@example.com', seconds: 35);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
          ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ChangeNotifierProvider<WishlistProvider>(create: (_) => WishlistProvider()),
        ],
        child: const MaterialApp(
          home: OtpScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('0:35'), findsOneWidget);
    expect(find.text('0:59'), findsNothing);

    authProvider.stopOtpTimer();
  });
}

