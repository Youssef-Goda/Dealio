import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class R {
  // Check if large screen (Web/Tablet)
  static bool get isLargeScreen => ScreenUtil().screenWidth > 600;
  
  // Font sizes
  static double font(double size) => isLargeScreen ? size : size.sp;
  
  // Heights
  static double h(double size) => isLargeScreen ? size : size.h;
  
  // Widths
  static double w(double size) => isLargeScreen ? size : size.w;
  
  // Radius & equal padding
  static double r(double size) => isLargeScreen ? size : size.r;
  
  // Edge Insets - symmetric
  static EdgeInsets symmetric({double? h, double? v}) {
    return EdgeInsets.symmetric(
      horizontal: h != null ? (isLargeScreen ? h : h.w) : 0,
      vertical: v != null ? (isLargeScreen ? v : v.h) : 0,
    );
  }
  
  // Edge Insets - all
  static EdgeInsets all(double size) {
    return EdgeInsets.all(isLargeScreen ? size : size.r);
  }
}