import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';

class SearchBox extends StatelessWidget {
  final void Function(String)? onChanged;
  final String? hintText;
  final TextEditingController textEditingController;
  const SearchBox({
    super.key,
    required this.textEditingController,
    this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      width: 346.w,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(25.r),
          bottomEnd: Radius.circular(25.r),
        ),
      ),
      padding: EdgeInsetsDirectional.only(start: 5.w),
      child: TextFormField(
        onChanged: onChanged,
        controller: textEditingController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: (hintText ?? 'search').tr(context),
          border: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }
}
