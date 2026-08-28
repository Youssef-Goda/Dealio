// import 'package:e_commerce/core/constants/colors.dart';
// import 'package:e_commerce/data/providers/auth_provider.dart';
// import 'package:e_commerce/core/utils/responsive_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
// import 'package:top_snackbar_flutter/custom_snack_bar.dart';
// import 'package:top_snackbar_flutter/top_snack_bar.dart';

// class NewPasswordScreen extends StatefulWidget {
//   final String email;
//   final String otp;

//   const NewPasswordScreen({super.key, required this.email, required this.otp});

//   @override
//   State<NewPasswordScreen> createState() => _NewPasswordScreenState();
// }

// class _NewPasswordScreenState extends State<NewPasswordScreen> {
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   bool isPasswordVisible = false;
//   bool isConfirmVisible = false;
//   bool _autoValidate = false;
//   String? passwordServerError;

//   @override
//   void dispose() {
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     super.dispose();
//   }

//   Future<void> handleResetPassword() async {
//     FocusScope.of(context).unfocus();
//     HapticFeedback.mediumImpact();
//     setState(() => passwordServerError = null);

//     if (!_formKey.currentState!.validate()) {
//       setState(() => _autoValidate = true);
//       return;
//     }

//     final authProvider = context.read<AuthProvider>();
//     final result = await authProvider.resetPassword(
//       email: widget.email,
//       otp: widget.otp,
//       newPassword: passwordController.text.trim(),
//     );

//     if (!mounted) return;

//     if (result['success']) {
//       showTopSnackBar(
//         Overlay.of(context),
//         CustomSnackBar.success(
//           message: "Password updated successfully!",
//           backgroundColor: Colors.green.shade600,
//         ),
//       );
//       Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
//     } else {
//       String message = result['message'];

//       if (message.toLowerCase().contains('same as old')) {
//         setState(() => passwordServerError = "New password cannot be the same as the old one");
//         _formKey.currentState!.validate();
//       } else {
//         showTopSnackBar(
//           Overlay.of(context),
//           CustomSnackBar.error(
//             message: message,
//             backgroundColor: AppColors.errorRed,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final authLoading = context.watch<AuthProvider>().isLoading;
//     final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;

//     return GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: Scaffold(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         body: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: R.symmetric(context, horizontal: 15),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildHeader(isDark, textColor),
//                   SizedBox(height: R.h(context, 40)),
                  
//                   // Card Container
//                   ConstrainedBox(
//                     constraints: BoxConstraints(
//                       maxWidth: R.isLargeScreen(context) ? 400.0 : double.infinity,
//                     ),
//                     child: Container(
//                       padding: R.all(context, 20),
//                       decoration: BoxDecoration(
//                         color: isDark ? AppColors.darkSurface : Colors.white,
//                         borderRadius: BorderRadius.circular(R.r(context, 25)),
//                         boxShadow: [
//                           BoxShadow(
//                             color: isDark ? Colors.black26 : Colors.black.withOpacity(0.07),
//                             blurRadius: 30,
//                             offset: const Offset(0, 12),
//                           ),
//                         ],
//                         border: isDark ? Border.all(color: AppColors.darkBorder) : null,
//                       ),
//                       child: Form(
//                         key: _formKey,
//                         autovalidateMode: _autoValidate
//                             ? AutovalidateMode.onUserInteraction
//                             : AutovalidateMode.disabled,
//                         child: Column(
//                           children: [
//                             _buildPasswordField(
//                               isDark: isDark,
//                               controller: passwordController,
//                               label: "New Password",
//                               hint: "Min. 8 characters",
//                               isVisible: isPasswordVisible,
//                               toggleVisible: () => setState(() => isPasswordVisible = !isPasswordVisible),
//                             ),
//                             SizedBox(height: R.h(context, 20)),
//                             _buildPasswordField(
//                               isDark: isDark,
//                               controller: confirmPasswordController,
//                               label: "Confirm Password",
//                               hint: "Repeat your password",
//                               isVisible: isConfirmVisible,
//                               isConfirm: true,
//                               toggleVisible: () => setState(() => isConfirmVisible = !isConfirmVisible),
//                             ),
//                             SizedBox(height: R.h(context, 35)),
                            
//                             // Submit Button
//                             SizedBox(
//                               width: double.infinity,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(R.r(context, 12)),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: authLoading ? Colors.transparent : AppColors.primary.withOpacity(0.3),
//                                       blurRadius: 15,
//                                       offset: const Offset(0, 5),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ElevatedButton(
//                                   onPressed: authLoading ? null : handleResetPassword,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: AppColors.primary,
//                                     disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
//                                     foregroundColor: AppColors.secondary,
//                                     elevation: 0,
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(context, 12))),
//                                     padding: R.symmetric(context, vertical: 15),
//                                   ),
//                                   child: authLoading
//                                       ? SizedBox(
//                                           height: 25,
//                                           width: 25,
//                                           child: Lottie.asset('assets/animations/dealio_loading_js.json', fit: BoxFit.contain),
//                                         )
//                                       : Text(
//                                           'SUBMIT',
//                                           style: TextStyle(
//                                             fontSize: R.font(context, 16),
//                                             fontWeight: FontWeight.bold,
//                                             letterSpacing: 1.2,
//                                           ),
//                                         ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: R.h(context, 20)),
//                   TextButton.icon(
//                     onPressed: authLoading ? null : () => Navigator.pop(context),
//                     icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.secondary),
//                     label: Text(
//                       "Back to OTP",
//                       style: TextStyle(
//                         color: isDark ? AppColors.darkTextMuted : AppColors.secondary,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader(bool isDark, Color textColor) {
//     return Column(
//       children: [
//         Container(
//           padding: R.all(context, 20),
//           decoration: BoxDecoration(
//             color: AppColors.primary.withOpacity(0.15),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             Icons.lock_open_rounded,
//             size: R.font(context, 70),
//             color: AppColors.primary,
//           ),
//         ),
//         SizedBox(height: R.h(context, 20)),
//         Text(
//           "Create New Password",
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: R.font(context, 26),
//             fontWeight: FontWeight.w900,
//             color: textColor,
//           ),
//         ),
//         SizedBox(height: R.h(context, 10)),
//         Text(
//           "Choose a strong password to secure your account",
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: R.font(context, 14),
//             color: isDark ? AppColors.darkTextSecondary : Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPasswordField({
//     required bool isDark,
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required bool isVisible,
//     required VoidCallback toggleVisible,
//     bool isConfirm = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontWeight: FontWeight.bold, 
//             fontSize: R.font(context, 14),
//             color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
//           ),
//         ),
//         SizedBox(height: R.h(context, 8)),
//         TextFormField(
//           controller: controller,
//           obscureText: !isVisible,
//           inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
//           style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.secondary),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400, fontSize: 13),
//             filled: true,
//             fillColor: isDark ? AppColors.darkBackground : AppColors.fillColor,
//             contentPadding: R.symmetric(context, horizontal: 16, vertical: 16),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(15),
//               borderSide: BorderSide.none,
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(15),
//               borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
//             ),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
//                 color: AppColors.primary.withOpacity(0.6),
//                 size: 20,
//               ),
//               onPressed: toggleVisible,
//             ),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) return 'Please enter password';
//             if (value.length < 8) return 'Must be at least 8 characters';
//             if (isConfirm) {
//               if (value != passwordController.text) return 'Passwords do not match';
//             } else {
//               if (passwordServerError != null) return passwordServerError;
//             }
//             return null;
//           },
//           onChanged: (value) {
//             if (!isConfirm && passwordServerError != null) {
//               setState(() => passwordServerError = null);
//               _formKey.currentState!.validate();
//             }
//           },
//         ),
//       ],
//     );
//   }
// }



import 'package:e_commerce/core/constants/colors.dart';
import 'package:e_commerce/data/providers/auth_provider.dart';
import 'package:e_commerce/core/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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

  bool isPasswordVisible = false;
  bool isConfirmVisible = false;
  bool _autoValidate = false;
  String? passwordServerError;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleResetPassword() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => passwordServerError = null);

    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.resetPassword(
      email: widget.email,
      otp: widget.otp,
      newPassword: passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result['success']) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message: "Password updated successfully!",
          backgroundColor: Colors.green.shade600,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      String message = result['message'];

      if (message.toLowerCase().contains('same as old')) {
        setState(() => passwordServerError = "New password cannot be the same as the old one");
        _formKey.currentState!.validate();
      } else {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: message,
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authLoading = context.watch<AuthProvider>().isLoading;
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: R.symmetric(context, horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(isDark, textColor),
                  SizedBox(height: R.h(context, 40)),
                  
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: R.isLargeScreen(context) ? 400.0 : double.infinity,
                    ),
                    child: Container(
                      padding: R.all(context, 20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(R.r(context, 25)),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.07),
                            blurRadius: R.r(context, 30),
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autoValidate
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          children: [
                            _buildPasswordField(
                              isDark: isDark,
                              controller: passwordController,
                              label: "New Password",
                              hint: "Min. 8 characters",
                              isVisible: isPasswordVisible,
                              toggleVisible: () => setState(() => isPasswordVisible = !isPasswordVisible),
                            ),
                            SizedBox(height: R.h(context, 20)),
                            _buildPasswordField(
                              isDark: isDark,
                              controller: confirmPasswordController,
                              label: "Confirm Password",
                              hint: "Repeat your password",
                              isVisible: isConfirmVisible,
                              isConfirm: true,
                              toggleVisible: () => setState(() => isConfirmVisible = !isConfirmVisible),
                            ),
                            SizedBox(height: R.h(context, 35)),
                            
                            // Buttons Row
                            Row(
                              children: [
                                // Cancel Button (Outlined)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: authLoading ? null : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: R.symmetric(context, vertical: 15),
                                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(context, 12))),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: R.font(context, 16),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: R.w(context, 15)),
                                // Submit Button
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(R.r(context, 12)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: authLoading ? Colors.transparent : AppColors.primary.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: authLoading ? null : handleResetPassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                                        foregroundColor: AppColors.secondary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(context, 12))),
                                        padding: R.symmetric(context, vertical: 15),
                                      ),
                                      child: authLoading
                                          ? SizedBox(
                                              height: 25,
                                              width: 25,
                                              child: Lottie.asset('assets/animations/dealio_loading_js.json', fit: BoxFit.contain),
                                            )
                                          : Text(
                                              'SUBMIT',
                                              style: TextStyle(
                                                fontSize: R.font(context, 16),
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
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
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return Column(
      children: [
        Container(
          padding: R.all(context, 20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_open_rounded,
            size: R.font(context, 70),
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: R.h(context, 20)),
        Text(
          "Create New Password",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: R.font(context, 26),
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        SizedBox(height: R.h(context, 10)),
        Text(
          "Choose a strong password to secure your account",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: R.font(context, 14),
            color: isDark ? AppColors.darkTextSecondary : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required bool isDark,
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
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: R.font(context, 14),
            color: isDark ? AppColors.darkTextSecondary : AppColors.secondary,
          ),
        ),
        SizedBox(height: R.h(context, 8)),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.secondary),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : AppColors.fillColor,
            contentPadding: R.symmetric(context, horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: AppColors.primary.withOpacity(0.6),
                size: 20,
              ),
              onPressed: toggleVisible,
              mouseCursor: SystemMouseCursors.click, // الماوس يقلب إيد هنا
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter password';
            if (value.length < 8) return 'Must be at least 8 characters';
            if (isConfirm) {
              if (value != passwordController.text) return 'Passwords do not match';
            } else {
              if (passwordServerError != null) return passwordServerError;
            }
            return null;
          },
        ),
      ],
    );
  }
}