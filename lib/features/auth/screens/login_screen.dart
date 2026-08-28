// import 'package:e_commerce/core/constants/colors.dart';
// import 'package:e_commerce/data/providers/auth_provider.dart';
// import 'package:e_commerce/core/utils/responsive_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:top_snackbar_flutter/custom_snack_bar.dart';
// import 'package:top_snackbar_flutter/top_snack_bar.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   LoginScreenState createState() => LoginScreenState();
// }

// class LoginScreenState extends State<LoginScreen> {
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final passwordFocusNode = FocusNode();

//   bool passwordVisible = false;
//   bool hasLoginError = false;
//   bool _autoValidate = false;
//   bool hasAutofilled = false;

//   bool _isEmailValid(String email) {
//     return RegExp(
//       r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,4}$",
//     ).hasMatch(email);
//   }

//   void _clearServerError() {
//     if (hasLoginError) {
//       setState(() => hasLoginError = false);
//       _formKey.currentState!.validate();
//     }
//   }

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     passwordFocusNode.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     FocusScope.of(context).unfocus();
//     HapticFeedback.mediumImpact();
//     if (!_formKey.currentState!.validate()) {
//       setState(() => _autoValidate = true);
//       return;
//     }
//     final authProvider = context.read<AuthProvider>();
//     try {
//       final result = await authProvider.login(
//         emailController.text.trim(),
//         passwordController.text.trim(),
//       );
//       if (!mounted) return;
//       if (result['success']) {
//         TextInput.finishAutofillContext();
//         Navigator.pushReplacementNamed(context, "/home");
//       } else {
//         setState(() {
//           hasLoginError = true;
//           _autoValidate = true;
//         });
//         _formKey.currentState!.validate();
//         showTopSnackBar(
//           Overlay.of(context),
//           CustomSnackBar.error(
//             message: result['message'] ?? 'Login failed',
//             backgroundColor: AppColors.primary,
//             textStyle: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: AppColors.secondary,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       showTopSnackBar(
//         Overlay.of(context),
//         CustomSnackBar.error(
//           message: 'Connection Error: $e',
//           textStyle: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: AppColors.secondary,
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final auth = context.read<AuthProvider>();
//       if (auth.tempEmail.isNotEmpty) {
//         emailController.text = auth.tempEmail;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setSystemUIOverlayStyle(
//       const SystemUiOverlayStyle(
//         statusBarColor: AppColors.transparent,
//         systemNavigationBarColor: AppColors.background,
//         systemNavigationBarIconBrightness: Brightness.dark,
//         statusBarIconBrightness: Brightness.dark,
//       ),
//     );
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     final auth = Provider.of<AuthProvider>(context);
//     return GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: AnimatedOpacity(
//         duration: const Duration(milliseconds: 300),
//         opacity: auth.isLoading ? 0.8 : 1.0,
//         child: Scaffold(
//           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//           body: AbsorbPointer(
//             absorbing: auth.isLoading,
//             child: SafeArea(
//               child: Center(
//                 child: SingleChildScrollView(
//                   padding: R.symmetric(context, horizontal: 15),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SvgPicture.asset(
//                             'assets/images/dealio_logo.svg',
//                             height: R.font(context, 42),
//                             colorFilter: const ColorFilter.mode(
//                               AppColors.secondary,
//                               BlendMode.srcIn,
//                             ),
//                             // fit: BoxFit.contain,
//                           ),
//                           Text(
//                             "ealio",
//                             style: TextStyle(
//                               fontSize: R.font(context, 48),
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.secondary,
//                               letterSpacing: -1.0,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: R.h(context, 50)),

//                       // Login Card
//                       ConstrainedBox(
//                         constraints: BoxConstraints(
//                           maxWidth: R.isLargeScreen(context)
//                               ? 400.0
//                               : double.infinity,
//                         ),
//                         // constraints: BoxConstraints(maxWidth: 400),
//                         child: Container(
//                           padding: R.all(context, 15),
//                           // decoration: BoxDecoration(
//                           //   color: AppColors.white,
//                           //   borderRadius: BorderRadius.circular(20),
//                           //   boxShadow: [
//                           //     BoxShadow(
//                                 // color: AppColors.black.withOpacity(0.1),
//                           //       blurRadius: 20,
//                           //       offset: Offset(0, 10),
//                           //     ),
//                           //   ],
//                           // ),
//                           decoration: BoxDecoration(
//                             color: Theme.of(context).cardColor,
//                             borderRadius: BorderRadius.circular(
//                               R.r(context, 20),
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppColors.black.withOpacity(0.07),
//                                 blurRadius: R.r(context, 30),
//                                 offset: const Offset(0, 12),
//                                 spreadRadius: -5,
//                               ),
//                             ],
//                           ),
//                           child: Form(
//                             key: _formKey,
//                             autovalidateMode: _autoValidate
//                                 ? AutovalidateMode.onUserInteraction
//                                 : AutovalidateMode.disabled,
//                             child: AutofillGroup(
//                               child: Column(
//                                 children: [
//                                   Text(
//                                     "Welcome Back",
//                                     style: TextStyle(
//                                       fontSize: R.font(context, 24),
//                                       // fontSize: 24,
//                                       fontWeight: FontWeight.bold,
//                                       color: AppColors.secondary.withOpacity(
//                                         0.85,
//                                       ),
//                                       // letterSpacing: -0.2,
//                                     ),
//                                   ),
//                                   SizedBox(height: R.h(context, 12)),
//                                   Text(
//                                     "Login to continue your journey",
//                                     style: TextStyle(
//                                       fontSize: R.font(context, 13),
//                                       color: AppColors.textSecondary,
//                                     ),
//                                   ),
//                                   SizedBox(height: R.h(context, 45)),
//                                   _buildEmailField(),
//                                   SizedBox(height: R.h(context, 15)),
//                                   _buildPasswordField(),
//                                   Align(
//                                     alignment: Alignment.bottomRight,
//                                     child: TextButton(
//                                       style: TextButton.styleFrom(
//                                         foregroundColor: AppColors.primary,
//                                       ),
//                                       onPressed: () async {
//                                         final returnedEmail =
//                                             await Navigator.pushNamed(
//                                               context,

//                                               '/forgotPassword',
//                                               arguments: emailController.text,
//                                             );
//                                         if (returnedEmail != null &&
//                                             returnedEmail is String) {
//                                           setState(() {
//                                             emailController.text =
//                                                 returnedEmail;
//                                           });
//                                         }
//                                       },
//                                       child: Text(
//                                         'Forgot Password?',
//                                         style: TextStyle(
//                                           color: AppColors.secondary
//                                               .withOpacity(0.8),
//                                           fontWeight: FontWeight.w600,
//                                           fontSize: R.font(context, 13),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: R.h(context, 10)),

//                                   // Login Button
//                                   SizedBox(
//                                     width: double.infinity,
//                                     child: Container(
//                                       width: double.infinity,
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(
//                                           R.r(context, 12),
//                                         ),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: auth.isLoading
//                                                 ? AppColors.transparent
//                                                 : AppColors.primary.withOpacity(
//                                                     0.2,
//                                                   ),
//                                             blurRadius: 20,
//                                             offset: const Offset(0, 0),
//                                             spreadRadius: 2,
//                                           ),
//                                         ],
//                                       ),
//                                       child: ElevatedButton(
//                                         onPressed: auth.isLoading
//                                             ? null
//                                             : _login,
//                                         style: ElevatedButton.styleFrom(
//                                           // minimumSize: Size(double.infinity, 50.h),
//                                           backgroundColor: AppColors.primary,
//                                           disabledBackgroundColor: AppColors
//                                               .primary
//                                               .withOpacity(0.2),
//                                           foregroundColor: AppColors.secondary,
//                                           elevation: 0,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               R.r(context, 10),
//                                             ),
//                                           ),
//                                           // دي الطريقة "الصح" واللي بتخلي الكود بتاعك نظيف جداً
//                                           padding: R.symmetric(
//                                             context,
//                                             vertical: 15,
//                                           ),
//                                         ),
//                                         child: auth.isLoading
//                                             ? SizedBox(
//                                                 height: R.r(context, 26),
//                                                 width: R.r(context, 26),
//                                                 child: Lottie.asset(
//                                                   'assets/animations/dealio_loading_js.json',
//                                                   fit: BoxFit.contain,
//                                                 ),
//                                               )
//                                             : Text(
//                                                 'Login',
//                                                 style: TextStyle(
//                                                   fontSize: R.font(context, 16),
//                                                   fontWeight: FontWeight.bold,
//                                                   color: AppColors.secondary,
//                                                 ),
//                                               ),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(height: R.h(context, 12)),

//                                   // --- 1. الـ OR Divider (بنفس روح ألوانك) ---
//                                   Padding(
//                                     padding: R.symmetric(context, vertical: 15),
//                                     child: Row(
//                                       children: [
//                                         Expanded(
//                                           child: Divider(
//                                             thickness: 1,
//                                             color: AppColors.secondary
//                                                 .withOpacity(0.1),
//                                           ),
//                                         ),
//                                         Padding(
//                                           padding: R.symmetric(
//                                             context,
//                                             horizontal: 15,
//                                           ),
//                                           child: Text(
//                                             'OR',
//                                             style: TextStyle(
//                                               color: AppColors.secondary
//                                                   .withOpacity(0.4),
//                                               fontSize: R.font(context, 13),
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                         Expanded(
//                                           child: Divider(
//                                             thickness: 1,
//                                             color: AppColors.secondary
//                                                 .withOpacity(0.1),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   // في الـ Google Button
//                                   ElevatedButton(
//                                     onPressed: auth.isLoading
//                                         ? null
//                                         : () async {
//                                             final result = await auth
//                                                 .signInWithGoogle();

//                                             if (!mounted) return;

//                                             if (result['success']) {
//                                               // ✅ نعرض رسالة إن الـ popup فتح
//                                               showTopSnackBar(
//                                                 Overlay.of(context),
//                                                 CustomSnackBar.info(
//                                                   message:
//                                                       result['message'] ??
//                                                       'Opening Google Sign-in...',
//                                                   backgroundColor:
//                                                       AppColors.primary,
//                                                   textStyle: const TextStyle(
//                                                     fontWeight: FontWeight.bold,
//                                                     color: AppColors.secondary,
//                                                   ),
//                                                 ),
//                                               );
//                                             } else {
//                                               // ❌ لو فشل
//                                               showTopSnackBar(
//                                                 Overlay.of(context),
//                                                 CustomSnackBar.error(
//                                                   message:
//                                                       result['message'] ??
//                                                       'Google Sign-in failed',
//                                                   backgroundColor:
//                                                       AppColors.errorRed,
//                                                   textStyle: const TextStyle(
//                                                     fontWeight: FontWeight.bold,
//                                                     color: AppColors.white,
//                                                   ),
//                                                 ),
//                                               );
//                                             }
//                                           },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor:
//                                           AppColors.backgroundLight,
//                                       foregroundColor: AppColors.secondary,
//                                       elevation: 0,
//                                       shadowColor: AppColors.transparent,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(
//                                           R.r(context, 10),
//                                         ),
//                                       ),
//                                       padding: R.symmetric(
//                                         context,
//                                         vertical: 15,
//                                       ),
//                                     ),
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         SvgPicture.asset(
//                                           'assets/images/google_icon.svg',
//                                           height: R.r(context, 30),
//                                         ),
//                                         SizedBox(width: R.r(context, 12)),
//                                         Text(
//                                           'Continue with Google',
//                                           style: TextStyle(
//                                             fontSize: R.font(context, 16),
//                                             fontWeight: FontWeight.w700,
//                                             color: AppColors.secondary
//                                                 .withOpacity(0.9),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),

//                                   SizedBox(height: R.h(context, 20)),
//                                   Padding(
//                                     padding: EdgeInsets.only(
//                                       left: R.r(context, 8),
//                                       right: R.r(context, 8),
//                                     ),
//                                     child: Text.rich(
//                                       TextSpan(
//                                         text:
//                                             "By continuing, you agree to our ",
//                                         style: TextStyle(
//                                           fontSize: R.font(context, 11),
//                                           color: AppColors.textMuted,
//                                         ),
//                                         children: [
//                                           TextSpan(
//                                             text: "Terms of Service",
//                                             style: TextStyle(
//                                               color: AppColors.primary,
//                                               fontWeight: FontWeight.bold,
//                                               decoration:
//                                                   TextDecoration.underline,
//                                               decorationColor:
//                                                   AppColors.primary,
//                                             ),
//                                           ),
//                                           TextSpan(text: " and "),
//                                           TextSpan(
//                                             text: "Privacy Policy",
//                                             style: TextStyle(
//                                               color: AppColors.primary,
//                                               fontWeight: FontWeight.bold,
//                                               decoration:
//                                                   TextDecoration.underline,
//                                               decorationColor:
//                                                   AppColors.primary,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: R.h(context, 30)),

//                       // Footer
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Don't have an account? ",
//                             style: TextStyle(
//                               color: AppColors.textMuted,
//                               fontSize: R.font(context, 14),
//                             ),
//                           ),
//                           TextButton(
//                             style: TextButton.styleFrom(
//                               foregroundColor: AppColors.primary,
//                             ),
//                             onPressed: () async {
//                               final returnedEmail = await Navigator.pushNamed(
//                                 context,
//                                 '/register',
//                                 arguments: emailController.text,
//                               );
//                               if (returnedEmail != null &&
//                                   returnedEmail is String) {
//                                 setState(() {
//                                   emailController.text = returnedEmail;
//                                 });
//                               }
//                             },
//                             child: Text(
//                               "Sign Up",
//                               style: TextStyle(
//                                 color: AppColors.secondary,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: R.font(context, 14),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       TextButton(
//                         style: TextButton.styleFrom(
//                           foregroundColor: AppColors.primary,
//                         ),

//                         onPressed: () => Navigator.pushNamed(
//                           context,
//                           '/home',
//                           arguments: emailController.text,
//                         ),
//                         child: Text(
//                           "Skip",
//                           style: TextStyle(
//                             color: AppColors.secondary,
//                             fontWeight: FontWeight.bold,
//                             fontSize: R.font(context, 13),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailField() {
//     return TextFormField(
//       controller: emailController,
//       autofillHints: [AutofillHints.email],
//       inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
//       textInputAction: TextInputAction.next,
//       keyboardType: TextInputType.emailAddress,
//       onChanged: (v) {
//         _clearServerError();
//         context.read<AuthProvider>().tempEmail = v;
//       },
//       onFieldSubmitted: (_) =>
//           FocusScope.of(context).requestFocus(passwordFocusNode),
//       decoration: _inputDecoration('Email', hintText: 'you@example.com'),
//       style: TextStyle(
//         fontSize: R.font(context, 16),
//         // fontWeight: FontWeight.w900,
//         color: AppColors.secondary,
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) return 'Please enter your email';
//         if (!_isEmailValid(value)) return 'Enter a valid email';
//         if (hasLoginError) return '';
//         return null;
//       },
//     );
//   }

//   Widget _buildPasswordField() {
//     return TextFormField(
//       controller: passwordController,
//       focusNode: passwordFocusNode,
//       autofillHints: [AutofillHints.password],
//       obscureText: !passwordVisible,
//       inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
//       textInputAction: TextInputAction.done,
//       onChanged: (v) => _clearServerError(),
//       onFieldSubmitted: (_) => _login(),
//       decoration: _inputDecoration('Password', hintText: 'Enter your password')
//           .copyWith(
//             suffixIcon: IconButton(
//               style: TextButton.styleFrom(foregroundColor: AppColors.primary),

//               icon: Icon(
//                 passwordVisible ? Icons.visibility : Icons.visibility_off,
//                 size: R.r(context, 24),
//                 color: AppColors.secondary.withOpacity(0.6),
//               ),
//               onPressed: () =>
//                   setState(() => passwordVisible = !passwordVisible),
//             ),
//           ),
//       style: TextStyle(
//         fontSize: R.font(context, 16),
//         // fontWeight: FontWeight.w500,
//         color: AppColors.secondary,
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) return 'Please enter your password';
//         if (hasLoginError) return '';
//         return null;
//       },
//     );
//   }

//   InputDecoration _inputDecoration(String label, {String? hintText}) {
//     return InputDecoration(
//       labelText: label,
//       alignLabelWithHint: true,
//       labelStyle: TextStyle(
//         color: AppColors.secondary.withOpacity(0.7),
//         fontSize: R.font(context, 15),
//         fontWeight: FontWeight.w500,
//         letterSpacing: -0.05,
//       ),
//       hintText: hintText,
//       hintStyle: TextStyle(
//         color: AppColors.secondary.withOpacity(0.5),
//         fontSize: R.font(context, 15),
//       ),
//       filled: true,
//       fillColor:
//           Theme.of(context).inputDecorationTheme.fillColor ??
//           Theme.of(context).cardColor,
//       contentPadding: R.symmetric(context, horizontal: 12, vertical: 14),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(R.r(context, 10)),
//         borderSide: BorderSide.none,
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(R.r(context, 10)),
//         borderSide: const BorderSide(color: AppColors.primary, width: 1.25),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(R.r(context, 10)),
//         borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(R.r(context, 10)),
//         borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
//       ),
//     );
//   }
// }

import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/data/providers/cart_provider.dart';
import 'package:e_commerce/data/providers/profile_provider.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:e_commerce/features/settings/widgets/privacy_policy_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
// import 'package:lucide_icons/lucide_icons.dart';
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

        // ─── Fetch profile & cart immediately after login ───────
        final token =
            context.read<AuthProvider>().user['accessToken']?.toString() ?? '';
        if (token.isNotEmpty) {
          await context.read<ProfileProvider>().fetchProfile(token);
        }
        context.read<CartProvider>().fetchCart();

        // ─── Smart navigation: pop back if opened from Cart guest wall ──
        final args = ModalRoute.of(context)?.settings.arguments;
        final bool fromCart = args is Map && (args['fromCart'] == true);

        if (fromCart && Navigator.canPop(context)) {
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
            message: 'Login failed',
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
          message: 'Connection Error' /*: $e'*/,
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
        : AppColors.textSecondary;

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
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: R.h(context, 20)),

                      // Login Card
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: R.isLargeScreen(context)
                              ? 400.0
                              : double.infinity,
                        ),
                        child: Container(
                          padding: R.all(context, 15),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                              R.r(context, 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black26
                                    : AppColors.black.withOpacity(0.07),
                                blurRadius: R.r(context, 30),
                                offset: const Offset(0, 12),
                                spreadRadius: -5,
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
                                      fontSize: R.font(context, 24),
                                      fontWeight: FontWeight.bold,
                                      color: textColor.withOpacity(0.85),
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 12)),
                                  Text(
                                    "Login to continue your journey",
                                    style: TextStyle(
                                      fontSize: R.font(context, 13),
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 45)),
                                  _buildEmailField(isDark),
                                  SizedBox(height: R.h(context, 15)),
                                  _buildPasswordField(isDark),
                                  Align(
                                    alignment: Alignment.bottomRight,
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
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.primary
                                              : AppColors.secondary.withOpacity(
                                                  0.8,
                                                ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: R.font(context, 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 10)),

                                  // Login Button
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
                                                    0.3,
                                                  ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 4),
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
                                              R.r(context, 10),
                                            ),
                                          ),
                                          padding: R.symmetric(
                                            context,
                                            vertical: 15,
                                          ),
                                        ),
                                        child: auth.isLoading
                                            ? SizedBox(
                                                height: R.r(context, 26),
                                                width: R.r(context, 26),
                                                child: Lottie.asset(
                                                  'assets/animations/dealio_loading_js.json',
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                            : Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontSize: R.font(context, 16),
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.secondary,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 12)),

                                  Padding(
                                    padding: R.symmetric(context, vertical: 15),
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
                                            horizontal: 15,
                                          ),
                                          child: Text(
                                            'OR',
                                            style: TextStyle(
                                              color: secondaryTextColor
                                                  .withOpacity(0.5),
                                              fontSize: R.font(context, 13),
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
                                  ElevatedButton(
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
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.secondary,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? AppColors.darkSurface
                                          : AppColors.backgroundLight,
                                      foregroundColor: textColor,
                                      elevation: 0,
                                      side: isDark
                                          ? const BorderSide(
                                              color: AppColors.darkBorder,
                                            )
                                          : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          R.r(context, 10),
                                        ),
                                      ),
                                      padding: R.symmetric(
                                        context,
                                        vertical: 15,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/images/google_icon.svg',
                                          height: R.r(context, 30),
                                        ),
                                        SizedBox(width: R.r(context, 12)),
                                        Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            fontSize: R.font(context, 16),
                                            fontWeight: FontWeight.w700,
                                            color: textColor.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: R.h(context, 20)),
                                       GestureDetector(
                                    onTap: () => showPrivacyPolicySheet(context),
                                    child: Text.rich(
                                      TextSpan(
                                        text: "By continuing up, you agree to our ",
                                        style: TextStyle(fontSize: R.font(context, 11), color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                                        children: [
                                          TextSpan(
                                            text: "Terms of Service",
                                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                          ),
                                          const TextSpan(text: " and "),
                                          TextSpan(
                                            text: "Privacy Policy",
                                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // Text.rich(
                                  //   TextSpan(
                                  //     text: "By continuing, you agree to our ",
                                  //     style: TextStyle(
                                  //       fontSize: R.font(context, 11),
                                  //       color: isDark
                                  //           ? AppColors.darkTextMuted
                                  //           : AppColors.textMuted,
                                  //     ),
                                  //     children: [
                                  //       TextSpan(
                                  //         text: "Terms of Service",
                                  //         style: TextStyle(
                                  //           color: AppColors.primary,
                                  //           fontWeight: FontWeight.bold,
                                  //           decoration:
                                  //               TextDecoration.underline,
                                  //         ),
                                  //       ),
                                  //       const TextSpan(text: " and "),
                                  //       TextSpan(
                                  //         text: "Privacy Policy",
                                  //         style: TextStyle(
                                  //           color: AppColors.primary,
                                  //           fontWeight: FontWeight.bold,
                                  //           decoration:
                                  //               TextDecoration.underline,
                                  //         ),
                                  //       ),
                                  //     ],
                                  //   ),
                                  //   textAlign: TextAlign.center,
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: R.h(context, 30)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                              fontSize: R.font(context, 14),
                            ),
                          ),
                          TextButton(
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
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: R.font(context, 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/home',
                          arguments: emailController.text,
                        ),
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: R.font(context, 13),
                          ),
                        ),
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
      ),
      style: TextStyle(
        fontSize: R.font(context, 16),
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
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? LucideIcons.eye : LucideIcons.eyeClosed,
                size: R.r(context, 24),
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.secondary.withOpacity(0.6),
              ),
              onPressed: () =>
                  setState(() => passwordVisible = !passwordVisible),
            ),
          ),
      style: TextStyle(
        fontSize: R.font(context, 16),
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
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark
            ? AppColors.darkTextSecondary.withOpacity(0.7)
            : AppColors.secondary.withOpacity(0.7),
        fontSize: R.font(context, 15),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark
            ? AppColors.darkTextMuted
            : AppColors.secondary.withOpacity(0.5),
        fontSize: R.font(context, 15),
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkBackground : AppColors.fillColor,
      contentPadding: R.symmetric(context, horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 10)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 10)),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.25),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.r(context, 10)),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
      ),
    );
  }
}
