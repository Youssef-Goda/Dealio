// import 'dart:async';
// import 'package:e_commerce/core/utils/responsive_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pinput/pinput.dart';
// import 'package:provider/provider.dart';
// import 'package:e_commerce/core/constants/colors.dart';
// import 'package:e_commerce/data/providers/auth_provider.dart';
// import 'package:e_commerce/features/home/screens/home_screen.dart';

// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key});

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen> {
//   final pinController = TextEditingController();
//   final focusNode = FocusNode();
//   int remainingSeconds = 59;
//   Timer? timer;

//   @override
//   void initState() {
//     super.initState();
//     startTimer();
//   }

//   void startTimer() {
//     timer?.cancel();
//     setState(() => remainingSeconds = 59);
//     timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (!mounted) return;
//       if (remainingSeconds > 0) {
//         setState(() => remainingSeconds--);
//       } else {
//         t.cancel();
//       }
//     });
//   }

//   Future<void> _handleVerify(String pin) async {
//     if (pin.length < 6) return;

//     final authProvider = context.read<AuthProvider>();
//     // final result = await authProvider.verifyOtp(pin);
//     final result = await authProvider.verifyOtp(
//       otp: pin,
//       email: authProvider.user['email'], // نبعت الإيميل اللي متسيف في اليوزر
//     );

//     if (!mounted) return;

//     if (result['success']) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//         (route) => false,
//       );
//     } else {
//       pinController.clear();
//       HapticFeedback.heavyImpact();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(result['message'] ?? "Invalid code")),
//       );
//     }
//   }

//   Future<void> _handleResendCode() async {
//     if (context.read<AuthProvider>().isLoading) return;
//     final authProvider = context.read<AuthProvider>();
//     final result = await authProvider.resendOtp();

//     if (!mounted) return;

//     if (result['success']) {
//       startTimer();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Success! A new code has been sent."),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(result['message'] ?? "Failed to resend code"),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     pinController.dispose();
//     focusNode.dispose();
//     timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final email = authProvider.user['email'] ?? "your email";
//     final isLoading = authProvider.isLoading;
//     final defaultPinTheme = PinTheme(
//       width: 50,
//       height: 55,
//       textStyle: const TextStyle(
//         fontSize: 22,
//         color: AppColors.secondary,
//         fontWeight: FontWeight.bold,
//       ),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.borderColor),
//         color: Colors.grey[50],
//       ),
//     );

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 25),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(15),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.mark_email_read_outlined,
//                   size: 50,
//                   color: AppColors.primary,
//                 ),
//               ),
//               const SizedBox(height: 30),
//               const Text(
//                 "Verification Code",
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.secondary,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 "We have sent the code to",
//                 style: TextStyle(fontSize: 15, color: Colors.grey[600]),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: TextButton.styleFrom(
//                   foregroundColor: AppColors.primary,
//                   minimumSize: Size.zero,
//                   padding: R.symmetric(context, horizontal: 10, vertical: 6),
//                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     SizedBox(width: R.r(context, 16) + R.w(context, 6)),
//                     Flexible(
//                       child: Text(
//                         email,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: R.font(context, 14),
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.secondary,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: R.w(context, 6)),
//                     Icon(
//                       Icons.mode_edit_rounded,
//                       color: AppColors.primary,
//                       size: R.r(context, 16),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 40),
//               Pinput(
//                 length: 6,
//                 controller: pinController,
//                 focusNode: focusNode,
//                 defaultPinTheme: defaultPinTheme,
//                 hapticFeedbackType: HapticFeedbackType.mediumImpact,
//                 onCompleted: _handleVerify,
//                 focusedPinTheme: defaultPinTheme.copyWith(
//                   decoration: defaultPinTheme.decoration!.copyWith(
//                     border: Border.all(color: AppColors.primary, width: 1.5),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               remainingSeconds > 0
//                   ? Text(
//                       "Resend code in 0:${remainingSeconds.toString().padLeft(2, '0')}",
//                       style: const TextStyle(color: Colors.grey),
//                     )
//                   : TextButton(
//                       onPressed: () {
//                         _handleResendCode();
//                         startTimer();
//                       },
//                       child: const Text(
//                         "Resend New Code",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.primary,
//                         ),
//                       ),
//                     ),
//               const SizedBox(height: 50),
//               SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton(
//                   onPressed: isLoading
//                       ? null
//                       : () => _handleVerify(pinController.text),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           "Confirm",
//                           style: TextStyle(
//                             fontSize: 18,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'dart:async';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/features/home/screens/home_screen.dart';
import 'package:e_commerce/features/location/screens/location_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  int remainingSeconds = 59;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    setState(() => remainingSeconds = 59);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        t.cancel();
      }
    });
  }
Future<void> _handleVerify(String pin) async {
    if (pin.length < 6) return;

    // 1. تثبيت الـ Provider والإيميل قبل أي await عشان نتجنب الـ Async Gap
    final authProvider = context.read<AuthProvider>();
    final String targetEmail = authProvider.user['email'] ?? authProvider.tempEmail;

    // 2. إظهار مؤشر تحميل (Loading) لو عندك متغير حالة في الـ Screen
    // setState(() => _isVerifying = true); 

    try {
      // 3. نده دالة الـ OTP (واللي مفترض جواها بتنادي _saveUserSession)
      final result = await authProvider.verifyOtp(
        otp: pin,
        email: targetEmail,
      );

      if (!mounted) return;

      if (result['success']) {
        debugPrint('✅ OTP Verified. Role: ${authProvider.userRole}');

        if (mounted) {
          // ── First-time location onboarding check ───────────────────────
          // Show the location screen only once — after account creation.
          // Once the user completes or skips it, the flag is set and
          // they go straight to Home on all future logins.
          final prefs = await SharedPreferences.getInstance();
          final bool locationDone =
              prefs.getBool(kLocationOnboardingDone) ?? false;

          if (!locationDone && mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const LocationOnboardingScreen(),
              ),
              (_) => false,
            );
          } else if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } else {
        // 6. التعامل مع الخطأ بشكل احترافي
        pinController.clear();
        HapticFeedback.heavyImpact();
        
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              message: result['message'] ?? "كود التحقق غير صحيح",
              backgroundColor: AppColors.errorRed,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                fontFamily: 'Cairo', // عشان يظبط مع لغة الأبلكيشن
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error during OTP Verify: $e');
    } finally {
      // if (mounted) setState(() => _isVerifying = false);
    }
  }
  // Future<void> _handleVerify(String pin) async {
  //   if (pin.length < 6) return;

  //   final authProvider = context.read<AuthProvider>();
  //   final result = await authProvider.verifyOtp(
  //     otp: pin,
  //     email: authProvider.user['email'],
  //   );

  //   if (!mounted) return;

  //   if (result['success']) {
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (context) => const HomeScreen()),
  //       (route) => false,
  //     );
  //   } else {
  //     pinController.clear();
  //     HapticFeedback.heavyImpact();
  //     showTopSnackBar(
  //       Overlay.of(context),
  //       CustomSnackBar.error(
  //         message: result['message'] ?? "Invalid code",
  //         backgroundColor: AppColors.errorRed,
  //         textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  //       ),
  //     );
  //   }
  // }

  Future<void> _handleResendCode() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;
    
    final result = await authProvider.resendOtp();

    if (!mounted) return;

    if (result['success']) {
      startTimer();
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message: "Success! A new code has been sent.",
          backgroundColor: Colors.green.shade600,
        ),
      );
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: result['message'] ?? "Failed to resend code",
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final email = authProvider.user['email'] ?? "your email";
    final isLoading = authProvider.isLoading;
    
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;

    // Pin Themes
    final defaultPinTheme = PinTheme(
      width: R.w(context, 50),
      height: R.h(context, 55),
      textStyle: TextStyle(
        fontSize: R.font(context, 22),
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
        color: isDark ? AppColors.darkSurface : Colors.grey[50],
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              SizedBox(height: R.h(context, 20)),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: R.h(context, 30)),
              Text(
                "Verification Code",
                style: TextStyle(
                  fontSize: R.font(context, 26),
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: R.h(context, 10)),
              Text(
                "We have sent the code to",
                style: TextStyle(
                  fontSize: R.font(context, 15), 
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey[600]
                ),
              ),
              
              // Email & Edit Row
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: R.font(context, 14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: R.h(context, 40)),
              
              Pinput(
                length: 6,
                controller: pinController,
                focusNode: focusNode,
                defaultPinTheme: defaultPinTheme,
                hapticFeedbackType: HapticFeedbackType.heavyImpact,
                onCompleted: _handleVerify,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: R.h(context, 35)),
              
              remainingSeconds > 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: isDark ? AppColors.darkTextMuted : Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          "Resend code in 0:${remainingSeconds.toString().padLeft(2, '0')}",
                          style: TextStyle(color: isDark ? AppColors.darkTextMuted : Colors.grey),
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: _handleResendCode,
                      child: const Text(
                        "Resend New Code",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    
              SizedBox(height: R.h(context, 50)),
              
              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: R.h(context, 55),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: isLoading ? Colors.transparent : AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _handleVerify(pinController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 3),
                          )
                        : const Text(
                            "Confirm",
                            style: TextStyle(fontSize: 18, color: AppColors.secondary, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}