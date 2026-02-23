// import 'package:e_commerce/core/constants/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:e_commerce/core/utils/responsive_helper.dart';
// import '../widgets/admin_sidebar.dart';
// import '../widgets/products_content.dart';
// import '../widgets/user_content.dart';

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({super.key});

//   @override
//   State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   int _selectedIndex = 0;
//   final List<Widget> _pages = [
//     const Center(child: Text("Welcome to Dashboard")),
//     const ProductsContent(),
//     const UsersContent(),
//     const Center(child: Text("Orders Coming Soon...")),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     bool isDesktop = R.isDesktop(context);

//     return Scaffold(
//       backgroundColor: AppColors.background, // تأكد إن اللون ده مش أبيض!
//       appBar: AppBar(
//         title: const Text("Admin Panel"),
//         elevation: 0, // خليه فلات عشان ميعملش ضل
//         backgroundColor: AppColors.background, // خليه نفس لون الخلفية
//         foregroundColor: Colors.black, // لون الكتابة
//       ),
//       body: Row(
//         children: [
//           if (isDesktop)
//             Container(
//               // استخدمت كونتينر عشان أضمن اللون
//               color: AppColors.background,
//               width: 260,
//               child: AdminSidebar(
//                 onIndexChanged: (index) {
//                   setState(
//                     () => _selectedIndex = index,
//                   ); // يحدث الصفحة فوراً [cite: 2026-02-03]
//                 },
//               ),
//             ),
//           Expanded(
//             child: Container(
//               color: AppColors.background, // أكد على اللون هنا كمان
//               child: _pages[_selectedIndex],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
