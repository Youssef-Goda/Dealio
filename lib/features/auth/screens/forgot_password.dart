// import 'package:dealio/core/constants/colors.dart';
// import 'package:dealio/data/providers/auth_provider.dart';
// import 'package:dealio/features/auth/screens/reset_password_otp_screen.dart';
// import 'package:dealio/core/utils/responsive_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
// import 'package:top_snackbar_flutter/custom_snack_bar.dart';
// import 'package:top_snackbar_flutter/top_snack_bar.dart';

// class ForgotPassword extends StatefulWidget {
//   const ForgotPassword({super.key});

//   @override
//   State<ForgotPassword> createState() => _ForgotPasswordState();
// }

// class _ForgotPasswordState extends State<ForgotPassword> {
//   final emailController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool isLoading = false;
//   bool hasError = false;
//   bool _autoValidate = false;

//   @override
//   void dispose() {
//     emailController.dispose();
//     super.dispose();
//   }

//   bool _isEmailValid(String email) {
//     return RegExp(
//       r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,4}$",
//     ).hasMatch(email);
//   }

//   void _clearServerError() {
//     if (hasError) {
//       setState(() => hasError = false);
//       _formKey.currentState!.validate();
//     }
//   }

//   Future<void> sendResetCode() async {
//     FocusScope.of(context).unfocus();
//     HapticFeedback.mediumImpact();
//     if (!_formKey.currentState!.validate()) {
//       setState(() => _autoValidate = true);
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       hasError = false;
//     });

//     try {
//       final auth = context.read<AuthProvider>();
//       final result = await auth.sendResetCode(emailController.text.trim());

//       if (!mounted) return;

//       if (result['success']) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) =>
//                 ResetPasswordOtpScreen(email: emailController.text.trim()),
//           ),
//         );
//       } else {
//         setState(() {
//           hasError = true;
//           _autoValidate = true;
//         });
//         _formKey.currentState!.validate();

//         showTopSnackBar(
//           Overlay.of(context),
//           CustomSnackBar.error(
//             message: result['message'] ?? 'Error occurred',
//             backgroundColor: AppColors.errorRed,
//             textStyle: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: AppColors.white,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//        if (!mounted) return;
//     } finally {
//       if (mounted) setState(() => isLoading = false);
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
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;
//     final Color secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

//     return GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: AnimatedOpacity(
//         duration: const Duration(milliseconds: 300),
//         opacity: isLoading ? 0.8 : 1.0,
//         child: Scaffold(
//           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//           body: SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: R.symmetric(context, horizontal: 15),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Icon Section
//                     Container(
//                       padding: R.all(context, 15),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary.withOpacity(0.15),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.key_sharp,
//                         size: R.font(context, 85),
//                         color: AppColors.primary,
//                       ),
//                     ),
//                     SizedBox(height: R.h(context, 65)),

//                     // Reset Card
//                     ConstrainedBox(
//                       constraints: BoxConstraints(
//                         maxWidth: R.isLargeScreen(context) ? 400.0 : double.infinity,
//                       ),
//                       child: Container(
//                         padding: EdgeInsets.only(
//                           top: R.r(context, 20),
//                           left: R.r(context, 15),
//                           right: R.r(context, 15),
//                           bottom: R.r(context, 10),
//                         ),
//                         decoration: BoxDecoration(
//                           color: isDark ? AppColors.darkSurface : Theme.of(context).cardColor,
//                           borderRadius: BorderRadius.circular(R.r(context, 20)),
//                           boxShadow: [
//                             BoxShadow(
//                               color: isDark ? Colors.black26 : AppColors.black.withOpacity(0.07),
//                               blurRadius: R.r(context, 30),
//                               offset: const Offset(0, 12),
//                               spreadRadius: -5,
//                             ),
//                           ],
//                           border: isDark ? Border.all(color: AppColors.darkBorder, width: 1) : null,
//                         ),
//                         child: Form(
//                           key: _formKey,
//                           autovalidateMode: _autoValidate
//                               ? AutovalidateMode.onUserInteraction
//                               : AutovalidateMode.disabled,
//                           child: Column(
//                             children: [
//                               Text(
//                                 "Reset Password",
//                                 style: TextStyle(
//                                   fontSize: R.font(context, 22),
//                                   fontWeight: FontWeight.bold,
//                                   color: textColor.withOpacity(0.85),
//                                 ),
//                               ),
//                               SizedBox(height: R.h(context, 12)),
//                               Text(
//                                 "Enter your email to receive a reset code",
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: R.font(context, 13),
//                                   color: isDark ? AppColors.darkTextMuted : Colors.grey[500],
//                                 ),
//                               ),
//                               SizedBox(height: R.h(context, 45)),

//                               _buildEmailField(isDark),

//                               SizedBox(height: R.h(context, 30)),

//                               // Send code button
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(R.r(context, 12)),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: isLoading
//                                             ? AppColors.transparent
//                                             : AppColors.primary.withOpacity(0.3),
//                                         blurRadius: R.r(context, 15),
//                                         offset: const Offset(0, 4),
//                                       ),
//                                     ],
//                                   ),
//                                   child: ElevatedButton(
//                                     onPressed: isLoading ? null : sendResetCode,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: AppColors.primary,
//                                       disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
//                                       foregroundColor: AppColors.secondary,
//                                       elevation: 0,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(R.r(context, 10)),
//                                       ),
//                                       padding: R.symmetric(context, vertical: 15),
//                                     ),
//                                     child: isLoading
//                                         ? SizedBox(
//                                             height: R.r(context, 26),
//                                             width: R.r(context, 26),
//                                             child: Lottie.asset(
//                                               'assets/animations/dealio_loading_js.json',
//                                               fit: BoxFit.contain,
//                                             ),
//                                           )
//                                         : Text(
//                                             'Send code',
//                                             style: TextStyle(
//                                               fontSize: R.font(context, 17),
//                                               fontWeight: FontWeight.bold,
//                                               color: AppColors.secondary,
//                                             ),
//                                           ),
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(height: R.h(context, 15)),
                              
//                               // Back to Login
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context, emailController.text),
//                                 child: Text(
//                                   "Back",
//                                   style: TextStyle(
//                                     color: isDark ? AppColors.darkTextMuted : AppColors.secondary,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: R.font(context, 14),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: R.h(context, 50)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailField(bool isDark) {
//     return TextFormField(
//       controller: emailController,
//       autofillHints: const [AutofillHints.email],
//       inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
//       textInputAction: TextInputAction.done,
//       keyboardType: TextInputType.emailAddress,
//       onChanged: (v) {
//         _clearServerError();
//         context.read<AuthProvider>().tempEmail = v;
//       },
//       onFieldSubmitted: (_) {
//         if (!isLoading) sendResetCode();
//       },
//       decoration: _inputDecoration('Email', isDark, hintText: 'you@example.com'),
//       style: TextStyle(
//         fontSize: R.font(context, 16),
//         color: isDark ? AppColors.darkTextPrimary : AppColors.secondary,
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) return 'Please enter your email';
//         if (!_isEmailValid(value)) return 'Enter a valid email';
//         if (hasError) return '';
//         return null;
//       },
//     );
//   }

//   InputDecoration _inputDecoration(String label, bool isDark, {String? hintText}) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: TextStyle(
//         color: isDark ? AppColors.darkTextSecondary.withOpacity(0.7) : AppColors.secondary.withOpacity(0.7),
//         fontSize: R.font(context, 14),
//       ),
//       hintText: hintText,
//       hintStyle: TextStyle(
//         color: isDark ? AppColors.darkTextMuted : AppColors.secondary.withOpacity(0.5),
//         fontSize: R.font(context, 15),
//       ),
//       filled: true,
//       fillColor: isDark ? AppColors.darkBackground : AppColors.fillColor,
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
//     );
//   }
// }







import 'dart:async';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/features/auth/screens/reset_password_otp_screen.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  bool isLoading = false;
  bool hasError = false;
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
        _formKey.currentState!.validate();

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: result['message'] ?? 'Error occurred',
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
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                          color: isDark
                              ? AppColors.darkSurface
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(R.r(context, 25)),
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
                              ? Border.all(color: AppColors.darkBorder)
                              : null,
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autoValidate
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            children: [
                              // Header Icon Section (Matching OTP Screens)
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
                                  LucideIcons.keyRound,
                                  size: R.font(context, 44),
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: R.h(context, 16)),

                              Text(
                                "Reset Password",
                                style: TextStyle(
                                  fontSize: R.font(context, 20),
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: R.h(context, 6)),
                              Text(
                                "Enter your email to receive a reset code",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: R.font(context, 13),
                                  color: secondaryTextColor,
                                ),
                              ),
                              SizedBox(height: R.h(context, 25)),

                              _buildEmailField(isDark),

                              SizedBox(height: R.h(context, 30)),

                              // Action Buttons (Back + Send Code)
                              Row(
                                children: [
                                  // Back Button
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => Navigator.pop(
                                              context,
                                              emailController.text,
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
                                        "Back",
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

                                  // Send Code Button (With 360 Glow & Adaptive Loading)
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
                                            : sendResetCode,
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
                                                'Send code',
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
                    ),
                    SizedBox(height: R.h(context, 50)),
                  ],
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
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) {
        _clearServerError();
        context.read<AuthProvider>().tempEmail = v;
      },
      onFieldSubmitted: (_) {
        if (!isLoading) sendResetCode();
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
        if (value == null || value.isEmpty) return 'Please enter your email';
        if (!_isEmailValid(value)) return 'Enter a valid email';
        if (hasError) return '';
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
 