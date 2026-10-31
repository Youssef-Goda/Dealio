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
import 'package:dealio/data/providers/review_provider.dart';
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
import 'package:dealio/features/products/screens/product_details_page.dart';
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

  // Install auth callbacks before loadUserData starts its background profile
  // request; that request can receive a 401 before runApp/Navigator exists.
  ApiService.onTokensRefreshed =
      (previousRefreshToken, accessToken, refreshToken) {
        authProvider.acceptRefreshedTokens(
          previousRefreshToken: previousRefreshToken,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      };
  ApiService.onSessionExpired = (expiredAccessToken) {
    final expired = authProvider.expireSessionIfTokenMatches(
      expiredAccessToken,
    );
    if (expired) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (r) => false,
      );
    }
    return expired;
  };

  // Restore session immediately if Supabase has one
  try {
    await authProvider.loadUserData();

    // Only process a Supabase session if no custom JWT session was restored,
    // AND the Supabase session is from an OAuth provider (e.g. Google).
    // Regular email/password users use a custom Node.js JWT — calling
    // handleGoogleSuccess for them would overwrite their backend token with
    // a Supabase token, breaking all API calls.
    if (!authProvider.isLoggedIn) {
      final supabaseSession = Supabase.instance.client.auth.currentSession;
      if (supabaseSession != null) {
        final provider =
            supabaseSession.user.appMetadata['provider']?.toString() ?? '';
        final isOAuth =
            provider == 'google' ||
            supabaseSession.user.identities?.any(
                  (i) => i.provider == 'google',
                ) ==
                true;
        if (isOAuth) {
          await authProvider.handleGoogleSuccess(supabaseSession);
        }
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
  //
  // ⚠️ SECURITY: Only process SIGNED_IN events (initial OAuth callback).
  // Ignoring TOKEN_REFRESHED / USER_UPDATED prevents the Supabase session from
  // silently overwriting the custom JWT session that regular (email/password)
  // users hold in SharedPreferences — the root cause of the role-switching bug.
  Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) {
      try {
        // Only handle the initial sign-in event (OAuth callback).
        // TOKEN_REFRESHED, USER_UPDATED, etc. must NOT overwrite the session.
        final isSignIn =
            data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.initialSession;

        if (!isSignIn) return;

        final session = data.session;
        if (session == null) return;

        // Guard: only process if this Supabase session belongs to the SAME user
        // already loaded in AuthProvider (or if no user is loaded yet).
        // This prevents a cached Supabase token for a different account (e.g. an
        // admin who previously signed in with Google on the same device) from
        // overwriting the currently-logged-in regular user's JWT session.
        if (authProvider.isLoggedIn &&
            authProvider.userId.isNotEmpty &&
            authProvider.userId != session.user.id) {
          debugPrint(
            '🛡️ [Auth] Supabase session for ${session.user.id} ignored '
            '— current user is ${authProvider.userId}',
          );
          return;
        }

        // Only handle OAuth (Google) sessions. Regular JWT users do NOT use
        // Supabase auth; calling handleGoogleSuccess for them would overwrite
        // their custom backend token with the Supabase token.
        final provider = session.user.appMetadata['provider']?.toString() ?? '';
        final isOAuth =
            provider == 'google' ||
            session.user.identities?.any((i) => i.provider == 'google') == true;

        if (!isOAuth && authProvider.isLoggedIn) {
          debugPrint(
            '🛡️ [Auth] Non-OAuth Supabase event (provider=$provider) ignored '
            '— user already has a JWT session.',
          );
          return;
        }

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
          session,
          profileProvider: profileProvider,
        );
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
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
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

            // Use Selector instead of Consumer so that background profile syncs
            // (updateUserData → notifyListeners) do NOT recreate HomeScreen /
            // HomeBottom / SidebarXController.  Only the two fields that
            // actually control which top-level widget to show are selected.
            // Bug fixed: manager dashboard rebuilding on refresh because
            // _syncProfileFromServer fired notifyListeners() → Consumer rebuilt
            // → new HomeBottom with SidebarXController re-reading Uri.base.path
            // which had already been updated to '/home', losing the admin tab.
            home: Selector<AuthProvider, ({bool isInitialized, bool isLoggedIn})>(
              selector: (_, auth) => (
                isInitialized: auth.isInitialized,
                isLoggedIn: auth.isLoggedIn,
              ),
              builder: (context, state, _) {
                // Still loading session from SharedPrefs/Supabase — show spinner
                if (!state.isInitialized) {
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
                // Without this check, the builder would return HomeScreen (for
                // logged-in users) and the status screen would never be shown.
                //
                // We check AFTER isInitialized so CheckoutStatusScreen has
                // access to authenticated providers (JWT, CheckoutProvider).
                //
                // usePathUrlStrategy() is active: path is in Uri.base.path,
                // not the fragment.
                if (kIsWeb) {
                  final path = Uri.base.path;
                  if (path == '/checkout/status' ||
                      path.startsWith('/checkout/status?') ||
                      path.startsWith('/checkout/status/')) {
                    return const CheckoutStatusScreen();
                  }
                }

                // Session loaded — route based on login state
                return state.isLoggedIn
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
            onGenerateRoute: (settings) {
              final name = settings.name ?? '';
              final uri = Uri.tryParse(name);

              if (uri != null) {
                final path = uri.path.isNotEmpty ? uri.path : uri.host;

                // ── /checkout/status — MUST stay first, never touch ─────────
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

                // ── /product/:id — fetch by id when not in memory ───────────
                final productMatch = RegExp(
                  r'^/product/(.+)$',
                ).firstMatch(path);
                if (productMatch != null) {
                  final productId = productMatch.group(1)!;
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (context) =>
                        _ProductDeepLinkPage(productId: productId),
                  );
                }

                // ── /order/:id — fetch by id when not in memory ─────────────
                final orderMatch = RegExp(r'^/order/(.+)$').firstMatch(path);
                if (orderMatch != null) {
                  final orderId = orderMatch.group(1)!;
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (context) => _OrderDeepLinkPage(orderId: orderId),
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
              // Unknown path → home (SPA fallback)
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
                settings: settings,
              );
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
              // ── Tab deep-link paths (HomeBottom reads Uri.base.path) ────────
              // User tabs — auth is already enforced by the home Consumer above
              '/orders': (context) => const HomeScreen(),
              '/cart': (context) => const HomeScreen(),
              '/favorites': (context) => const HomeScreen(),
              '/profile': (context) => const HomeScreen(),
              '/search': (context) => const HomeScreen(),
              // Admin tabs — role-guarded so typing the URL doesn't expose
              // the admin tab to a non-admin user
              '/admin/products': (context) => GuardedRoute(
                allowedRoles: AppRoles.productCreators,
                redirectTo: '/home',
                child: const HomeScreen(),
              ),
              '/admin/users': (context) => GuardedRoute(
                allowedRoles: AppRoles.privilegedRoles,
                redirectTo: '/home',
                child: const HomeScreen(),
              ),
              // ── ──────────────────────────────────────────────────────────────
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
              '/admin/orders': (context) => GuardedRoute(
                allowedRoles: AppRoles.orderManagers,
                redirectTo: '/home',
                child: const HomeScreen(),
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

// ══════════════════════════════════════════════════════════════════════════════
// Deep-link helpers
// These thin "loader" widgets are pushed by onGenerateRoute when the user
// navigates directly to /product/:id or /order/:id (paste URL / refresh).
// They look up the entity in the provider cache first; if not found they
// call the provider's fetch and locate by id.
// ══════════════════════════════════════════════════════════════════════════════

/// Resolves /product/:id → ProductDetailsPage
class _ProductDeepLinkPage extends StatefulWidget {
  final String productId;
  const _ProductDeepLinkPage({required this.productId});

  @override
  State<_ProductDeepLinkPage> createState() => _ProductDeepLinkPageState();
}

class _ProductDeepLinkPageState extends State<_ProductDeepLinkPage> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final provider = context.read<ProductProvider>();

    // Try cache first
    var product = provider.products
        .where((p) => p.id.toString() == widget.productId)
        .firstOrNull;

    if (product == null) {
      // Not in cache — fetch all products then retry
      await provider.fetchProducts();
      if (!mounted) return;
      product = provider.products
          .where((p) => p.id.toString() == widget.productId)
          .firstOrNull;
    }

    if (!mounted) return;

    if (product != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProductDetailsPage(product: product!),
        ),
      );
    } else {
      // Product not found — fall back to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Resolves /order/:id → OrderDetailScreen
class _OrderDeepLinkPage extends StatefulWidget {
  final String orderId;
  const _OrderDeepLinkPage({required this.orderId});

  @override
  State<_OrderDeepLinkPage> createState() => _OrderDeepLinkPageState();
}

class _OrderDeepLinkPageState extends State<_OrderDeepLinkPage> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final provider = context.read<OrdersProvider>();

    // Try cache first (may already have the full order with items).
    var order = provider.orders
        .where((o) => o.id == widget.orderId)
        .firstOrNull;

    if (order == null || order.items.isEmpty) {
      // Not in cache or cache has a summary-only row — fetch this specific
      // order via GET /api/orders/:id which returns items + address in one
      // request. Cheaper than fetching the entire orders list.
      try {
        order = await provider.fetchOrderById(widget.orderId);
      } on OrderFetchException catch (e) {
        debugPrint(
          '⚠️ [DeepLink] fetchOrderById failed: ${e.failure.name}: ${e.message}',
        );
        order = null;
      } catch (e) {
        debugPrint('⚠️ [DeepLink] fetchOrderById unexpected error: $e');
        order = null;
      }
      if (!mounted) return;
    }

    if (!mounted) return;

    if (order != null) {
      // OrderDetailScreen reads its Order via ModalRoute.settings.arguments
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OrderDetailScreen(),
          settings: RouteSettings(
            name: '/order/${widget.orderId}',
            arguments: order,
          ),
        ),
      );
    } else {
      // Order not found or user not authorised — fall back to orders tab
      Navigator.of(context).pushReplacementNamed('/orders');
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
