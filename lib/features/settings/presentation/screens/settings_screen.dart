import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/home/presentation/widgets/head_title.dart';
import 'package:taskbite/features/settings/presentation/widgets/app_language_component.dart';
import 'package:taskbite/features/settings/presentation/widgets/dark_mode_component.dart';
import 'package:taskbite/features/settings/presentation/widgets/settings_app_bar.dart';
import 'package:taskbite/features/settings/presentation/widgets/sound_recognetion_language_component.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
        child: Column(
          children: [
            SettingsAppBar(),
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
