import 'package:flutter/material.dart';
import 'package:taskbite/core/themes/colors.dart';

class AppTextStyles {
  // Light theme body / titles (dark text on light surfaces).

  static const TextStyle lightBodyMedium = TextStyle(
    fontSize: 15,
    color: AppColors.black,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle lightBodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.black,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );
  static const TextStyle lightTitle = TextStyle(
    fontSize: 24,
    color: AppColors.black,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle lightHintStyle = TextStyle(
    color: AppColors.mutedLight,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle lightLabel = TextStyle(
    color: AppColors.mutedLight,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // Dark theme body / titles (light text on dark surfaces).

  static const TextStyle darkBodyMedium = TextStyle(
    fontSize: 15,
    color: AppColors.white,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle darkBodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.white,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );
  static const TextStyle darkTitle = TextStyle(
    fontSize: 24,
    color: AppColors.white,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle darkHintStyle = TextStyle(
    color: AppColors.mutedDark,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle darkLabel = TextStyle(
    color: AppColors.mutedDark,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}

class AppBorders {
  static OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(width: 1.4, color: AppColors.borderLight),
  );
  static OutlineInputBorder errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(width: 1.4, color: AppColors.red),
  );
  static OutlineInputBorder darkBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(width: 1.4, color: AppColors.borderDark),
  );
}
