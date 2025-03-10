import 'package:flutter/material.dart';
import 'package:taskbite/core/localization/app_localization.dart';

extension SnackBarExtension on BuildContext {
  void showSnack() {
    ScaffoldMessenger.of(
      this,
    ).showSnackBar(SnackBar(content: Text('noInternetConnection'.tr(this))));
  }
}
