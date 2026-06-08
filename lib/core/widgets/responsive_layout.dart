import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool center;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1000,
    this.padding = EdgeInsets.zero,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (center) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        ),
      );
    }

    return content;
  }
}
