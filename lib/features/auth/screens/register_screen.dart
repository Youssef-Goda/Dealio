// import 'package:dealio/core/constants/colors.dart';
// import 'package:dealio/features/settings/widgets/privacy_policy_sheet.dart';
// import 'package:dealio/data/providers/auth_provider.dart';
// import 'package:dealio/core/utils/responsive_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:top_snackbar_flutter/custom_snack_bar.dart';
// import 'package:top_snackbar_flutter/top_snack_bar.dart';

// class RegisterScreen extends StatefulWidget {
//   const RegisterScreen({super.key});

//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final firstNameController = TextEditingController();
//   final lastNameController = TextEditingController();
//   var emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final lastNameFocusNode = FocusNode();
//   final emailFocusNode = FocusNode();
//   final passwordFocusNode = FocusNode();
//   final confirmFocusNode = FocusNode();
//   String? serverEmailError;
//   bool passwordVisible = false;
//   bool confirmPasswordVisible = false;
//   bool _autoValidate = false;

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

//   bool _isEmailValid(String email) {
//     return RegExp(
//       r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,4}$",
//     ).hasMatch(email);
//   }

//   String formatName(String name) => name.isEmpty
//       ? ""
//       : name[0].toUpperCase() + name.substring(1).toLowerCase();

//   void _onFieldChanged() {
//     if (serverEmailError != null) {
//       setState(() => serverEmailError = null);
//     }
//   }

//   Future<void> _register() async {
//     FocusScope.of(context).unfocus();
//     HapticFeedback.mediumImpact();
//     setState(() => _autoValidate = true);
//     if (!_formKey.currentState!.validate()) return;
//     final authProvider = context.read<AuthProvider>();
//     final result = await authProvider.register(
//       firstName: formatName(firstNameController.text.trim()),
//       lastName: formatName(lastNameController.text.trim()),
//       email: emailController.text.trim(),
//       password: passwordController.text.trim(),
//     );
//     if (result['success']) {
//       if (!mounted) return;
//       // Backup: ensure tempEmail is set even if provider didn't set it
//       authProvider.tempEmail = emailController.text.trim();
//       Navigator.pushReplacementNamed(context, "/otp");
//     } else {
//       String msg = (result['message'] ?? "").toLowerCase();
//       if (msg.contains("email")) {
//         setState(() => serverEmailError = result['message']);
//         _formKey.currentState!.validate();
//       }
//       if (!mounted) return;
//       showTopSnackBar(
//         Overlay.of(context),
//         CustomSnackBar.error(
//           message: result['message'] ?? "Registration Failed",
//           backgroundColor: AppColors.errorRed,
//           textStyle: const TextStyle(
//             fontWeight: FontWeight.bold,
//             color: AppColors.white,
//           ),
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     firstNameController.dispose();
//     lastNameController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     lastNameFocusNode.dispose();
//     emailFocusNode.dispose();
//     passwordFocusNode.dispose();
//     confirmFocusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
//     SystemChrome.setSystemUIOverlayStyle(
//       SystemUiOverlayStyle(
//         statusBarColor: AppColors.transparent,
//         systemNavigationBarColor: isDark ? AppColors.darkBackground : AppColors.background,
//         systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
//         statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
//       ),
//     );

//     final auth = Provider.of<AuthProvider>(context);
//     final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;
//     final Color secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

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
//                             colorFilter: ColorFilter.mode(
//                               isDark ? AppColors.primary : AppColors.secondary,
//                               BlendMode.srcIn,
//                             ),
//                           ),
//                           Text(
//                             "ealio",
//                             style: TextStyle(
//                               fontSize: R.font(context, 48),
//                               fontWeight: FontWeight.w700,
//                               color: textColor,
//                               letterSpacing: -1.0,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: R.h(context, 30)),
                      
//                       // Register Card
//                       ConstrainedBox(
//                         constraints: BoxConstraints(
//                           maxWidth: R.isLargeScreen(context) ? 400.0 : double.infinity,
//                         ),
//                         child: Container(
//                           padding: R.all(context, 17),
//                           decoration: BoxDecoration(
//                             color: isDark ? AppColors.darkSurface : Theme.of(context).cardColor,
//                             borderRadius: BorderRadius.circular(R.r(context, 20)),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: isDark ? Colors.black26 : AppColors.black.withOpacity(0.07),
//                                 blurRadius: R.r(context, 30),
//                                 offset: const Offset(0, 12),
//                                 spreadRadius: -5,
//                               ),
//                             ],
//                             border: isDark ? Border.all(color: AppColors.darkBorder, width: 1) : null,
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
//                                     "Create Account",
//                                     style: TextStyle(
//                                       fontSize: R.font(context, 24),
//                                       fontWeight: FontWeight.bold,
//                                       color: textColor.withOpacity(0.85),
//                                     ),
//                                   ),
//                                   SizedBox(height: R.h(context, 12)),
//                                   Text(
//                                     "Join us to start your journey",
//                                     style: TextStyle(
//                                       fontSize: R.font(context, 13),
//                                       color: secondaryTextColor,
//                                     ),
//                                   ),
//                                   SizedBox(height: R.h(context, 35)),

//                                   // First Name & Last Name
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: _buildTextField(
//                                           isDark: isDark,
//                                           controller: firstNameController,
//                                           label: 'First Name',
//                                           autofill: AutofillHints.givenName,
//                                           nextFocus: lastNameFocusNode,
//                                           allowSpaces: true,
//                                           onChanged: (v) {
//                                             if (v.endsWith(' ')) {
//                                               String cleanValue = v.trim();
//                                               firstNameController.value = firstNameController.value.copyWith(
//                                                 text: cleanValue,
//                                                 selection: TextSelection.collapsed(offset: cleanValue.length),
//                                               );
//                                               FocusScope.of(context).requestFocus(lastNameFocusNode);
//                                             }
//                                           },
//                                         ),
//                                       ),
//                                       SizedBox(width: R.w(context, 10)),
//                                       Expanded(
//                                         child: _buildTextField(
//                                           isDark: isDark,
//                                           controller: lastNameController,
//                                           label: 'Last Name',
//                                           focusNode: lastNameFocusNode,
//                                           autofill: AutofillHints.familyName,
//                                           nextFocus: emailFocusNode,
//                                           allowSpaces: false,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   SizedBox(height: R.h(context, 15)),
                                  
//                                   _buildEmailField(isDark),

//                                   SizedBox(height: R.h(context, 15)),
                                  
//                                   _buildPasswordField(
//                                     isDark: isDark,
//                                     controller: passwordController,
//                                     label: 'Password',
//                                     visible: passwordVisible,
//                                     focusNode: passwordFocusNode,
//                                     nextFocus: confirmFocusNode,
//                                     onChanged: (v) {
//                                       if (_autoValidate) _formKey.currentState!.validate();
//                                     },
//                                     validator: (v) {
//                                       if (v == null || v.isEmpty) return 'Enter a strong password';
//                                       if (v.length < 8) return 'Min 8 characters';
//                                       return null;
//                                     },
//                                     toggle: () => setState(() => passwordVisible = !passwordVisible),
//                                   ),
//                                   SizedBox(height: R.h(context, 15)),

//                                   _buildPasswordField(
//                                     isDark: isDark,
//                                     controller: confirmPasswordController,
//                                     label: 'Confirm Password',
//                                     visible: confirmPasswordVisible,
//                                     focusNode: confirmFocusNode,
//                                     validator: (v) {
//                                       if (v == null || v.isEmpty) return 'Please confirm your password';
//                                       if (v != passwordController.text) return 'Passwords do not match';
//                                       return null;
//                                     },
//                                     isConfirm: true,
//                                     toggle: () => setState(() => confirmPasswordVisible = !confirmPasswordVisible),
//                                   ),
                                  
//                                   SizedBox(height: R.h(context, 25)),
                                  
//                                   // Sign Up Button
//                                   SizedBox(
//                                     width: double.infinity,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(R.r(context, 12)),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: auth.isLoading ? AppColors.transparent : AppColors.primary.withOpacity(0.3),
//                                             blurRadius: 15,
//                                             offset: const Offset(0, 4),
//                                           ),
//                                         ],
//                                       ),
//                                       child: ElevatedButton(
//                                         onPressed: auth.isLoading ? null : _register,
//                                         style: ElevatedButton.styleFrom(
//                                           backgroundColor: AppColors.primary,
//                                           disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
//                                           foregroundColor: AppColors.secondary,
//                                           elevation: 0,
//                                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(context, 10))),
//                                           padding: R.symmetric(context, vertical: 15),
//                                         ),
//                                         child: auth.isLoading
//                                             ? SizedBox(
//                                                 height: R.r(context, 24),
//                                                 width: R.r(context, 24),
//                                                 child: Lottie.asset('assets/animations/dealio_loading_js.json', fit: BoxFit.contain),
//                                               )
//                                             : Text(
//                                                 'Sign up',
//                                                 style: TextStyle(fontSize: R.font(context, 17), fontWeight: FontWeight.bold),
//                                               ),
//                                       ),
//                                     ),
//                                   ),
                                  
//                                   SizedBox(height: R.h(context, 12)),
                                  
//                                   // OR Divider
//                                   Padding(
//                                     padding: R.symmetric(context, vertical: 15),
//                                     child: Row(
//                                       children: [
//                                         Expanded(child: Divider(thickness: 1, color: isDark ? AppColors.darkBorder : AppColors.borderColor)),
//                                         Padding(
//                                           padding: R.symmetric(context, horizontal: 15),
//                                           child: Text(
//                                             'OR',
//                                             style: TextStyle(
//                                               color: secondaryTextColor.withOpacity(0.5),
//                                               fontSize: R.font(context, 13),
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                         Expanded(child: Divider(thickness: 1, color: isDark ? AppColors.darkBorder : AppColors.borderColor)),
//                                       ],
//                                     ),
//                                   ),

//                                   // Google Button
//                                   ElevatedButton(
//                                     onPressed: auth.isLoading ? null : () async {
//                                       final result = await auth.signInWithGoogle();
//                                       if (!mounted) return;
//                                       if (result['success']) {
//                                         showTopSnackBar(
//                                           Overlay.of(context),
//                                           CustomSnackBar.info(
//                                             message: result['message'] ?? 'Opening Google Sign-in...',
//                                             backgroundColor: AppColors.primary,
//                                             textStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
//                                           ),
//                                         );
//                                       }
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: isDark ? AppColors.darkSurface : AppColors.backgroundLight,
//                                       foregroundColor: textColor,
//                                       elevation: 0,
//                                       side: isDark ? const BorderSide(color: AppColors.darkBorder) : null,
//                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(context, 10))),
//                                       padding: R.symmetric(context, vertical: 15),
//                                     ),
//                                     child: Row(
//                                       mainAxisAlignment: MainAxisAlignment.center,
//                                       children: [
//                                         SvgPicture.asset('assets/images/google_icon.svg', height: R.r(context, 30)),
//                                         SizedBox(width: R.r(context, 12)),
//                                         Text(
//                                           'Continue with Google',
//                                           style: TextStyle(fontSize: R.font(context, 16), fontWeight: FontWeight.w700, color: textColor.withOpacity(0.9)),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
                                  
//                                   SizedBox(height: R.h(context, 20)),
//                                   GestureDetector(
//                                     onTap: () => showPrivacyPolicySheet(context),
//                                     child: Text.rich(
//                                       TextSpan(
//                                         text: "By signing up, you agree to our ",
//                                         style: TextStyle(fontSize: R.font(context, 11), color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
//                                         children: [
//                                           TextSpan(
//                                             text: "Terms of Service",
//                                             style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
//                                           ),
//                                           const TextSpan(text: " and "),
//                                           TextSpan(
//                                             text: "Privacy Policy",
//                                             style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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
//                           Text("Already have an account? ", style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted, fontSize: R.font(context, 14))),
//                           TextButton(
//                             onPressed: () => Navigator.pop(context, emailController.text),
//                             child: Text(
//                               "Login",
//                               style: TextStyle(color: isDark ? AppColors.primary : AppColors.secondary, fontWeight: FontWeight.bold, fontSize: R.font(context, 14)),
//                             ),
//                           ),
//                         ],
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

//   Widget _buildTextField({
//     required bool isDark,
//     required TextEditingController controller,
//     required String label,
//     String? autofill,
//     FocusNode? focusNode,
//     FocusNode? nextFocus,
//     Function(String)? onChanged,
//     bool allowSpaces = false,
//   }) {
//     return TextFormField(
//       controller: controller,
//       focusNode: focusNode,
//       autofillHints: autofill != null ? [autofill] : null,
//       textInputAction: TextInputAction.next,
//       onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
//       inputFormatters: [
//         FilteringTextInputFormatter.allow(allowSpaces ? RegExp(r'[a-zA-Z\-\s]') : RegExp(r'[a-zA-Z\-]')),
//       ],
//       onChanged: onChanged,
//       decoration: _inputDecoration(label, isDark),
//       style: TextStyle(fontSize: R.font(context, 16), color: isDark ? AppColors.darkTextPrimary : AppColors.secondary),
//       validator: (v) {
//         if (v == null || v.trim().isEmpty) return 'Required';
//         if (v.trim().length < 2) return 'Min 2 characters';
//         return null;
//       },
//     );
//   }

//   Widget _buildEmailField(bool isDark) {
//     return TextFormField(
//       controller: emailController,
//       focusNode: emailFocusNode,
//       autofillHints: const [AutofillHints.email],
//       keyboardType: TextInputType.emailAddress,
//       textInputAction: TextInputAction.next,
//       onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(passwordFocusNode),
//       inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
//       onChanged: (v) {
//         _onFieldChanged();
//         context.read<AuthProvider>().tempEmail = v;
//       },
//       decoration: _inputDecoration('Email', isDark, hintText: 'you@example.com'),
//       style: TextStyle(fontSize: R.font(context, 16), color: isDark ? AppColors.darkTextPrimary : AppColors.secondary),
//       validator: (value) {
//         if (value == null || value.isEmpty) return 'Enter your Email Address';
//         if (!_isEmailValid(value)) return 'Invalid Email';
//         if (serverEmailError != null) return serverEmailError;
//         return null;
//       },
//     );
//   }

//   Widget _buildPasswordField({
//     required bool isDark,
//     required TextEditingController controller,
//     required String label,
//     required bool visible,
//     required VoidCallback toggle,
//     FocusNode? focusNode,
//     FocusNode? nextFocus,
//     bool isConfirm = false,
//     Function(String)? onChanged,
//     required var validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       focusNode: focusNode,
//       obscureText: !visible,
//       onChanged: onChanged,
//       autofillHints: const [AutofillHints.newPassword],
//       textInputAction: isConfirm ? TextInputAction.done : TextInputAction.next,
//       onFieldSubmitted: (_) => isConfirm ? _register() : FocusScope.of(context).requestFocus(nextFocus),
//       inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
//       style: TextStyle(fontSize: R.font(context, 16), color: isDark ? AppColors.darkTextPrimary : AppColors.secondary),
//       decoration: _inputDecoration(label, isDark).copyWith(
//         suffixIcon: IconButton(
//           icon: Icon(
//             visible ? Icons.visibility : Icons.visibility_off,
//             color: isDark ? AppColors.darkTextMuted : AppColors.secondary.withOpacity(0.6),
//             size: R.r(context, 24),
//           ),
//           onPressed: toggle,
//         ),
//       ),
//       validator: validator,
//     );
//   }

//   InputDecoration _inputDecoration(String label, bool isDark, {String? hintText}) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: TextStyle(
//         color: isDark ? AppColors.darkTextSecondary.withOpacity(0.7) : AppColors.secondary.withOpacity(0.7),
//         fontSize: R.font(context, 15),
//       ),
//       hintText: hintText,
//       hintStyle: TextStyle(
//         color: isDark ? AppColors.darkTextMuted : AppColors.secondary.withOpacity(0.4),
//         fontSize: R.font(context, 15),
//       ),
//       filled: true,
//       fillColor: isDark ? AppColors.darkBackground : AppColors.fillColor,
//       contentPadding: R.symmetric(context, horizontal: 12, vertical: 14),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.r(context, 10)), borderSide: BorderSide.none),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(R.r(context, 10)),
//         borderSide: const BorderSide(color: AppColors.primary, width: 1.25),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(R.r(context, 10)),
//         borderSide: const BorderSide(color: AppColors.errorRed, width: 1),
//       ),
//     );
//   }
// }






import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/features/settings/widgets/privacy_policy_sheet.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
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

    if (!mounted) return;

    if (result['success']) {
      authProvider.tempEmail = emailController.text.trim();
      Navigator.pushReplacementNamed(context, "/otp");
    } else {
      String msg = (result['message'] ?? "").toLowerCase();
      if (msg.contains("email")) {
        setState(() => serverEmailError = result['message']);
        _formKey.currentState!.validate();
      }
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: result['message'] ?? "Registration Failed",
          backgroundColor: AppColors.errorRed,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
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

                      // App Logo
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
                      SizedBox(height: R.h(context, 25)),

                      // Register Card
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
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: R.font(context, 22),
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 6)),
                                  Text(
                                    "Join us to start your journey",
                                    style: TextStyle(
                                      fontSize: R.font(context, 13),
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 25)),

                                  // First Name & Last Name Fields
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          isDark: isDark,
                                          controller: firstNameController,
                                          label: 'First Name',
                                          prefixIcon: LucideIcons.user,
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
                                      SizedBox(width: R.w(context, 10)),
                                      Expanded(
                                        child: _buildTextField(
                                          isDark: isDark,
                                          controller: lastNameController,
                                          label: 'Last Name',
                                          prefixIcon: LucideIcons.user,
                                          focusNode: lastNameFocusNode,
                                          autofill: AutofillHints.familyName,
                                          nextFocus: emailFocusNode,
                                          allowSpaces: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: R.h(context, 15)),

                                  _buildEmailField(isDark),

                                  SizedBox(height: R.h(context, 15)),

                                  _buildPasswordField(
                                    isDark: isDark,
                                    controller: passwordController,
                                    label: 'Password',
                                    hint: 'Min 8 characters',
                                    visible: passwordVisible,
                                    focusNode: passwordFocusNode,
                                    nextFocus: confirmFocusNode,
                                    onChanged: (v) {
                                      if (_autoValidate) {
                                        _formKey.currentState!.validate();
                                      }
                                    },
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Enter a password';
                                      }
                                      if (v.length < 8) {
                                        return 'Min 8 characters';
                                      }
                                      return null;
                                    },
                                    toggle: () => setState(
                                      () => passwordVisible = !passwordVisible,
                                    ),
                                  ),
                                  SizedBox(height: R.h(context, 15)),

                                  _buildPasswordField(
                                    isDark: isDark,
                                    controller: confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Repeat password',
                                    visible: confirmPasswordVisible,
                                    focusNode: confirmFocusNode,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Confirm password';
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

                                  SizedBox(height: R.h(context, 25)),

                                  // Sign Up CTA Button (With 360 Glow & Adaptive Loading)
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
                                            : _register,
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
                                                'Sign Up',
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

                                  // Google Sign-In Button
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
                                              "By signing up, you agree to our ",
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

                      // Bottom Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: R.font(context, 14),
                            ),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, emailController.text),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Login",
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

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? autofill,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    Function(String)? onChanged,
    bool allowSpaces = false,
  }) {
    return TextFormField(
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
      decoration: _inputDecoration(label, isDark, prefixIcon: prefixIcon),
      style: TextStyle(
        fontSize: R.font(context, 15),
        color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (v.trim().length < 2) return 'Min 2 chars';
        return null;
      },
    );
  }

  Widget _buildEmailField(bool isDark) {
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
        context.read<AuthProvider>().tempEmail = v;
      },
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
        if (value == null || value.isEmpty) return 'Enter your email';
        if (!_isEmailValid(value)) return 'Invalid email';
        if (serverEmailError != null) return serverEmailError;
        return null;
      },
    );
  }

  Widget _buildPasswordField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool visible,
    required VoidCallback toggle,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool isConfirm = false,
    Function(String)? onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !visible,
      onChanged: onChanged,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: isConfirm ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) => isConfirm
          ? _register()
          : FocusScope.of(context).requestFocus(nextFocus),
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
      style: TextStyle(
        fontSize: R.font(context, 15),
        color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
      ),
      decoration:
          _inputDecoration(
            label,
            isDark,
            hintText: hint,
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
                visible ? LucideIcons.eye : LucideIcons.eyeClosed,
                size: R.r(context, 20),
              ),
              onPressed: toggle,
            ),
          ),
      validator: validator,
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
          color: isDark ?AppColors.primary : AppColors.secondary.withOpacity(0.3),
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
