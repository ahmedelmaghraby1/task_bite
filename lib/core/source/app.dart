import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/injection/injection.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/localization/cubit/localization_cubit.dart';
import 'package:taskbite/core/routes/router.dart';
import 'package:taskbite/core/themes/themes.dart';
import 'package:taskbite/features/settings/cubits/settings_cubit.dart';

class TaskBite extends StatelessWidget {
  const TaskBite({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocalizationCubit>(
          create: (context) => getIt<LocalizationCubit>(),
        ),
        BlocProvider<SettingsCubit>(
          create: (context) => getIt<SettingsCubit>(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return BlocBuilder<LocalizationCubit, LocalizationState>(
            builder: (context, state) {
              return ScreenUtilInit(
                designSize: Size(393, 852),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Task bite',
                  localizationsDelegates: const [
                    AppLocalizationDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  locale: state.locale,
                  supportedLocales: AppLocalization.supportedLocales,
                  theme: AppThemes.lightTheme,
                  darkTheme: AppThemes.darkTheme,
                  themeMode:
                      SettingsCubit.get(context).darkMode
                          ? ThemeMode.dark
                          : ThemeMode.light,
                  onGenerateRoute: AppRouter.onGenerateRoute,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
