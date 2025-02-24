import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/tasks/presentation/widgets/custom_alert_dialog.dart';

showAlertDialog(
  BuildContext context, {
  required String message,
  String? yesTitle,
  String? noTitle,
  void Function()? onYesFunction,
  void Function()? onNoFunction,
}) {
  showDialog(
    context: context,
    builder: (BuildContext alertDialogcontext) {
      return CustomAlertDialog(
        message: message.tr(context),
        yesTitle: (yesTitle ?? 'yes').tr(context),
        noTitle: (noTitle ?? 'no').tr(context),
        onNoFunction:
            onNoFunction ??
            () {
              Navigator.pop(context);
            },
        onYesFunction: onYesFunction,
      );
    },
  );
}
