import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/home/presentation/widgets/head_title.dart';
import 'package:taskbite/features/settings/presentation/widgets/app_language_component.dart';
import 'package:taskbite/features/settings/presentation/widgets/dark_mode_component.dart';
import 'package:taskbite/features/settings/presentation/widgets/sound_recognetion_language_component.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios_new, size: 30),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: 10.h),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 15.w),
                    child: HeadTitle(title: 'settings'.tr(context)),
                  ),
                  SizedBox(height: 20.h),
                  DarkModeComponent(),
                  SizedBox(height: 20.h),
                  AppLanguageComponent(),
                  SizedBox(height: 20.h),

                  SoundRecognetionLanguageComponent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
