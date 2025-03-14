import 'package:flutter/material.dart';
import 'package:taskbite/core/constants/fonts.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/core/themes/styles.dart';

class AppThemes {
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    dialogTheme: DialogTheme(backgroundColor: AppColors.white),
    appBarTheme: AppBarTheme(),
    fontFamily: FontAssets.poppins,
    iconTheme: const IconThemeData(color: AppColors.purpple, size: 30),
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white, // Light grey for Scaffold
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.white,
      modalBackgroundColor: AppColors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: AppTextStyles.lightTitle,
      bodyLarge: AppTextStyles.lightBodyLarge, // Default Text color black
      bodyMedium: AppTextStyles.lightBodyMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: AppTextStyles.lightHintStyle,
      border: AppBorders.border,
      errorBorder: AppBorders.errorBorder,
      focusedErrorBorder: AppBorders.errorBorder,
      enabledBorder: AppBorders.border,
      focusedBorder: AppBorders.border,
      disabledBorder: AppBorders.border,
      filled: false,
    ),
    colorScheme: const ColorScheme.light(
      error: AppColors.red,
      inversePrimary: AppColors.white,
      primary: AppColors.purpple,
      secondary: AppColors.transparent,
      tertiary: AppColors.backgroundColor,
      surface: AppColors.transparent,
      onPrimaryContainer: AppColors.backgroundColor,
      onSecondaryContainer: AppColors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.grey,
      contentTextStyle: AppTextStyles.lightBodyLarge.copyWith(
        color: AppColors.white,
      ),
      closeIconColor: AppColors.white,
      showCloseIcon: true,
      shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    dialogTheme: DialogTheme(backgroundColor: AppColors.grey),

    fontFamily: FontAssets.poppins,
    iconTheme: const IconThemeData(color: AppColors.white, size: 30),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffoldBlack,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.scaffoldBlack,
      modalBackgroundColor: AppColors.scaffoldBlack,
      modalBarrierColor: AppColors.grey.withOpacity(0.4),
    ), // Darker grey for Scaffold
    textTheme: const TextTheme(
      titleLarge: AppTextStyles.darkTitle,
      bodyLarge: AppTextStyles.darkBodyLarge, // Default Text color black
      bodyMedium: AppTextStyles.darkBodyMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: AppTextStyles.darkHintStyle,
      border: AppBorders.border,
      errorBorder: AppBorders.errorBorder,
      focusedErrorBorder: AppBorders.errorBorder,
      enabledBorder: AppBorders.border,
      focusedBorder: AppBorders.border,
      disabledBorder: AppBorders.border,
      filled: true,
      fillColor: AppColors.grey,
    ),
    colorScheme: const ColorScheme.dark(
      error: AppColors.red,
      inversePrimary: AppColors.scaffoldBlack,
      primary: AppColors.white,
      secondary: AppColors.grey,
      tertiary: AppColors.transparent,
      surface: AppColors.transparent,
      onPrimaryContainer: AppColors.grey,
      onSecondaryContainer: AppColors.grey,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.grey,
      contentTextStyle: AppTextStyles.lightBodyLarge.copyWith(
        color: AppColors.white,
      ),
      closeIconColor: AppColors.white,
      showCloseIcon: true,
      shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}
