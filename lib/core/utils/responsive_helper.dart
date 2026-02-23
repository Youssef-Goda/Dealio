import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class R {
  R._();

  // ============================================================
  // 1. تحديد نوع الشاشة (Breakpoints)
  // ============================================================

  /// موبايل: عرض الشاشة أقل من أو يساوي 600
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= 600;

  /// تابلت: عرض الشاشة من 600 لـ 1024
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 600 && width <= 1024;
  }

  /// ديسكتوب: عرض الشاشة أكبر من 1024
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 1024;

  /// الشاشات الكبيرة (تابلت + ديسكتوب)
  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 600;

  // ============================================================
  // 2. الخطوط (Fonts)
  // ============================================================

  /// حجم الخط responsive
  /// - موبايل: يستخدم ScreenUtil
  /// - تابلت: تكبير بسيط (5%)
  /// - ديسكتوب: تكبير أوضح (8%)  عدلنا من 10% لـ 8%
  static double font(BuildContext context, double size) {
    if (isMobile(context)) return size.sp;
    if (isTablet(context)) return size * 1.05;
    return size * 1.08;
  }

  // ============================================================
  // 3. الارتفاعات (Heights)
  // ============================================================

  /// الارتفاع responsive
  /// - موبايل: يستخدم ScreenUtil
  /// - تابلت والويب: ثابت (عشان منضخمش الشاشة)
  static double h(BuildContext context, double size) {
    if (isMobile(context)) return size.h;
    return size;
  }

  // ============================================================
  // 4. العروض (Widths)
  // ============================================================

  /// العرض responsive
  /// - موبايل: يستخدم ScreenUtil
  /// - تابلت والويب: ثابت
  static double w(BuildContext context, double size) {
    if (isMobile(context)) return size.w;
    return size;
  }

  // ============================================================
  // 5. الزوايا الدائرية (Radius)
  // ============================================================

  /// نصف القطر responsive
  /// - موبايل: يستخدم ScreenUtil
  /// - تابلت والويب: ثابت
  static double r(BuildContext context, double size) {
    if (isMobile(context)) return size.r;
    return size;
  }

  // ============================================================
  // 6. الحواف (Padding & Margin)
  // ============================================================

  /// حواف متساوية من كل الجهات
  static EdgeInsets all(BuildContext context, double size) {
    final value = isMobile(context) ? size.r : size;
    return EdgeInsets.all(value);
  }

  /// حواف متماثلة (أفقية وعمودية)
  static EdgeInsets symmetric(
    BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    final mobile = isMobile(context);
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? (mobile ? horizontal.w : horizontal) : 0,
      vertical: vertical != null ? (mobile ? vertical.h : vertical) : 0,
    );
  }

  // إحواف مخصصة لكل جانب
  static EdgeInsets only(
    BuildContext context, {
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final mobile = isMobile(context);
    return EdgeInsets.only(
      left: left != null ? (mobile ? left.w : left) : 0,
      top: top != null ? (mobile ? top.h : top) : 0,
      right: right != null ? (mobile ? right.w : right) : 0,
      bottom: bottom != null ? (mobile ? bottom.h : bottom) : 0,
    );
  }

  // ============================================================
  // 7. دوال مساعدة إضافية (Helper Functions)
  // ============================================================

  // الحصول على عرض الشاشة
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // الحصول على ارتفاع الشاشة
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // حجم أيقونة responsive
  static double iconSize(BuildContext context, double size) {
    if (isMobile(context)) return size;
    if (isTablet(context)) return size * 1.1;
    return size * 1.15;
  }

  // مسافة عمودية (SizedBox)
  static SizedBox verticalSpace(BuildContext context, double height) {
    return SizedBox(height: h(context, height));
  }

  // مسافة أفقية (SizedBox)
  static SizedBox horizontalSpace(BuildContext context, double width) {
    return SizedBox(width: w(context, width));
  }

  // قيمة مختلفة حسب نوع الجهاز
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}