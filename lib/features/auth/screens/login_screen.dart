import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/data/providers/cart_provider.dart';
import 'package:dealio/data/providers/profile_provider.dart';
import 'package:dealio/data/providers/wishlist_provider.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:dealio/features/settings/widgets/privacy_policy_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();

  bool passwordVisible = false;
  bool hasLoginError = false;
  bool _autoValidate = false;
  bool hasAutofilled = false;

  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,4}$",
    ).hasMatch(email);
  }

  void _clearServerError() {
    if (hasLoginError) {
      setState(() => hasLoginError = false);
      _formKey.currentState!.validate();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }
    final authProvider = context.read<AuthProvider>();
    try {
      final result = await authProvider.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (!mounted) return;
      if (result['success']) {
        TextInput.finishAutofillContext();

        // ─── Fetch profile, sync guest cart & wishlist after login ───────
        final token =
            context.read<AuthProvider>().user['accessToken']?.toString() ?? '';
        final userId = context.read<AuthProvider>().userId;
        if (token.isNotEmpty) {
          await context.read<ProfileProvider>().fetchProfile(token);
          await context.read<CartProvider>().syncGuestCart(token);
        }
        if (userId.isNotEmpty) {
          await context.read<WishlistProvider>().syncGuestWishlist(userId);
        }

        // ─── Smart navigation: pop back if on top of navigation stack (e.g. Home, Cart) ──
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          hasLoginError = true;
          _autoValidate = true;
        });
        _formKey.currentState!.validate();
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: result['message'] ?? 'Login failed',
            backgroundColor: AppColors.errorRed,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: 'Connection Error',
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      );
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final auth = Provider.of<AuthProvider>(context);
    final Color textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.secondary;
    final Color secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey[600]!;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: auth.isLoading ? 0.8 : 1.0,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: AbsorbPointer(
            absorbing: auth.isLoading,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: R.symmetric(context, horizontal: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: R.h(context, 20)),

                      // App Logo Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/dealio_logo.svg',
                            height: R.font(context, 42),
                            colorFilter: ColorFilter.mode(
                              isDark ? AppColors.primary : AppColors.secondary,
                              BlendMode.srcIn,
                            ),
                          ),
                          Text(
                            "ealio",
                            style: TextStyle(
                              fontSize: R.font(context, 48),
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              // color: textColor,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: R.h(context, 25)),

                      // Login Main Card
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: R.isLargeScreen(context)
                              ? 400.0
                              : double.infinity,
                        ),
                        child: Container(
                          padding: R.all(context, 20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                              R.r(context, 25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black26
                                    : AppColors.black.withOpacity(0.07),
                                blurRadius: R.r(context, 30),
                                offset: const Offset(0, 12),
                              ),
                            ],
                            border: isDark
                                ? Border.all(
                                    color: AppColors.darkBorder,
                                    width: 1,
                                  )
                                : null,
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
                                    "Welcome Back",
                                    style: TextStyle(
                                      fontSize: R.font(context, 22),
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 6)),
                                  Text(
                                    "Login to continue your journey",
                                    style: TextStyle(
                                      fontSize: R.font(context, 13),
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 25)),

                                  _buildEmailField(isDark),
                                  SizedBox(height: R.h(context, 15)),
                                  _buildPasswordField(isDark),
                                  SizedBox(height: R.h(context, 9)),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: TextButton(
                                        onPressed: () async {
                                          final returnedEmail =
                                              await Navigator.pushNamed(
                                                context,
                                                '/forgotPassword',
                                                arguments: emailController.text,
                                              );
                                          if (returnedEmail != null &&
                                              returnedEmail is String) {
                                            setState(
                                              () => emailController.text =
                                                  returnedEmail,
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          padding: R.symmetric(
                                            context,
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: R.font(context, 13),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 20)),

                                  // Login Button (With 360 Glow & Adaptive Loading)
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          R.r(context, 12),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: auth.isLoading
                                                ? AppColors.transparent
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
                                        onPressed: auth.isLoading
                                            ? null
                                            : _login,
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
                                        child: auth.isLoading
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
                                                              AppColors
                                                                  .secondary,
                                                            ),
                                                      )
                                                    : Lottie.asset(
                                                        'assets/animations/dealio_loading_js.json',
                                                        fit: BoxFit.contain,
                                                      ),
                                              )
                                            : Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontSize: R.font(context, 16),
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: R.symmetric(context, vertical: 18),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            thickness: 1,
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : AppColors.borderColor,
                                          ),
                                        ),
                                        Padding(
                                          padding: R.symmetric(
                                            context,
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: secondaryTextColor
                                                  .withOpacity(0.6),
                                              fontSize: R.font(context, 12),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            thickness: 1,
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : AppColors.borderColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Google Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading
                                          ? null
                                          : () async {
                                              final result = await auth
                                                  .signInWithGoogle();
                                              if (!mounted) return;
                                              if (result['success']) {
                                                showTopSnackBar(
                                                  Overlay.of(context),
                                                  CustomSnackBar.info(
                                                    message:
                                                        result['message'] ??
                                                        'Opening Google Sign-in...',
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    textStyle: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.secondary,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? AppColors.darkBackground
                                            : Colors.grey[50],
                                        foregroundColor: textColor,
                                        elevation: 0,
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
                                        padding: R.symmetric(
                                          context,
                                          vertical: 14,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/images/google_icon.svg',
                                            height: R.r(context, 29),
                                          ),
                                          SizedBox(width: R.w(context, 10)),
                                          Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: R.font(context, 15),
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: R.h(context, 20)),

                                  // Terms & Privacy Policy Footer
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () =>
                                          showPrivacyPolicySheet(context),
                                      child: Text.rich(
                                        TextSpan(
                                          text:
                                              "By continuing, you agree to our ",
                                          style: TextStyle(
                                            fontSize: R.font(context, 11),
                                            color: secondaryTextColor,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: "Terms of Service",
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: " and "),
                                            TextSpan(
                                              text: "Privacy Policy",
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: R.h(context, 20)),

                      // Bottom Sign Up & Skip Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: R.font(context, 14),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: TextButton(
                              onPressed: () async {
                                final returnedEmail = await Navigator.pushNamed(
                                  context,
                                  '/register',
                                  arguments: emailController.text,
                                );
                                if (returnedEmail != null &&
                                    returnedEmail is String) {
                                  setState(
                                    () => emailController.text = returnedEmail,
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: R.font(context, 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: R.h(context, 8)),

                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/home',
                            arguments: emailController.text,
                          ),
                          child: Text(
                            "Skip for now",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: R.font(context, 13),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: R.h(context, 30)),
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

  Widget _buildEmailField(bool isDark) {
    return TextFormField(
      controller: emailController,
      autofillHints: const [AutofillHints.email],
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) {
        _clearServerError();
        context.read<AuthProvider>().tempEmail = v;
      },
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(passwordFocusNode),
      decoration: _inputDecoration(
        'Email',
        isDark,
        hintText: 'you@example.com',
        prefixIcon: LucideIcons.mail,
      ),
      style: TextStyle(
        fontSize: R.font(context, 15),
        color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your email';
        if (!_isEmailValid(value)) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return TextFormField(
      controller: passwordController,
      focusNode: passwordFocusNode,
      autofillHints: const [AutofillHints.password],
      obscureText: !passwordVisible,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      textInputAction: TextInputAction.done,
      onChanged: (v) => _clearServerError(),
      onFieldSubmitted: (_) => _login(),
      decoration:
          _inputDecoration(
            'Password',
            isDark,
            hintText: 'Enter your password',
            prefixIcon: LucideIcons.lock,
          ).copyWith(
            suffixIconColor: WidgetStateColor.resolveWith((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.error)) {
                return AppColors.error;
              }
              return isDark
                  ? AppColors.darkTextSecondary.withOpacity(0.7)
                  : AppColors.secondary.withOpacity(0.7);
            }),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? LucideIcons.eye : LucideIcons.eyeClosed,
                size: R.r(context, 20),
              ),
              onPressed: () =>
                  setState(() => passwordVisible = !passwordVisible),
            ),
          ),
      style: TextStyle(
        fontSize: R.font(context, 15),
        color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your password';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(
    String label,
    bool isDark, {
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark
            ? AppColors.darkTextSecondary.withOpacity(0.7)
            : AppColors.secondary.withOpacity(0.7),
        fontSize: R.font(context, 14),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark
            ? AppColors.darkTextMuted
            : AppColors.secondary.withOpacity(0.5),
        fontSize: R.font(context, 14),
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: R.font(context, 20),
              color: isDark
                  ? AppColors.darkTextSecondary.withOpacity(0.7)
                  : AppColors.secondary.withOpacity(0.7),
            )
          : null,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.error)) {
          return const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }
        return TextStyle(
          color: isDark
              ? AppColors.darkTextSecondary.withOpacity(0.7)
              : AppColors.secondary.withOpacity(0.7),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
      errorStyle: const TextStyle(
        color: AppColors.error,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : AppColors.fillColor,
      contentPadding: R.symmetric(context, horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.primary
              : AppColors.secondary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
