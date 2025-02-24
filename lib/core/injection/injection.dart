import 'package:get_it/get_it.dart';
import 'package:taskbite/core/localization/cubit/localization_cubit.dart';
import 'package:taskbite/features/settings/cubits/settings_cubit.dart';

GetIt getIt = GetIt.instance;

initGetIt() {
  // Cubits
  getIt.registerFactory<LocalizationCubit>(() => LocalizationCubit());
  getIt.registerFactory<SettingsCubit>(() => SettingsCubit());
}
