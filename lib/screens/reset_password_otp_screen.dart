import 'dart:async';
import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/providers/auth_provider.dart';
import 'package:e_commerce/screens/new_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class ResetPasswordOtpScreen extends StatefulWidget {
  final String email;

  const ResetPasswordOtpScreen({super.key, required this.email});

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AuthProvider>().startOtpTimer());
  }

  Future<void> resendOtp() async {
    final result = await context.read<AuthProvider>().sendResetCode(
      widget.email,
    );
    if (!mounted) return;
    if (result['success']) {
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ ${result['message']}")));
    }
  }

  void goToNewPassword(String pin) {
    if (pin.length < 6) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NewPasswordScreen(email: widget.email, otp: pin.trim()),
      ),
    );
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authLoading = context.watch<AuthProvider>().isLoading;
    final seconds = context.select(
      (AuthProvider auth) => auth.remainingSeconds,
    );

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppColors.secondary,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
        color: Colors.grey[50],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icon Section
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "OTP Verification",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter the 6-digit code sent to",
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.mode_edit_rounded,
                  color: AppColors.primary,
                ),
                label: Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Pin Input Section
              Pinput(
                length: 6,
                controller: pinController,
                focusNode: focusNode,
                defaultPinTheme: defaultPinTheme,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onCompleted: (pin) => goToNewPassword(pin),
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Timer Section
              seconds > 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Resend code in "),
                        Text(
                          "0:${seconds.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: authLoading ? null : () => resendOtp(),
                      child: const Text("Resend new code"),
                    ),
              const SizedBox(height: 50),
              // Continue Button
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: authLoading
                        ? null
                        : () => goToNewPassword(pinController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: authLoading
                        ? const CircularProgressIndicator(
                            color: AppColors.secondary,
                          )
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
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
