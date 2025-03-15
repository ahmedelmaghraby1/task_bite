import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/constants/enums.dart';
import 'package:taskbite/core/helpers/validations.dart';
import 'package:taskbite/core/localization/app_localization.dart';

class AddTaskTextField extends StatelessWidget {
  final FieldType type;
  final Widget? trailling;
  final int? maxLength;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(PointerDownEvent)? onTapOutside;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final String text;
  final TextEditingController textEditingController;
  const AddTaskTextField({
    super.key,
    required this.textEditingController,
    required this.text,
    required this.type,
    this.onChanged,
    this.trailling,
    this.maxLength,
    this.focusNode,
    this.textInputAction,
    this.onTapOutside,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
      child: TextFormField(
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        onTapOutside: onTapOutside,
        maxLength: maxLength,
        maxLines: 7,
        minLines: 1,
        validator:
            type == FieldType.content
                ? null
                : (value) =>
                    AppValidations.validator(value, 'emptyField')?.tr(context),
        onChanged: onChanged,
        controller: textEditingController,

        decoration: InputDecoration(
          suffixIcon: Padding(
            padding: EdgeInsetsDirectional.only(end: 20.w),
            child: trailling ?? SizedBox(),
          ),
          contentPadding: EdgeInsetsDirectional.symmetric(
            horizontal: 30.w,
            vertical: 20.h,
          ),
          hintText: text.tr(context),
        ),
      ),
    );
  }
}
