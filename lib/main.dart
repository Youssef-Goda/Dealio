import 'dart:convert';
import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/screens/home_screen.dart';
import 'package:e_commerce/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  String id = '';
  String firstName = '';
  String lastName = '';
  String email = '';

  if (isLoggedIn) {
    String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> user = jsonDecode(userDataString);
      id = (user['_id'] ?? user['id'] ?? '').toString();
      firstName = user['firstName'] ?? '';
      lastName = user['lastName'] ?? '';
      email = user['email'] ?? '';
    }
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MyApp(
        startScreen: isLoggedIn
            ? HomeScreen(
                id: id,
                firstName: firstName,
                lastName: lastName,
                email: email,
              )
            : LoginScreen(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      title: 'Dealio',
      theme: ThemeData(
        colorScheme: ColorScheme.light(primary: AppColors.secondary),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),

        // الانتقالات الناعمة
        // pageTransitionsTheme: const PageTransitionsTheme(
        //   builders: {
        //     TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        //     TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        //   },
        // ),
      ),
      home: startScreen,
    );
  }
}
