import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/providers/auth_provider.dart';
import 'package:e_commerce/screens/reset_password_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();
  bool isLoading = false;
  bool hasError = false;
  bool _autoValidate = false;
  bool hasLoginError = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,4}$",
    ).hasMatch(email);
  }

  void _clearServerError() {
    if (hasError) {
      setState(() => hasError = false);
      _formKey.currentState!.validate();
    }
  }

  Future<void> sendResetCode() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final auth = context.read<AuthProvider>();
      final result = await auth.sendResetCode(emailController.text.trim());

      if (!mounted) return;

      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordOtpScreen(email: emailController.text.trim()),
          ),
        );
      } else {
        setState(() {
          hasError = true;
          _autoValidate = true;
        });

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: result['message'],
            backgroundColor: AppColors.primary,
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        );
      }
    } catch (e) {
      // unexpected error
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.tempEmail.isNotEmpty) {
        emailController.text = auth.tempEmail;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Section
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.key_sharp,
                      size: 85,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 85),

                  // Reset Card
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          400, // عشان ما يبقاش واسع أوي على الشاشات الكبيرة(الويب)
                    ),
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 24,
                        left: 24,
                        right: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autoValidate
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          children: [
                            const Text(
                              "Reset Password",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Enter your email to receive a reset code",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondary.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 30),

                            _buildEmailField(),

                            const SizedBox(height: 30),

                            // send code button
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isLoading
                                          ? Colors.transparent
                                          : AppColors.primary.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(2, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : sendResetCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    disabledBackgroundColor: AppColors.primary
                                        .withOpacity(0.2),
                                    foregroundColor: AppColors.secondary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Lottie.asset(
                                            'assets/animations/dealio_loading_js.json',
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : const Text(
                                          'Send code',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            // Back to Login Button
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, emailController.text),
                              child: const Text(
                                "Back",
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 85),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      autofillHints: [AutofillHints.email],
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) {
        _clearServerError();
        context.read<AuthProvider>().tempEmail = v;
      },
      onFieldSubmitted: (_) {
        if (!isLoading) {
          sendResetCode();
        }
      },
      // onFieldSubmitted: (_) =>
      //     FocusScope.of(context).requestFocus(passwordFocusNode),
      decoration: _inputDecoration(
        'Email Address',
        hintText: 'you@example.com',
      ),
      style: TextStyle(
        fontSize: 16,
        // fontWeight: FontWeight.w500,
        color: AppColors.secondary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your email';
        if (!_isEmailValid(value)) return 'Enter a valid email';
        if (hasLoginError) return '';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      alignLabelWithHint: true,
      labelStyle: TextStyle(
        color: AppColors.secondary.withOpacity(0.7),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.secondary.withOpacity(0.5),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.fillColor,
      contentPadding: EdgeInsets.fromLTRB(12, 14, 12, 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 1.25),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
