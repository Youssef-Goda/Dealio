import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/providers/auth_provider.dart';
import 'package:e_commerce/screens/forgot_password.dart';
import 'package:e_commerce/screens/home_screen.dart';
import 'package:e_commerce/screens/login_screen.dart';
import 'package:e_commerce/screens/otp_screen.dart';
import 'package:e_commerce/screens/register_screen.dart' show RegisterScreen;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  GoogleFonts.config.allowRuntimeFetching = true;
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }
  final authProvider = AuthProvider();
  try {
    await authProvider.loadUserData();
  } catch (e) {
    debugPrint("Error loading user data: $e");
  }
  if (!kIsWeb) {
    FlutterNativeSplash.remove();
  }
  runApp(
    // DevicePreview(
    //   enabled:
    //       !kReleaseMode && (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)),
    /*builder: (context) => */ MultiProvider(
      providers: [ChangeNotifierProvider.value(value: authProvider)],
      child: const MyApp(),
    ),
    // ),
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
        useInheritedMediaQuery: true,
        debugShowCheckedModeBanner: false,
        title: 'Dealio',
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.lexendTextTheme(),
          colorScheme: ColorScheme.light(primary: AppColors.secondary),
        ),

        home: Selector<AuthProvider, bool>(
          selector: (context, auth) => auth.isLoggedIn,
          builder: (context, isLoggedIn, child) {
            return isLoggedIn ? const HomeScreen() : const LoginScreen();
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
