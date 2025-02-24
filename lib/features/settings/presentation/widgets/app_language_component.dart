import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/constants/enums.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/localization/cubit/localization_cubit.dart';
import 'package:taskbite/features/settings/presentation/widgets/settings_component_title.dart';
import 'package:taskbite/features/tasks/presentation/widgets/shadow_container.dart';

class AppLanguageComponent extends StatelessWidget {
  const AppLanguageComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsComponentTitle(title: 'appLanguage'),
        SizedBox(height: 10.h),
        ValueListenableBuilder(
          valueListenable: HiveHelper.settingsListenable(),
          builder: (context, Box<dynamic> box, _) {
            return ShadowedContainer(
              borderColor: Theme.of(context).colorScheme.tertiary,
              padding: EdgeInsetsDirectional.symmetric(horizontal: 30.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('English'),
                      Spacer(),
                      Radio<String>.adaptive(
                        value: 'en',
                        groupValue: LocalizationCubit.get(context).language,
                        onChanged: (value) {
                          LocalizationCubit.get(
                            context,
                          ).changeLanguageToEnglish(LanguageType.normal);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('العربية'),
                      Spacer(),
                      Radio<String>(
                        value: 'ar',
                        groupValue: LocalizationCubit.get(context).language,
                        onChanged: (value) {
                          LocalizationCubit.get(
                            context,
                          ).changeLanguageToArabic(LanguageType.normal);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
