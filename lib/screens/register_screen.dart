import 'package:e_commerce/models/colors.dart';
import 'package:e_commerce/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialEmail;

  const RegisterScreen({super.key, this.initialEmail});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  var emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final lastNameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmFocusNode = FocusNode();
  String? serverEmailError;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool _autoValidate = false;

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

  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,4}$",
    ).hasMatch(email);
  }
  
  String formatName(String name) => name.isEmpty
      ? ""
      : name[0].toUpperCase() + name.substring(1).toLowerCase();

  void _onFieldChanged() {
    if (serverEmailError != null) {
      setState(() => serverEmailError = null);
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.register(
      firstName: formatName(firstNameController.text.trim()),
      lastName: formatName(lastNameController.text.trim()),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/otp");
    } else {
      String msg = (result['message'] ?? "").toLowerCase();
      if (msg.contains("email")) {
        setState(() => serverEmailError = result['message']);
        _formKey.currentState!.validate();
      }
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: result['message'] ?? "Registration Failed",
          backgroundColor: AppColors.primary,
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    lastNameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300),
        opacity: auth.isLoading ? 0.8 : 1.0,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: AbsorbPointer(
            absorbing: auth.isLoading,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/dealio_logo.svg',
                            height: 42,
                            colorFilter: const ColorFilter.mode(
                              AppColors.secondary,
                              BlendMode.srcIn,
                            ),
                            // fit: BoxFit.con tain,
                          ),
                          Text(
                            "ealio",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      // Register Card
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 400),
                        child: Container(
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: _autoValidate
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: AutofillGroup(
                              child: Column(
                                children: [
                                  Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary.withOpacity(
                                        0.85,
                                      ),
                                      // letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "Join us to start your journey",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 35),

                                  // First Name & Last Name
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: firstNameController,
                                          label: 'First Name',
                                          autofill: AutofillHints.givenName,
                                          nextFocus: lastNameFocusNode,
                                          allowSpaces: true,
                                          onChanged: (v) {
                                            if (v.endsWith(' ')) {
                                              String cleanValue = v.trim();
                                              firstNameController
                                                  .value = firstNameController
                                                  .value
                                                  .copyWith(
                                                    text: cleanValue,
                                                    selection:
                                                        TextSelection.collapsed(
                                                          offset:
                                                              cleanValue.length,
                                                        ),
                                                  );
                                              FocusScope.of(
                                                context,
                                              ).requestFocus(lastNameFocusNode);
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: lastNameController,
                                          label: 'Last Name',
                                          focusNode: lastNameFocusNode,
                                          autofill: AutofillHints.familyName,
                                          nextFocus: emailFocusNode,
                                          allowSpaces: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  // Email Field
                                  _buildEmailField(),

                                  SizedBox(height: 15),
                                  // Password Field
                                  _buildPasswordField(
                                    controller: passwordController,
                                    label: 'Password',
                                    visible: passwordVisible,
                                    focusNode: passwordFocusNode,
                                    nextFocus: confirmFocusNode,
                                    onChanged: (v) {
                                      bool isConfirm = false;
                                      if (!isConfirm && _autoValidate) {
                                        _formKey.currentState!.validate();
                                      }
                                    },
                                    validator: (v) {
                                      bool isConfirm = false;
                                      if (v == null || v.isEmpty) {
                                        return 'Enter a strong password';
                                      }
                                      if (!isConfirm && v.length < 8) {
                                        return 'Min 8 characters';
                                      }
                                      return null;
                                    },
                                    toggle: () => setState(
                                      () => passwordVisible = !passwordVisible,
                                    ),
                                  ),
                                  SizedBox(height: 15),

                                  // Confirm Password
                                  _buildPasswordField(
                                    controller: confirmPasswordController,
                                    label: 'Confirm Password',
                                    visible: confirmPasswordVisible,
                                    focusNode: confirmFocusNode,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (v != passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    isConfirm: true,
                                    toggle: () => setState(
                                      () => confirmPasswordVisible =
                                          !confirmPasswordVisible,
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),

                                        boxShadow: [
                                          BoxShadow(
                                            color: auth.isLoading
                                                ? Colors.transparent
                                                : AppColors.primary.withOpacity(
                                                    0.2,
                                                  ),
                                            blurRadius: 10,
                                            offset: Offset(2, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: auth.isLoading
                                            ? null
                                            : _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          disabledBackgroundColor: AppColors
                                              .primary
                                              .withOpacity(0.2),
                                          foregroundColor: AppColors.secondary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        child: auth.isLoading
                                            ? SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: Lottie.asset(
                                                  'assets/animations/dealio_loading_js.json',
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                            : const Text(
                                                'Sign up',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text.rich(
                                    TextSpan(
                                      text: "By signing up, you agree to our ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "Terms of Service",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                          ),
                                        ),
                                        TextSpan(text: " and "),
                                        TextSpan(
                                          text: "Privacy Policy",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, emailController.text),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? autofill,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    Function(String)? onChanged,
    bool allowSpaces = false,
  }) {
    return TextFormField(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: controller,
      focusNode: focusNode,
      autofillHints: autofill != null ? [autofill] : null,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowSpaces ? RegExp(r'[a-zA-Z\-\s]') : RegExp(r'[a-zA-Z\-]'),
        ),
      ],
      onChanged: onChanged,
      decoration: _inputDecoration(label),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (v.trim().isEmpty || v.trim().length < 2) return 'Min 2 characters';
        if (v.trim().length > 20) return 'Max 20 characters';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      focusNode: emailFocusNode,
      autofillHints: const [AutofillHints.email],
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(passwordFocusNode),
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      onChanged: (v) {
        _onFieldChanged();
        context.read<AuthProvider>().tempEmail =
            v;
      },
      decoration: _inputDecoration(
        'Email Address',
        hintText: 'you@example.com',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter your Email Adress';
        if (!_isEmailValid(value)) return 'Invalid Email';
        if (serverEmailError != null) return '';
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback toggle,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool isConfirm = false,
    Function(String)? onChanged,
    required var validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !visible,
      onChanged: onChanged,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: isConfirm ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (isConfirm) {
          _register();
        } else {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: AppColors.secondary.withOpacity(0.6),
            size: 24,
          ),
          onPressed: toggle,
        ),
      ),
      validator: validator,
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
        color: AppColors.secondary.withOpacity(0.4),
        fontSize: 15,
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.25),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
