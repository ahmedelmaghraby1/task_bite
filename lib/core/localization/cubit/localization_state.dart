part of 'localization_cubit.dart';

abstract class LocalizationState {
  final Locale locale;
  LocalizationState(this.locale);
}

class LocalizationInit extends LocalizationState {
  LocalizationInit() : super(AppLocalization.supportedLocales.first);
}

class LocalizationChange extends LocalizationState {
  LocalizationChange(super.locale);
}
