import 'package:flutter/material.dart';

/// Mobil, tablet ve farklı en-boy oranlarındaki cihazlar için
/// güvenli alan ve ekran ölçekleme yöneticisi.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool applySafeArea;
  final EdgeInsets? customPadding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.applySafeArea = true,
    this.customPadding,
  });

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isVerySmall = width < 360;
        final isWide = width >= 600;

        final horizontalPadding = customPadding?.left ??
            (isVerySmall ? 12.0 : (isWide ? 32.0 : 16.0));
        final verticalPadding = customPadding?.top ??
            (isVerySmall ? 8.0 : (isWide ? 20.0 : 12.0));

        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          padding: customPadding ??
              EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
          child: child,
        );
      },
    );

    if (applySafeArea) {
      content = SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 4),
        child: content,
      );
    }

    return content;
  }
}
