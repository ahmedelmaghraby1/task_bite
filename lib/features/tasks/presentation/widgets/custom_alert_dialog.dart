import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/widgets/rounded_button.dart';

class CustomAlertDialog extends StatelessWidget {
  final String message;
  final String? yesTitle;
  final String? noTitle;
  final void Function()? onYesFunction;
  final void Function()? onNoFunction;
  const CustomAlertDialog({
    super.key,
    required this.message,
    this.yesTitle,
    this.noTitle,
    this.onYesFunction,
    this.onNoFunction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 15.w),
      iconPadding: EdgeInsetsDirectional.only(
        end: 15.w,
        top: 10.h,
        bottom: 10.h,
      ),
      icon: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.cancel_outlined),
          ),
        ],
      ),
      iconColor: Theme.of(context).colorScheme.primary,
      alignment: AlignmentDirectional.center,
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        RoundedButton(
          width: 90.w,
          height: 28.h,
          title: (yesTitle ?? 'yes').tr(context),
          onTap: onYesFunction,
        ),
        RoundedButton(
          width: 90.w,
          height: 28.h,
          title: (noTitle ?? 'no').tr(context),
          onTap: onNoFunction,
        ),
      ],
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              message.tr(context),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.start,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
