import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/providers/auth_provider.dart';
import 'package:e_commerce/screens/home_screen.dart';

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

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.verifyOtp(pin);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      pinController.clear();
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Invalid code")),
      );
    }
  }

  Future<void> _handleResendCode() async {
    if (context.read<AuthProvider>().isLoading) return;
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.resendOtp();

    if (!mounted) return;

    if (result['success']) {
      startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Success! A new code has been sent."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Failed to resend code"),
          backgroundColor: Colors.redAccent,
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
    final authProvider = context.watch<AuthProvider>();
    final email = authProvider.user['email'] ?? "your email";
    final isLoading = authProvider.isLoading;
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
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Verification Code",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We have sent the code to",
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              Pinput(
                length: 6,
                controller: pinController,
                focusNode: focusNode,
                defaultPinTheme: defaultPinTheme,
                hapticFeedbackType: HapticFeedbackType.mediumImpact,
                onCompleted: _handleVerify,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              remainingSeconds > 0
                  ? Text(
                      "Resend code in 0:${remainingSeconds.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.grey),
                    )
                  : TextButton(
                      onPressed: () {
                        _handleResendCode();
                        startTimer();
                      },
                      child: const Text(
                        "Resend New Code",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => _handleVerify(pinController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Confirm",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
