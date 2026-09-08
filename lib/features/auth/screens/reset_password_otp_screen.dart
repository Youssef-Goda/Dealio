// // import 'dart:async';
// // import 'package:e_commerce/core/constants/colors.dart';
// // import 'package:e_commerce/data/providers/auth_provider.dart';
// // import 'package:e_commerce/features/auth/screens/new_password_screen.dart';
// // import 'package:e_commerce/core/utils/responsive_helper.dart';
// // import 'package:flutter/material.dart';
// // import 'package:lottie/lottie.dart';
// // import 'package:pinput/pinput.dart';
// // import 'package:provider/provider.dart';
// // import 'package:top_snackbar_flutter/custom_snack_bar.dart';
// // import 'package:top_snackbar_flutter/top_snack_bar.dart';

// // class ResetPasswordOtpScreen extends StatefulWidget {
// //   final String email;

// //   const ResetPasswordOtpScreen({super.key, required this.email});

// //   @override
// //   State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
// // }

// // class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
// //   final pinController = TextEditingController();
// //   final focusNode = FocusNode();
// //   bool hasError = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     Future.microtask(() => context.read<AuthProvider>().startOtpTimer());
// //   }

// //   Future<void> resendOtp() async {
// //     final result = await context.read<AuthProvider>().sendResetCode(
// //       widget.email,
// //     );
// //     if (!mounted) return;
// //     if (result['success']) {
// //       // focusNode.requestFocus();
// //     } else {
// //       // ).showSnackBar(SnackBar(content: Text("❌ ${result['message']}")));
// //       showTopSnackBar(
// //         Overlay.of(context),
// //         CustomSnackBar.error(
// //           message: "❌ ${result['message']}",
// //           textStyle: TextStyle(
// //             fontWeight: FontWeight.bold,
// //             color: AppColors.secondary,
// //           ),
// //         ),
// //       );
// //     }
// //   }

// //   void goToNewPassword(String pin) async {
// //     if (pin.length < 6) return;

// //     final auth = context.read<AuthProvider>();
// //     auth.setLoading(true);
// //     setState(() => hasError = false);

// //     try {
// //       final result = await auth.verifyOtp(
// //         otp: pin,
// //         email: widget.email,
// //         isForPasswordReset: true,
// //       );

// //       if (!mounted) return;
// //       auth.setLoading(false);

// //       if (result['success']) {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (context) =>
// //                 NewPasswordScreen(email: widget.email, otp: pin.trim()),
// //           ),
// //         );
// //       } else {
// //         setState(() => hasError = true);
// //         showTopSnackBar(
// //           Overlay.of(context),
// //           CustomSnackBar.error(message: result['message'] ?? "Invalid Code"),
// //         );
// //       }
// //     } catch (e) {
// //       if (mounted) auth.setLoading(false);
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     pinController.dispose();
// //     focusNode.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final authLoading = context.watch<AuthProvider>().isLoading;
// //     final seconds = context.select(
// //       (AuthProvider auth) => auth.remainingSeconds,
// //     );

// //     final defaultPinTheme = PinTheme(
// //       width: R.r(context, 50),
// //       height: R.r(context, 45),
// //       textStyle: TextStyle(
// //         fontSize: R.font(context, 24),
// //         color: AppColors.secondary,
// //         fontWeight: FontWeight.w500,
// //       ),
// //       decoration: BoxDecoration(
// //         borderRadius: BorderRadius.circular(R.r(context, 10)),

// //         border: Border.all(color: AppColors.borderColor),
// //         color: Theme.of(context).cardColor,
// //       ),
// //     );

// //     final auth = Provider.of<AuthProvider>(context);

// //     return GestureDetector(
// //       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
// //       child: AnimatedOpacity(
// //         duration: const Duration(milliseconds: 300),
// //         opacity: auth.isLoading ? 0.8 : 1.0,
// //         child: Scaffold(
// //           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
// //           body: SafeArea(
// //             child: Center(
// //               child: SingleChildScrollView(
// //                 padding: R.symmetric(context, horizontal: 15),
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     // Icon Section
// //                     Container(
// //                       padding: R.all(context, 15),
// //                       decoration: BoxDecoration(
// //                         color: AppColors.primary.withOpacity(0.1),
// //                         shape: BoxShape.circle,
// //                       ),
// //                       child: Icon(
// //                         Icons.lock_reset_rounded,
// //                         size: R.font(context, 85),
// //                         color: AppColors.primary,
// //                       ),
// //                     ),
// //                     SizedBox(height: R.h(context, 50)),
// //                     // Card
// //                     ConstrainedBox(
// //                       constraints: BoxConstraints(
// //                         maxWidth: R.isLargeScreen(context)
// //                             ? 400.0
// //                             : double.infinity,
// //                       ),
// //                       child: Container(
// //                         padding: R.all(context, 15),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white,
// //                           borderRadius: BorderRadius.circular(R.r(context, 20)),
// //                           boxShadow: [
// //                             BoxShadow(
// //                               color: Colors.black.withOpacity(0.07),
// //                               blurRadius: R.r(context, 30),
// //                               offset: const Offset(0, 12),
// //                               spreadRadius: -5,
// //                             ),
// //                           ],
// //                         ),
// //                         child: Column(
// //                           children: [
// //                             Text(
// //                               "OTP Verification",
// //                               style: TextStyle(
// //                                 fontSize: R.font(context, 22),
// //                                 fontWeight: FontWeight.bold,
// //                                 color: AppColors.secondary.withOpacity(0.85),
// //                               ),
// //                             ),
// //                             SizedBox(height: R.h(context, 10)),
// //                             Text(
// //                               "Enter the 6-digit code sent to",
// //                               style: TextStyle(
// //                                 fontSize: R.font(context, 14),
// //                                 color: Colors.grey[500],
// //                               ),
// //                             ),
// //                             SizedBox(height: R.h(context, 25)),

// //                             TextButton(
// //                               onPressed: () => Navigator.pop(context),
// //                               style: TextButton.styleFrom(
// //                                 foregroundColor: AppColors.primary,
// //                                 minimumSize: Size.zero,
// //                                 padding: R.symmetric(
// //                                   context,
// //                                   horizontal: 10,
// //                                   vertical: 6,
// //                                 ),
// //                                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //                               ),
// //                               child: Row(
// //                                 mainAxisSize: MainAxisSize.min,
// //                                 children: [
// //                                   SizedBox(
// //                                     width: R.r(context, 16) + R.w(context, 6),
// //                                   ),
// //                                   Flexible(
// //                                     child: Text(
// //                                       widget.email,
// //                                       textAlign: TextAlign.center,
// //                                       style: TextStyle(
// //                                         fontSize: R.font(context, 14),
// //                                         fontWeight: FontWeight.bold,
// //                                         color: AppColors.secondary,
// //                                       ),
// //                                     ),
// //                                   ),
// //                                   SizedBox(width: R.w(context, 6)),
// //                                   Icon(
// //                                     Icons.mode_edit_rounded,
// //                                     color: AppColors.primary,
// //                                     size: R.r(context, 16),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                             SizedBox(height: R.h(context, 10)),

// //                             // Pin Input Section
// //                             Pinput(
// //                               length: 6,
// //                               controller: pinController,
// //                               focusNode: focusNode,
// //                               forceErrorState: hasError,
// //                               hapticFeedbackType:
// //                                   HapticFeedbackType.lightImpact,
// //                               autofillHints: const [AutofillHints.oneTimeCode],
// //                               onChanged: (v) {
// //                                 if (hasError) setState(() => hasError = false);
// //                               },
// //                               defaultPinTheme: defaultPinTheme,
// //                               errorPinTheme: defaultPinTheme.copyWith(
// //                                 decoration: defaultPinTheme.decoration!
// //                                     .copyWith(
// //                                       border: Border.all(
// //                                         color: Colors.red,
// //                                         width: 1.5,
// //                                       ),
// //                                       color: Colors.red.withOpacity(0.05),
// //                                     ),
// //                               ),
// //                               onCompleted: goToNewPassword,
// //                               focusedPinTheme: defaultPinTheme.copyWith(
// //                                 decoration: defaultPinTheme.decoration!
// //                                     .copyWith(
// //                                       border: Border.all(
// //                                         color: AppColors.primary,
// //                                         width: 1.25,
// //                                       ),
// //                                     ),
// //                               ),
// //                             ),
// //                             if (hasError)
// //                               Padding(
// //                                 padding: const EdgeInsets.only(top: 15.0),
// //                                 child: Row(
// //                                   mainAxisAlignment: MainAxisAlignment.center,
// //                                   children: [
// //                                     Icon(
// //                                       Icons.error_outline_rounded,
// //                                       color: Colors.red,
// //                                       size: R.font(context, 16),
// //                                     ),
// //                                     SizedBox(width: R.w(context, 5)),
// //                                     Text(
// //                                       "Invalid code, please try again",
// //                                       style: TextStyle(
// //                                         color: Colors.red,
// //                                         fontSize: R.font(context, 13),
// //                                         fontWeight: FontWeight.w500,
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ),
// //                             //           Pinput(
// //                             //             length: 6,
// //                             //             controller: pinController,
// //                             //             focusNode: focusNode,
// //                             //             defaultPinTheme: defaultPinTheme,
// //                             //             closeKeyboardWhenCompleted: true,
// //                             //             hapticFeedbackType:
// //                             //                 HapticFeedbackType.lightImpact,
// //                             //             onCompleted: (pin) => goToNewPassword(pin),
// //                             //             onSubmitted: (pin) => goToNewPassword(pin),
// //                             //             focusedPinTheme: defaultPinTheme.copyWith(
// //                             //               decoration: defaultPinTheme.decoration!
// //                             //                   .copyWith(
// //                             //                     border: Border.all(
// //                             //                       color: AppColors.primary,
// //                             //                       width: 1.25,
// //                             //                     ),
// //                             //                   ),
// //                             //             ),
// //                             //           ),
// //                             SizedBox(height: R.h(context, 20)),
// //                             // Timer Section
// //                             seconds > 0
// //                                 ? Row(
// //                                     mainAxisAlignment: MainAxisAlignment.center,
// //                                     children: [
// //                                       Text(
// //                                         "Resend code in ",
// //                                         style: TextStyle(
// //                                           fontSize: R.font(context, 14),
// //                                           color: Colors.grey[600],
// //                                         ),
// //                                       ),
// //                                       Text(
// //                                         "0:${seconds.toString().padLeft(2, '0')}",
// //                                         style: TextStyle(
// //                                           color: AppColors.primary,
// //                                           fontWeight: FontWeight.bold,
// //                                           fontSize: R.font(context, 14),
// //                                         ),
// //                                       ),
// //                                     ],
// //                                   )
// //                                 : TextButton(
// //                                     style: TextButton.styleFrom(
// //                                       foregroundColor: AppColors.primary,
// //                                     ),
// //                                     onPressed: authLoading
// //                                         ? null
// //                                         : () {
// //                                             pinController.clear();
// //                                             setState(() => hasError = false);
// //                                             resendOtp();
// //                                           },
// //                                     child: Text(
// //                                       "Resend new code",
// //                                       style: TextStyle(
// //                                         fontSize: R.font(context, 14),
// //                                         fontWeight: FontWeight.bold,
// //                                         color: AppColors.primary,
// //                                       ),
// //                                     ),
// //                                   ),
// //                             SizedBox(height: R.h(context, 25)),
// //                             // Continue Button
// //                             SizedBox(
// //                               width: double.infinity,
// //                               child: Container(
// //                                 width: double.infinity,
// //                                 decoration: BoxDecoration(
// //                                   color: Theme.of(context).cardColor,
// //                                   borderRadius: BorderRadius.circular(
// //                                     R.r(context, 12),
// //                                   ),
// //                                   boxShadow: [
// //                                     BoxShadow(
// //                                       color: auth.isLoading
// //                                           ? Colors.transparent
// //                                           : AppColors.primary.withOpacity(0.2),
// //                                       blurRadius: R.r(context, 10),
// //                                       offset: const Offset(2, 6),
// //                                     ),
// //                                   ],
// //                                 ),
// //                                 child: ElevatedButton(
// //                                   onPressed: authLoading
// //                                       ? null
// //                                       : () =>
// //                                             goToNewPassword(pinController.text),
// //                                   style: ElevatedButton.styleFrom(
// //                                     backgroundColor: AppColors.primary,
// //                                     disabledBackgroundColor: AppColors.primary
// //                                         .withOpacity(0.2),
// //                                     foregroundColor: AppColors.secondary,
// //                                     elevation: 0,
// //                                     shape: RoundedRectangleBorder(
// //                                       borderRadius: BorderRadius.circular(
// //                                         R.r(context, 10),
// //                                       ),
// //                                     ),
// //                                     padding: R.symmetric(context, vertical: 10),
// //                                   ),
// //                                   child: authLoading
// //                                       ? SizedBox(
// //                                           height: R.r(context, 24),
// //                                           width: R.r(context, 24),
// //                                           child: Lottie.asset(
// //                                             'assets/animations/dealio_loading_js.json',
// //                                             fit: BoxFit.contain,
// //                                           ),
// //                                         )
// //                                       : Text(
// //                                           "Continue",
// //                                           style: TextStyle(
// //                                             fontSize: R.font(context, 17),
// //                                             fontWeight: FontWeight.bold,
// //                                           ),
// //                                         ),
// //                                 ),
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                     SizedBox(height: R.h(context, 100)),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }


// import 'dart:async';
// import 'package:dealio/core/constants/colors.dart';
// import 'package:dealio/data/providers/auth_provider.dart';
// import 'package:dealio/features/auth/screens/new_password_screen.dart';
// import 'package:dealio/core/utils/responsive_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';

// // import 'package:lucide_icons/lucide_icons.dart';
// import 'package:pinput/pinput.dart';
// import 'package:provider/provider.dart';
// import 'package:top_snackbar_flutter/custom_snack_bar.dart';
// import 'package:top_snackbar_flutter/top_snack_bar.dart';

// class ResetPasswordOtpScreen extends StatefulWidget {
//   final String email;

//   const ResetPasswordOtpScreen({super.key, required this.email});

//   @override
//   State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
// }

// class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
//   final pinController = TextEditingController();
//   final focusNode = FocusNode();
//   bool hasError = false;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() => context.read<AuthProvider>().startOtpTimer());
//   }

//   Future<void> resendOtp() async {
//     final result = await context.read<AuthProvider>().sendResetCode(widget.email);
//     if (!mounted) return;
//     if (result['success']) {
//       showTopSnackBar(
//         Overlay.of(context),
//         CustomSnackBar.success(
//           message: "A new code has been sent to your email",
//           backgroundColor: Colors.green.shade600,
//         ),
//       );
//     } else {
//       showTopSnackBar(
//         Overlay.of(context),
//         CustomSnackBar.error(
//           message: result['message'] ?? "Failed to resend code",
//           backgroundColor: AppColors.errorRed,
//           textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//       );
//     }
//   }

//   void goToNewPassword(String pin) async {
//     if (pin.length < 6) return;

//     final auth = context.read<AuthProvider>();
//     auth.setLoading(true);
//     setState(() => hasError = false);

//     try {
//       final result = await auth.verifyOtp(
//         otp: pin,
//         email: widget.email,
//         isForPasswordReset: true,
//       );

//       if (!mounted) return;
//       auth.setLoading(false);

//       if (result['success']) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => NewPasswordScreen(email: widget.email, otp: pin.trim()),
//           ),
//         );
//       } else {
//         setState(() => hasError = true);
//         showTopSnackBar(
//           Overlay.of(context),
//           CustomSnackBar.error(
//             message: result['message'] ?? "Invalid Code",
//             backgroundColor: AppColors.errorRed,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) auth.setLoading(false);
//     }
//   }

//   @override
//   void dispose() {
//     pinController.dispose();
//     focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;
//     final authLoading = context.watch<AuthProvider>().isLoading;
//     final seconds = context.select((AuthProvider auth) => auth.remainingSeconds);
    
//     final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;
//     final Color secondaryTextColor = isDark ? AppColors.darkTextSecondary : Colors.grey[600]!;

//     final defaultPinTheme = PinTheme(
//       width: R.r(context, 50),
//       height: R.r(context, 55),
//       textStyle: TextStyle(
//         fontSize: R.font(context, 24),
//         color: textColor,
//         fontWeight: FontWeight.bold,
//       ),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(R.r(context, 12)),
//         border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
//         color: isDark ? AppColors.darkSurface : Colors.grey[50],
//       ),
//     );

//     return GestureDetector(
//       onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
//       child: AnimatedOpacity(
//         duration: const Duration(milliseconds: 300),
//         opacity: authLoading ? 0.8 : 1.0,
//         child: Scaffold(
//           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//           // appBar: AppBar(
//           //   backgroundColor: Colors.transparent,
//           //   elevation: 0,
//           //   leading: IconButton(
//           //     icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
//           //     onPressed: () => Navigator.pop(context),
//           //   ),
//           // ),
//           body: SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: R.symmetric(context, horizontal: 15),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Icon Section
//                     Container(
//                       padding: R.all(context, 20),
//                       decoration: BoxDecoration(
//                         color: AppColors.primary.withOpacity(0.15),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.lock_reset_rounded,
//                         size: R.font(context, 75),
//                         color: AppColors.primary,
//                       ),
//                     ),
//                     SizedBox(height: R.h(context, 50)),
                    
//                     // Card
//                     ConstrainedBox(
//                       constraints: BoxConstraints(
//                         maxWidth: R.isLargeScreen(context) ? 400.0 : double.infinity,
//                       ),
//                       child: Container(
//                         padding: R.all(context, 20),
//                         decoration: BoxDecoration(
//                           color: isDark ? AppColors.darkSurface : Colors.white,
//                           borderRadius: BorderRadius.circular(R.r(context, 20)),
//                           boxShadow: [
//                             BoxShadow(
//                               color: isDark ? Colors.black26 : Colors.black.withOpacity(0.07),
//                               blurRadius: R.r(context, 30),
//                               offset: const Offset(0, 12),
//                               spreadRadius: -5,
//                             ),
//                           ],
//                           border: isDark ? Border.all(color: AppColors.darkBorder) : null,
//                         ),
//                         child: Column(
//                           children: [
//                             Text(
//                               "OTP Verification",
//                               style: TextStyle(
//                                 fontSize: R.font(context, 22),
//                                 fontWeight: FontWeight.bold,
//                                 color: textColor.withOpacity(0.85),
//                               ),
//                             ),
//                             SizedBox(height: R.h(context, 10)),
//                             Text(
//                               "Enter the 6-digit code sent to",
//                               style: TextStyle(
//                                 fontSize: R.font(context, 14),
//                                 color: secondaryTextColor,
//                               ),
//                             ),
                            
//                             // Edit Email Row
//                             GestureDetector(
//                               onTap: () => Navigator.pop(context),
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 10),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Flexible(
//                                       child: Text(
//                                         widget.email,
//                                         style: TextStyle(
//                                           fontSize: R.font(context, 14),
//                                           fontWeight: FontWeight.bold,
//                                           color: AppColors.primary,
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     const Icon(LucideIcons.pencilLine, color: AppColors.primary, size: 20),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             SizedBox(height: R.h(context, 20)),

//                             // Pin Input
//                             Pinput(
//                               length: 6,
//                               controller: pinController,
//                               focusNode: focusNode,
//                               forceErrorState: hasError,
//                               hapticFeedbackType: HapticFeedbackType.heavyImpact,
//                               autofillHints: const [AutofillHints.oneTimeCode],
//                               onChanged: (v) {
//                                 if (hasError) setState(() => hasError = false);
//                               },
//                               defaultPinTheme: defaultPinTheme,
//                               errorPinTheme: defaultPinTheme.copyWith(
//                                 decoration: defaultPinTheme.decoration!.copyWith(
//                                   border: Border.all(color: AppColors.errorRed, width: 1.5),
//                                   color: AppColors.errorRed.withOpacity(0.05),
//                                 ),
//                               ),
//                               onCompleted: goToNewPassword,
//                               focusedPinTheme: defaultPinTheme.copyWith(
//                                 decoration: defaultPinTheme.decoration!.copyWith(
//                                   border: Border.all(color: AppColors.primary, width: 2),
//                                 ),
//                               ),
//                             ),
                            
//                             if (hasError)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 15.0),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 18),
//                                     SizedBox(width: R.w(context, 5)),
//                                     Text(
//                                       "Invalid code, please try again",
//                                       style: TextStyle(
//                                         color: AppColors.errorRed,
//                                         fontSize: R.font(context, 13),
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                             SizedBox(height: R.h(context, 25)),
                            
//                             // Timer Section
//                             seconds > 0
//                                 ? Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         "Resend code in ",
//                                         style: TextStyle(fontSize: R.font(context, 14), color: secondaryTextColor),
//                                       ),
//                                       Text(
//                                         "0:${seconds.toString().padLeft(2, '0')}",
//                                         style: TextStyle(
//                                           color: AppColors.primary,
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: R.font(context, 14),
//                                         ),
//                                       ),
//                                     ],
//                                   )
//                                 : TextButton(
//                                     onPressed: authLoading ? null : () {
//                                       pinController.clear();
//                                       setState(() => hasError = false);
//                                       resendOtp();
//                                     },
//                                     child: const Text(
//                                       "Resend new code",
//                                       style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
//                                     ),
//                                   ),
                                  
//                             SizedBox(height: R.h(context, 30)),
                            
//                             // Continue Button
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
//                                   onPressed: authLoading ? null : () => goToNewPassword(pinController.text),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: AppColors.primary,
//                                     disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
//                                     foregroundColor: AppColors.secondary,
//                                     elevation: 0,
//                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(context, 10))),
//                                     padding: R.symmetric(context, vertical: 15),
//                                   ),
//                                   child: authLoading
//                                       ? SizedBox(
//                                           height: 25,
//                                           width: 25,
//                                           child: Lottie.asset('assets/animations/dealio_loading_js.json', fit: BoxFit.contain),
//                                         )
//                                       : Text(
//                                           "Continue",
//                                           style: TextStyle(fontSize: R.font(context, 17), fontWeight: FontWeight.bold),
//                                         ),
//                                 ),
//                               ),
//                             ),
//                           ],
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
// }





import 'dart:async';
import 'package:dealio/core/constants/colors.dart';
import 'package:dealio/data/providers/auth_provider.dart';
import 'package:dealio/features/auth/screens/new_password_screen.dart';
import 'package:dealio/core/utils/responsive_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ResetPasswordOtpScreen extends StatefulWidget {
  final String email;

  const ResetPasswordOtpScreen({super.key, required this.email});

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AuthProvider>().startOtpTimer());
  }

  Future<void> resendOtp() async {
    final result = await context.read<AuthProvider>().sendResetCode(widget.email);
    if (!mounted) return;
    if (result['success']) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message: "A new code has been sent to your email",
          backgroundColor: Colors.green.shade600,
        ),
      );
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: result['message'] ?? "Failed to resend code",
          backgroundColor: AppColors.errorRed,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
  }

  void goToNewPassword(String pin) async {
    if (pin.length < 6) return;

    final auth = context.read<AuthProvider>();
    auth.setLoading(true);
    setState(() => hasError = false);

    try {
      final result = await auth.verifyOtp(
        otp: pin,
        email: widget.email,
        isForPasswordReset: true,
      );

      if (!mounted) return;
      auth.setLoading(false);

      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordScreen(email: widget.email, otp: pin.trim()),
          ),
        );
      } else {
        setState(() => hasError = true);
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: result['message'] ?? "Invalid Code",
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) auth.setLoading(false);
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authLoading = context.watch<AuthProvider>().isLoading;
    final seconds = context.select((AuthProvider auth) => auth.remainingSeconds);
    
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;
    final Color secondaryTextColor = isDark ? AppColors.darkTextSecondary : Colors.grey[600]!;

    final defaultPinTheme = PinTheme(
      width: R.r(context, 48),
      height: R.r(context, 54),
      textStyle: TextStyle(
        fontSize: R.font(context, 22),
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.r(context, 12)),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
        color: isDark ? AppColors.darkBackground : Colors.grey[50],
      ),
    );

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: authLoading ? 0.8 : 1.0,
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
                        child: Column(
                          children: [
                            // Header Icon Section
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
                                LucideIcons.shieldCheck,
                                size: R.font(context, 44),
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: R.h(context, 16)),

                            Text(
                              "OTP Verification",
                              style: TextStyle(
                                fontSize: R.font(context, 20),
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(height: R.h(context, 6)),
                            Text(
                              "Enter the 6-digit code sent to",
                              style: TextStyle(
                                fontSize: R.font(context, 13),
                                color: secondaryTextColor,
                              ),
                            ),
                            
                            // Interactive Email Row with Mouse Pointer Cursor
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Padding(
                                  padding: R.symmetric(context, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.email,
                                          style: TextStyle(
                                            fontSize: R.font(context, 13),
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: R.w(context, 6)),
                                      Icon(
                                        LucideIcons.pencilLine,
                                        color: AppColors.primary,
                                        size: R.font(context, 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: R.h(context, 25)),

                            // Pin Input
                            Pinput(
                              length: 6,
                              controller: pinController,
                              focusNode: focusNode,
                              forceErrorState: hasError,
                              hapticFeedbackType: HapticFeedbackType.heavyImpact,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              onChanged: (v) {
                                if (hasError) setState(() => hasError = false);
                              },
                              defaultPinTheme: defaultPinTheme,
                              errorPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: AppColors.errorRed, width: 1.5),
                                  color: AppColors.errorRed.withOpacity(0.05),
                                ),
                              ),
                              onCompleted: goToNewPassword,
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                            ),
                            
                            if (hasError)
                              Padding(
                                padding: R.symmetric(context, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.circleAlert,
                                      color: AppColors.errorRed,
                                      size: R.font(context, 16),
                                    ),
                                    SizedBox(width: R.w(context, 6)),
                                    Text(
                                      "Invalid code, please try again",
                                      style: TextStyle(
                                        color: AppColors.errorRed,
                                        fontSize: R.font(context, 12),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            SizedBox(height: R.h(context, 25)),
                            
                            // Timer Section
                            seconds > 0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Resend code in ",
                                        style: TextStyle(fontSize: R.font(context, 13), color: secondaryTextColor),
                                      ),
                                      Text(
                                        "0:${seconds.toString().padLeft(2, '0')}",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: R.font(context, 13),
                                        ),
                                      ),
                                    ],
                                  )
                                : TextButton(
                                    onPressed: authLoading ? null : () {
                                      pinController.clear();
                                      setState(() => hasError = false);
                                      resendOtp();
                                    },
                                    child: const Text(
                                      "Resend new code",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  
                            SizedBox(height: R.h(context, 30)),
                            
                            // Action Buttons (Cancel + Continue)
                            Row(
                              children: [
                                // Cancel Button (Outlined)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: authLoading
                                        ? null
                                        : () => Navigator.pop(context),
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
                                      "Cancel",
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
                                
                                // Continue Button (With 360 Glow)
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        R.r(context, 12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: authLoading
                                              ? Colors.transparent
                                              : AppColors.primary.withOpacity(0.35),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                          offset: Offset.zero,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: authLoading
                                          ? null
                                          : () => goToNewPassword(pinController.text),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor:
                                            AppColors.primary.withOpacity(0.4),
                                        foregroundColor: AppColors.secondary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            R.r(context, 12),
                                          ),
                                        ),
                                        padding: R.symmetric(context, vertical: 15),
                                      ),
                                      child: authLoading
                                          ? SizedBox(
                                              height: R.r(context, 22),
                                              width: R.r(context, 22),
                                              child: kIsWeb
                                                  ? const CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                        AppColors.secondary,
                                                      ),
                                                    )
                                                  : Lottie.asset(
                                                      'assets/animations/dealio_loading_js.json',
                                                      fit: BoxFit.contain,
                                                    ),
                                            )
                                          : Text(
                                              "Continue",
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
}