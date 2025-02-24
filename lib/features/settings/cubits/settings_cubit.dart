import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  late bool _darkMode;
  SettingsCubit() : super(SettingsStateInitial()) {
    _darkMode = _checkTheme();
  }
  bool get darkMode => _darkMode;
  static SettingsCubit get(BuildContext context) =>
      BlocProvider.of<SettingsCubit>(context);
  bool _checkTheme() {
    Box<dynamic> settingsBox = Hive.box('settings');
    bool theme = settingsBox.get('darkMode', defaultValue: false);
    return theme;
  }

  void setDarkMode(bool theme) {
    _darkMode = theme;
    Box<dynamic> settingsBox = Hive.box('settings');
    settingsBox.put('darkMode', _darkMode);
    emit(ChangeThemeState());
  }
}
