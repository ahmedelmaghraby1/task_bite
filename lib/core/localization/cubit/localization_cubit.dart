import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:taskbite/core/constants/enums.dart';
import 'package:taskbite/core/localization/app_localization.dart';
part 'localization_state.dart';

class LocalizationCubit extends Cubit<LocalizationState> {
  late String _language;
  late String _recordingLanguage;
  LocalizationCubit() : super(LocalizationInit()) {
    // (language, _recordingLanguage) = _getLanguage();
    _language = _getLanguage().$1;
    _recordingLanguage = _getLanguage().$2;
    emit(LocalizationChange(Locale(_language)));
  }
  get language => _language;
  get recordingLanguage => _recordingLanguage;

  static LocalizationCubit get(context) =>
      BlocProvider.of<LocalizationCubit>(context);
  void changeLanguage(String locale, LanguageType type) {
    if (locale == _language) {
    } else {
      _language = locale;
      switch (locale) {
        case 'ar':
          changeLanguageToArabic(type);
        case 'en':
          changeLanguageToEnglish(type);
        default:
      }
    }
  }

  void changeLanguageToArabic(LanguageType type) {
    if (type == LanguageType.normal) _language = 'ar';
    if (type == LanguageType.record) _recordingLanguage = 'ar';
    _changeLanguage(
      type == LanguageType.normal ? _language : _recordingLanguage,
      type,
    );
    if (type == LanguageType.normal) {
      emit(LocalizationChange(AppLocalization.supportedLocales.first));
    }
  }

  void changeLanguageToEnglish(LanguageType type) {
    if (type == LanguageType.normal) _language = 'en';
    if (type == LanguageType.record) _recordingLanguage = 'en';
    _changeLanguage(
      type == LanguageType.normal ? _language : _recordingLanguage,
      type,
    );
    if (type == LanguageType.normal) {
      emit(LocalizationChange(AppLocalization.supportedLocales.last));
    }
  }

  (String, String) _getLanguage() {
    Box<dynamic> settingsBox = Hive.box('settings');
    String locale = settingsBox.get('locale', defaultValue: 'en');
    String recordLocale = settingsBox.get('recordLocale', defaultValue: locale);
    return (locale, recordLocale);
  }

  void _changeLanguage(String locale, LanguageType type) {
    Box<dynamic> settingsBox = Hive.box('settings');
    if (type == LanguageType.normal) settingsBox.put('locale', locale);
    if (type == LanguageType.record) settingsBox.put('recordLocale', locale);
  }
}
