import 'dart:convert';
import 'package:e_commerce/api/api_service.dart';
import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const NewPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmVisible = false;
  bool _autoValidate = false;

  String? serverError;
  String? passwordServerError;
  String? otpServerError;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": widget.otp,
          "newPassword": passwordController.text.trim(),
        }),
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userData', jsonEncode(user));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Password reset & Logged in!")),
        );

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              id: (user['id'] ?? user['_id']).toString(),
              firstName: user['firstName'] ?? '',
              lastName: user['lastName'] ?? '',
              email: user['email'] ?? '',
            ),
          ),
          (route) => false,
        );
      } else if (res.statusCode == 400) {
        final errorData = jsonDecode(res.body);
        String message = errorData['message'] ?? "Error occurred";

        if (message.toLowerCase().contains('same as old')) {
          setState(() {
            passwordServerError =
                "New password cannot be the same old password";
          });
          _formKey.currentState!.validate();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("❌ $message")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Something went wrong, try again later")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Connection error!")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_open_rounded,
                      size: size.height * 0.08,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Create New Password",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your identity is verified! Choose a strong password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Main Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.fillColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
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
                          _buildPasswordField(
                            controller: passwordController,
                            label: "New Password",
                            hint: "Min. 8 characters",
                            isVisible: isPasswordVisible,
                            toggleVisible: () => setState(
                              () => isPasswordVisible = !isPasswordVisible,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: confirmPasswordController,
                            label: "Confirm Password",
                            hint: "Repeat your password",
                            isVisible: isConfirmVisible,
                            isConfirm: true,
                            toggleVisible: () => setState(
                              () => isConfirmVisible = !isConfirmVisible,
                            ),
                          ),
                          const SizedBox(height: 35),

                          // Submit Button
                          isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.primary,
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'SUBMIT',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    label: Text(
                      "Back to OTP",
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
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback toggleVisible,
    bool isConfirm = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppColors.secondary,
                width: 1.5,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppColors.secondary.withOpacity(0.5),
                size: 20,
              ),
              onPressed: toggleVisible,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter password';
            if (value.length < 8) return 'Must be at least 8 characters';
            if (isConfirm) {
              if (value != passwordController.text) {
                return 'Passwords don\'t match';
              }
            } else {
              if (passwordServerError != null) return passwordServerError;
            }
            return null;
          },
          onChanged: (value) {
            if (!isConfirm && passwordServerError != null) {
              setState(() => passwordServerError = null);
              _formKey.currentState!.validate();
            }
          },
        ),
      ],
    );
  }
}
