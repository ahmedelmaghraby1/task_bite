import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';

class RoundedButton extends StatelessWidget {
  final String title;
  final double? height;
  final double? width;
  final void Function()? onTap;
  const RoundedButton({
    super.key,
    this.height,
    this.width,
    this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.r),
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          border: Border.all(
            width: 1.r,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Center(
          child: Text(
            title.tr(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
