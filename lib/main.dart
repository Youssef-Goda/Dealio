import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/providers/product_provider.dart';
import 'package:e_commerce/data/providers/user_provider.dart';
import 'package:e_commerce/features/auth/screens/forgot_password.dart';
import 'package:e_commerce/features/auth/screens/login_screen.dart';
import 'package:e_commerce/features/auth/screens/otp_screen.dart';
import 'package:e_commerce/features/auth/screens/register_screen.dart';
import 'package:e_commerce/features/home/screens/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  Remove # from URL
  usePathUrlStrategy();

  GoogleFonts.config.allowRuntimeFetching = true;

  try {
    debugPrint("🔍 Attempting to load .env file...");
    await dotenv.load(fileName: ".env");
    debugPrint("✅ .env loaded successfully");

    final String supabaseUrl =
        dotenv.maybeGet('SUPABASE_URL') ??
        const String.fromEnvironment('SUPABASE_URL');
    // final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final String supabaseKey =
        dotenv.maybeGet('SUPABASE_ANON_KEY') ??
        const String.fromEnvironment('SUPABASE_ANON_KEY');
    // final String supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    //  Ensure the Keys are present
    // debugPrint("🔗 Supabase URL: $supabaseUrl");
    // debugPrint(
    // "🔑 Supabase Key: ${supabaseKey.isNotEmpty ? '${supabaseKey.substring(0, 20)}...' : 'MISSING!'}",
    // );

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception("⚠️ Missing Supabase credentials in .env file!");
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    debugPrint("✅ Supabase initialized successfully");
  } catch (e) {
    debugPrint("❌ Detailed Error loading .env: $e");
    // هنا ممكن تكمل بـ Default values لو عايز السيستم ميفصلش
  }

  final authProvider = AuthProvider();
  await authProvider.loadUserData();

  // ✅ الـ Listener للـ Auth State
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    debugPrint("🔊 Auth Event: ${data.event}");

    final session = data.session;

    if (session != null && data.event == AuthChangeEvent.signedIn) {
      debugPrint("✅ User signed in: ${session.user.email}");
      authProvider.handleGoogleSuccess(session);
    }
  });

  if (!kIsWeb) {
    FlutterNativeSplash.remove();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dealio',
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.lexendTextTheme(),
          colorScheme: ColorScheme.light(primary: AppColors.secondary),
        ),

        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (Supabase.instance.client.auth.currentSession != null) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),

        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/otp': (context) => const OtpScreen(),
          '/forgotPassword': (context) => const ForgotPassword(),
        },
      ),
    );
  }
}
