import 'package:flutter/material.dart';

class CustomCircleAvatar extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  const CustomCircleAvatar({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
