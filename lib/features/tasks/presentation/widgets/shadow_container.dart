import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/themes/colors.dart';

class ShadowedContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double? borderWidth;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  const ShadowedContainer({
    super.key,
    this.width,
    this.height,
    this.borderColor,
    required this.child,
    this.borderWidth,
    this.padding,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (width)?.w,
      height: (height)?.h,
      padding:
          padding ??
          EdgeInsetsDirectional.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.onSecondaryContainer,
        border: Border.all(
          color: borderColor ?? AppColors.backgroundColor,
          width: (borderWidth ?? 1).w,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            blurRadius: 2.r,
            spreadRadius: 1.r,
            offset: Offset(0, 0),
            color: borderColor ?? AppColors.backgroundColor,
          ),
        ],
      ),
      child: child,
    );
  }
}
