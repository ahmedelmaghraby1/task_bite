import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskbite/core/helpers/hive_helper.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/features/settings/cubits/settings_cubit.dart';
import 'package:taskbite/features/settings/presentation/widgets/settings_component_title.dart';
import 'package:taskbite/features/tasks/presentation/widgets/shadow_container.dart';

class DarkModeComponent extends StatelessWidget {
  const DarkModeComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsComponentTitle(title: 'theme'),
        SizedBox(height: 10.h),
        ValueListenableBuilder(
          valueListenable: HiveHelper.settingsListenable(),
          builder: (context, Box<dynamic> box, _) {
            return ShadowedContainer(
              padding: EdgeInsets.zero,
              borderColor: Theme.of(context).colorScheme.tertiary,
              child: SwitchListTile.adaptive(
                title: Text(
                  'darkMode'.tr(context),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                value: SettingsCubit.get(context).darkMode,
                onChanged: (value) {
                  SettingsCubit.get(context).setDarkMode(value);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
