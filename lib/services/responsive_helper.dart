import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  static double scale(BuildContext context, double value) {
    final double width = screenWidth(context);
    return value * (width / 375); // 375 = iPhone SE baseline
  }
}
