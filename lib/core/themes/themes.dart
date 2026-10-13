import 'package:flutter/material.dart';
import 'package:taskbite/core/constants/fonts.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/core/themes/styles.dart';

/// Task Bite themes.
///
/// All colors come from [AppColors]; widgets must not hardcode raw colors.
/// Semantic roles (surface, primaryContainer, secondary...) stay consistent
/// between light and dark so shared widgets work in both modes.
class AppThemes {
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scaffoldColor: AppColors.surfaceSoft,
    surfaceColor: AppColors.surfaceLight,
    elevatedColor: AppColors.surfaceLight,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    containerColor: AppColors.primarySoft,
    onContainer: AppColors.primary,
    borderColor: AppColors.borderLight,
    muted: AppColors.mutedLight,
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scaffoldColor: AppColors.surfaceDark,
    surfaceColor: AppColors.surfaceDarkElevated,
    elevatedColor: AppColors.surfaceDarkElevated,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.surfaceDark,
    containerColor: AppColors.surfaceDarkElevated,
    onContainer: AppColors.primaryDark,
    borderColor: AppColors.borderDark,
    muted: AppColors.mutedDark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldColor,
    required Color surfaceColor,
    required Color elevatedColor,
    required Color primary,
    required Color onPrimary,
    required Color containerColor,
    required Color onContainer,
    required Color borderColor,
    required Color muted,
  }) {
    final bool dark = brightness == Brightness.dark;
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: containerColor,
      onSecondary: muted,
      error: AppColors.red,
      onError: AppColors.white,
      surface: surfaceColor,
      onSurface: dark ? AppColors.white : AppColors.black,
      surfaceContainerHighest: scaffoldColor,
      surfaceContainerHigh: elevatedColor,
      surfaceContainer: dark ? AppColors.surfaceDark : AppColors.surfaceSoft,
      surfaceContainerLow: scaffoldColor,
      surfaceContainerLowest: surfaceColor,
      surfaceTint: Colors.transparent,
      outline: borderColor,
      outlineVariant: dark ? AppColors.borderDark : AppColors.borderLight,
      shadow: dark ? AppColors.black : AppColors.borderLight,
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onInverseSurface: dark ? AppColors.white : AppColors.black,
      inversePrimary: onPrimary,
      primaryContainer: containerColor,
      onPrimaryContainer: onContainer,
      secondaryContainer: containerColor,
      onSecondaryContainer: surfaceColor,
      tertiary: borderColor,
      onTertiary: muted,
      tertiaryContainer:
          dark ? AppColors.surfaceDarkElevated : AppColors.primarySoft,
      onTertiaryContainer: muted,
      errorContainer: dark ? AppColors.surfaceDarkElevated : AppColors.red,
      onErrorContainer: AppColors.white,
    );

    final TextTheme textTheme = TextTheme(
      displaySmall: _title(dark).copyWith(fontSize: 32),
      headlineSmall: _title(dark).copyWith(fontSize: 26),
      titleLarge: _title(dark),
      titleMedium: _title(dark).copyWith(fontSize: 19),
      titleSmall: _title(dark).copyWith(fontSize: 16),
      bodyLarge:
          dark ? AppTextStyles.darkBodyLarge : AppTextStyles.lightBodyLarge,
      bodyMedium:
          dark ? AppTextStyles.darkBodyMedium : AppTextStyles.lightBodyMedium,
      bodySmall: (dark
              ? AppTextStyles.darkBodyMedium
              : AppTextStyles.lightBodyMedium)
          .copyWith(fontSize: 13, color: muted),
      labelLarge: (dark
              ? AppTextStyles.darkBodyLarge
              : AppTextStyles.lightBodyLarge)
          .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: _label(
        dark,
      ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: _label(dark).copyWith(fontSize: 11),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: FontAssets.poppins,
      scaffoldBackgroundColor: scaffoldColor,
      colorScheme: colorScheme,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            dark ? AppColors.surfaceDarkElevated : AppColors.surfaceLight,
        hintStyle:
            dark ? AppTextStyles.darkHintStyle : AppTextStyles.lightHintStyle,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: dark ? AppBorders.darkBorder : AppBorders.border,
        enabledBorder: dark ? AppBorders.darkBorder : AppBorders.border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(width: 1.8, color: colorScheme.primary),
        ),
        errorBorder: AppBorders.errorBorder,
        focusedErrorBorder: AppBorders.errorBorder,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.35),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(28),
          ),
        ),
        showDragHandle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: borderColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: containerColor,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium!.copyWith(color: onContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.surfaceDarkElevated : AppColors.grey,
        contentTextStyle:
            dark
                ? AppTextStyles.darkBodyMedium
                : AppTextStyles.lightBodyMedium.copyWith(
                  color: AppColors.white,
                ),
        closeIconColor: AppColors.white,
        showCloseIcon: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side:
              dark ? BorderSide(color: AppColors.borderDark) : BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: containerColor,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static TextStyle _title(bool dark) =>
      dark ? AppTextStyles.darkTitle : AppTextStyles.lightTitle;

  static TextStyle _label(bool dark) =>
      dark ? AppTextStyles.darkLabel : AppTextStyles.lightLabel;
}
