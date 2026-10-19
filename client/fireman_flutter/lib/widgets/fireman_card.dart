import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Shared dark panel used by character, lobby and game screens.
class FiremanCard extends StatelessWidget {
  const FiremanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.color = AppConstants.bgCard,
    this.borderColor = AppConstants.borderCard,
    this.borderRadius = 16,
    this.borderWidth = 1,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: onTap == null
          ? panel
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onTap, child: panel),
            ),
    );
  }
}
