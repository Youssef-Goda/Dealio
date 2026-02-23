import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/features/home/widgets/home_bottom.dart';
import 'package:e_commerce/features/home/widgets/home_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(child: HomeContent()),
      bottomNavigationBar: HomeBottom(),
    );
  }
}
