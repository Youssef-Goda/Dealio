import 'dart:async';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:dealio/data/providers/wishlist_provider.dart';
import 'package:dealio/features/home/screens/home_screen.dart';
import 'package:dealio/features/location/screens/location_onboarding_screen.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
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
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      // Do not forcibly restart the timer if there is an ongoing timer state
      if (!auth.isOtpTimerRunning && auth.remainingSeconds <= 0) {
        auth.startOtpTimer();
      }
    });
  }

  Future<void> _handleVerify(String pin) async {
    if (pin.length < 6) return;

    final authProvider = context.read<AuthProvider>();
    // final String targetEmail =
    //     authProvider.user['email'] ?? authProvider.tempEmail;
    final String targetEmail = authProvider.tempEmail.isNotEmpty
        ? authProvider.tempEmail
        : (authProvider.signUpEmail.isNotEmpty
            ? authProvider.signUpEmail
            : (authProvider.user['email']?.toString() ?? ''));

    setState(() => hasError = false);

    try {
      final result = await authProvider.verifyOtp(otp: pin, email: targetEmail);

      if (!mounted) return;

      if (result['success']) {
        debugPrint('✅ OTP Verified. Role: ${authProvider.userRole}');

        final token = authProvider.user['accessToken']?.toString() ?? '';
        final userId = authProvider.userId;
        if (token.isNotEmpty && mounted) {
          await context.read<ProfileProvider>().fetchProfile(token);
          await context.read<CartProvider>().syncGuestCart(token);
        }
        if (userId.isNotEmpty && mounted) {
          await context.read<WishlistProvider>().syncGuestWishlist(userId);
        }

        if (mounted) {
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
        pinController.clear();
        HapticFeedback.heavyImpact();
        setState(() => hasError = true);

        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              message: result['message'] ?? "Verification code is incorrect",
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error during OTP Verify: $e');
    }
  }

  Future<void> _handleResendCode() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    pinController.clear();
    setState(() => hasError = false);

    final result = await authProvider.resendOtp();

    if (!mounted) return;

    if (result['success'] == true) {
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

  void _returnToSignUp({bool isEditingEmail = false}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, {'isEditingEmail': isEditingEmail});
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/register',
        arguments: {'isEditingEmail': isEditingEmail},
      );
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final int remainingSeconds = authProvider.remainingSeconds;
    final email = authProvider.tempEmail.isNotEmpty
        ? authProvider.tempEmail
        : (authProvider.signUpEmail.isNotEmpty
            ? authProvider.signUpEmail
            : (authProvider.user['email']?.toString() ?? "your email"));
    // final email = authProvider.user['email'] ?? authProvider.tempEmail ?? "your email";
    final isLoading = authProvider.isLoading;

    final Color textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.secondary;
    final Color secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey[600]!;

    // Responsive Pin Theme
    final defaultPinTheme = PinTheme(
      width: R.r(context, 48),
      height: R.r(context, 54),
      textStyle: TextStyle(
        fontSize: R.font(context, 22),
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderColor,
        ),
        color: isDark ? AppColors.darkBackground : Colors.grey[50],
      ),
    );

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _returnToSignUp(isEditingEmail: false);
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isLoading ? 0.8 : 1.0,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: R.symmetric(context, horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: R.h(context, 40)),

                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: R.isLargeScreen(context)
                            ? 400.0
                            : double.infinity,
                      ),
                      child: Container(
                        padding: R.all(context, 20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(R.r(context, 25)),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : Colors.black.withOpacity(0.07),
                              blurRadius: R.r(context, 30),
                              offset: const Offset(0, 12),
                            ),
                          ],
                          border: isDark
                              ? Border.all(color: AppColors.darkBorder)
                              : null,
                        ),
                        child: Column(
                          children: [
                            // Header Icon Section with Radial Gradient
                            Container(
                              padding: R.all(context, 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.25),
                                    AppColors.primary.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.mailCheck,
                                size: R.font(context, 44),
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: R.h(context, 16)),

                            Text(
                              "Verification Code",
                              style: TextStyle(
                                fontSize: R.font(context, 20),
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: R.h(context, 6)),
                            Text(
                              "We have sent the code to",
                              style: TextStyle(
                                fontSize: R.font(context, 13),
                                color: secondaryTextColor,
                              ),
                            ),

                            // Interactive Email Row with Pointer Cursor
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () =>
                                    _returnToSignUp(isEditingEmail: true),
                                child: Padding(
                                  padding: R.symmetric(context, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          email,
                                          style: TextStyle(
                                            fontSize: R.font(context, 13),
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: R.w(context, 6)),
                                      Icon(
                                        LucideIcons.pencilLine,
                                        color: AppColors.primary,
                                        size: R.font(context, 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: R.h(context, 25)),

                            // Pin Input Section
                            Pinput(
                              length: 6,
                              controller: pinController,
                              focusNode: focusNode,
                              forceErrorState: hasError,
                              defaultPinTheme: defaultPinTheme,
                              hapticFeedbackType:
                                  HapticFeedbackType.heavyImpact,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              onChanged: (v) {
                                if (hasError) setState(() => hasError = false);
                              },
                              onCompleted: _handleVerify,
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!
                                    .copyWith(
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                              ),
                              errorPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!
                                    .copyWith(
                                      border: Border.all(
                                        color: AppColors.errorRed,
                                        width: 1.5,
                                      ),
                                      color: AppColors.errorRed.withOpacity(
                                        0.05,
                                      ),
                                    ),
                              ),
                            ),

                            if (hasError)
                              Padding(
                                padding: R.symmetric(context, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.circleAlert,
                                      color: AppColors.errorRed,
                                      size: R.font(context, 16),
                                    ),
                                    SizedBox(width: R.w(context, 6)),
                                    Text(
                                      "Invalid code, please try again",
                                      style: TextStyle(
                                        color: AppColors.errorRed,
                                        fontSize: R.font(context, 12),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(height: R.h(context, 25)),

                            // Timer Section
                            remainingSeconds > 0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Resend code in ",
                                        style: TextStyle(
                                          fontSize: R.font(context, 13),
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      Text(
                                        "0:${remainingSeconds.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: R.font(context, 13),
                                        ),
                                      ),
                                    ],
                                  )
                                : TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : _handleResendCode,
                                    child: const Text(
                                      "Resend new code",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),

                            SizedBox(height: R.h(context, 30)),

                            // Action Buttons (Cancel + Confirm)
                            Row(
                              children: [
                                // Cancel Button
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => _returnToSignUp(
                                            isEditingEmail: false,
                                          ),
                                    style: OutlinedButton.styleFrom(
                                      padding: R.symmetric(
                                        context,
                                        vertical: 15,
                                      ),
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.borderColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          R.r(context, 12),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: R.font(context, 16),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: R.w(context, 15)),

                                // Confirm Button (With 360 Glow & Adaptive Loading)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        R.r(context, 12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isLoading
                                              ? Colors.transparent
                                              : AppColors.primary.withOpacity(
                                                  0.35,
                                                ),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                          offset: Offset.zero,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => _handleVerify(
                                              pinController.text,
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors
                                            .primary
                                            .withOpacity(0.4),
                                        foregroundColor: AppColors.secondary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            R.r(context, 12),
                                          ),
                                        ),
                                        padding: R.symmetric(
                                          context,
                                          vertical: 15,
                                        ),
                                      ),
                                      child: isLoading
                                          ? SizedBox(
                                              height: R.r(context, 22),
                                              width: R.r(context, 22),
                                              child: kIsWeb
                                                  ? const CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            AppColors.secondary,
                                                          ),
                                                    )
                                                  : Lottie.asset(
                                                      'assets/animations/dealio_loading_js.json',
                                                      fit: BoxFit.contain,
                                                    ),
                                            )
                                          : Text(
                                              "Confirm",
                                              style: TextStyle(
                                                fontSize: R.font(context, 16),
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: R.h(context, 50)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
