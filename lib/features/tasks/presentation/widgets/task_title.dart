import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TaskTitle extends StatelessWidget {
  final String title;
  const TaskTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145.w,
      height: 34.h,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary,
        borderRadius: BorderRadius.circular(10.r),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
      ),
    );
  }
}
