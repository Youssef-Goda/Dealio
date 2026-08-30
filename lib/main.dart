import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/core/constants/app_roles.dart';
import 'package:dealio/core/widgets/guarded_route.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/category_provider.dart';
import 'package:dealio/data/providers/product_provider.dart';
import 'package:dealio/data/providers/user_provider.dart';
import 'package:dealio/data/providers/theme_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:dealio/data/providers/wishlist_provider.dart';
import 'package:dealio/data/providers/checkout_provider.dart';
import 'package:dealio/data/providers/orders_provider.dart';
import 'package:dealio/data/providers/settings_provider.dart';
import 'package:dealio/data/services/notification_service.dart';
import 'package:dealio/core/theme/app_theme.dart';
import 'package:dealio/features/admin/screens/admin_dashboard_screen.dart';
import 'package:dealio/features/admin/screens/vendor_dashboard_screen.dart';
import 'package:dealio/features/admin/screens/moderation_dashboard_screen.dart';
import 'package:dealio/features/auth/screens/forgot_password.dart';
import 'package:dealio/features/auth/screens/login_screen.dart';
import 'package:dealio/features/auth/screens/otp_screen.dart';
import 'package:dealio/features/auth/screens/register_screen.dart';
import 'package:dealio/features/home/screens/home_screen.dart';
import 'package:dealio/features/checkout/screens/checkout_screen.dart';
import 'package:dealio/features/checkout/screens/checkout_status_screen.dart';
import 'package:dealio/features/orders/screens/order_success_screen.dart';
import 'package:dealio/features/orders/screens/my_orders_screen.dart';
import 'package:dealio/features/orders/screens/order_detail_screen.dart';
import 'package:dealio/features/owner/screens/platform_control_screen.dart';
import 'package:dealio/features/location/screens/location_onboarding_screen.dart';
import 'package:dealio/features/settings/screens/settings_screen.dart';
import 'package:dealio/features/settings/screens/about_screen.dart';
import 'package:dealio/features/settings/screens/store_settings_screen.dart';
import 'package:dealio/data/services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoogleFonts.config.allowRuntimeFetching = true;

  // 1. Register FCM background handler BEFORE Firebase.initializeApp()
  //    Must be a top-level function — see notification_service.dart
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized");
  } catch (e) {
    debugPrint("❌ Firebase Init Error: $e");
  }

  // 3. Initialize NotificationService (permissions + local plugin + listeners)
  //    Wrap in try/catch so a notification failure never blocks the app.
  try {
    await NotificationService.instance.initialize(navigatorKey);
  } catch (e) {
    debugPrint("⚠️ NotificationService init error: $e");
  }

  // 4. Initialize Supabase
  try {
    final jsonString = await rootBundle.loadString('assets/env.json');
    final config = json.decode(jsonString);
    await Supabase.initialize(
      url: config['SUPABASE_URL'],
      anonKey: config['SUPABASE_ANON_KEY'],
    );
    debugPrint("✅ Supabase initialized");
  } catch (e) {
    debugPrint("❌ Init Error: $e");
  }

  // 5. Prepare AuthProvider and load saved session BEFORE runApp
  final authProvider = AuthProvider();

  // Restore session immediately if Supabase has one
  try {
    final initialSession = Supabase.instance.client.auth.currentSession;

    await authProvider.loadUserData();

    if (!authProvider.isLoggedIn) {
      final initialSession = Supabase.instance.client.auth.currentSession;

      if (initialSession != null) {
        await authProvider.handleGoogleSuccess(initialSession);
      }
    }

    // if (initialSession != null) {
    //   await authProvider.handleGoogleSuccess(initialSession);
    //   debugPrint(
    //     '⚡ Startup: Session restored for ${initialSession.user.email}',
    //   );
    // } else {
    //   await authProvider.loadUserData();
    // }
  } catch (e) {
    debugPrint(
      '⚠️ Initial auth session restore error (ignoring non-auth deep link query params): $e',
    );
    await authProvider.loadUserData();
  }

  // 6. Auth state listener (for background updates, e.g. Google sign-in callback)
  Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) {
      try {
        if (data.session != null) {
          ProfileProvider? profileProvider;
          try {
            final context = navigatorKey.currentContext;
            if (context != null) {
              profileProvider = Provider.of<ProfileProvider>(
                context,
                listen: false,
              );
            }
          } catch (_) {}

          authProvider.handleGoogleSuccess(
            data.session!,
            profileProvider: profileProvider,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Auth state change error (ignored): $e');
      }
    },
    onError: (err) {
      debugPrint(
        '⚠️ Supabase auth listener error (ignored for payment deep links): $err',
      );
    },
  );

  // 5. Wire ApiService session-expired callback
  ApiService.onSessionExpired = () {
    if (authProvider.isLoggedIn) {
      if (navigatorKey.currentContext != null) {
        authProvider.logout(navigatorKey.currentContext!);
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (r) => false,
        );
      }
    }
  };

  // 6. Load wishlist
  final wishlistProvider = WishlistProvider();
  await wishlistProvider.load();

  if (!kIsWeb) FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        // CRITICAL: .value preserves the pre-loaded auth state
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: wishlistProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..fetchCategories(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // ProfileProvider is seeded from AuthProvider automatically
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, auth, prev) {
            final profile = prev ?? ProfileProvider();
            if (auth.isInitialized && auth.isLoggedIn && auth.user.isNotEmpty) {
              profile.loadFromUser(auth.user);
            }
            return profile;
          },
        ),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(
          create: (_) => StoreSettingsProvider()..fetchPublicSettings(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Dealio',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Use AuthProvider state directly — no StreamBuilder race condition
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // Still loading session from SharedPrefs/Supabase — show spinner
                if (!auth.isInitialized) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                // ── Paymob callback deep-link detection ────────────────────
                // When the user completes card/wallet payment, Paymob redirects
                // the browser to:
                //   <FRONTEND_URL>/checkout/status?order_id=...&success=...
                //
                // Flutter web re-initializes fresh (cold start) at this URL.
                // Without this check, the Consumer builder would return
                // HomeScreen (for logged-in users) and the status screen would
                // never be shown.
                //
                // We check AFTER auth.isInitialized so CheckoutStatusScreen
                // has access to authenticated providers (JWT, CheckoutProvider).
                //
                // usePathUrlStrategy() is active, so the path is in Uri.base.path
                // (not the fragment). The backend callback now sends a plain path
                // URL: /checkout/status?... (no hash prefix).
                if (kIsWeb) {
                  final path = Uri.base.path;
                  if (path == '/checkout/status' ||
                      path.startsWith('/checkout/status?') ||
                      path.startsWith('/checkout/status/')) {
                    return const CheckoutStatusScreen();
                  }
                }

                // Session loaded — route based on login state
                return auth.isLoggedIn
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
            onGenerateRoute: (settings) {
              final name = settings.name ?? '';
              final uri = Uri.tryParse(name);

              if (uri != null) {
                final path = uri.path.isNotEmpty ? uri.path : uri.host;
                if (path == 'checkout-status' ||
                    path == '/checkout-status' ||
                    path == '/checkout/status' ||
                    path.contains('checkout-status') ||
                    path.contains('checkout/status') ||
                    name.contains('checkout-status') ||
                    name.contains('checkout/status')) {
                  return MaterialPageRoute(
                    builder: (_) => const CheckoutStatusScreen(),
                    settings: settings,
                  );
                }
              }

              final builder = {
                '/login': (context) => const LoginScreen(),
                '/register': (context) => const RegisterScreen(),
                '/home': (context) => const HomeScreen(),
                '/otp': (context) => const OtpScreen(),
                '/forgotPassword': (context) => const ForgotPassword(),
                '/checkout': (context) => const CheckoutScreen(),
                '/checkout/status': (context) => const CheckoutStatusScreen(),
                '/order-success': (context) => const OrderSuccessScreen(),
                '/my-orders': (context) => const MyOrdersScreen(),
                '/order-detail': (context) => const OrderDetailScreen(),
                '/location-onboarding': (context) =>
                    const LocationOnboardingScreen(),
              }[name];

              if (builder != null) {
                return MaterialPageRoute(builder: builder, settings: settings);
              }
              return null;
            },

            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/otp': (context) => const OtpScreen(),
              '/forgotPassword': (context) => const ForgotPassword(),
              '/checkout': (context) => const CheckoutScreen(),
              // Paymob browser redirect lands here; verifies payment server-side
              '/checkout/status': (context) => const CheckoutStatusScreen(),
              '/order-success': (context) => const OrderSuccessScreen(),
              '/my-orders': (context) => const MyOrdersScreen(),
              '/order-detail': (context) => const OrderDetailScreen(),
              '/location-onboarding': (context) =>
                  const LocationOnboardingScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/about': (context) => const AboutScreen(),
              '/store-settings': (context) => const StoreSettingsScreen(),
              // ── Moderator+ ──────────────────────────────────────────────────
              '/moderation': (context) => GuardedRoute(
                allowedRoles: AppRoles.moderators,
                redirectTo: '/home',
                child: const ModerationDashboardScreen(),
              ),
              // ── Admin + Owner ────────────────────────────────────────────────
              '/admin': (context) => GuardedRoute(
                allowedRoles: AppRoles.privilegedRoles,
                child: const AdminDashboardScreen(),
              ),
              // ── Vendor ──────────────────────────────────────────────────────
              '/vendor': (context) => GuardedRoute(
                allowedRoles: AppRoles.productCreators,
                redirectTo: '/home',
                child: const VendorDashboardScreen(),
              ),
              // ── Owner Only ───────────────────────────────────────────────────
              '/owner-control': (context) => GuardedRoute(
                allowedRoles: AppRoles.ownerOnly,
                redirectTo: '/home',
                child: const PlatformControlScreen(),
              ),
            },
          );
        },
      ),
    );
  }
}
