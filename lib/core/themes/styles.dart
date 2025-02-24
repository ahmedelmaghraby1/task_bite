import 'package:flutter/material.dart';
import 'package:taskbite/core/themes/colors.dart';

class AppTextStyles {
  // Light theme

  // Body

  static const TextStyle lightBodyMedium = TextStyle(
    fontSize: 16,
    color: AppColors.black,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle lightBodyLarge = TextStyle(
    fontSize: 18,
    color: AppColors.black,
    fontWeight: FontWeight.w500,
  );
  // Title
  static const TextStyle lightTitle = TextStyle(
    fontSize: 24,
    color: AppColors.black,
    fontWeight: FontWeight.w700,
  );
  // Hint
  static const TextStyle lightHintStyle = TextStyle(
    color: AppColors.grey,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // Dark theme

  static const TextStyle darkBodyMedium = TextStyle(
    fontSize: 16,
    color: AppColors.white,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle darkBodyLarge = TextStyle(
    fontSize: 18,
    color: AppColors.white,
    fontWeight: FontWeight.w500,
  );
  // Title
  static const TextStyle darkTitle = TextStyle(
    fontSize: 24,
    color: AppColors.white,
    fontWeight: FontWeight.w700,
  );
  // Hint
  static const TextStyle darkHintStyle = TextStyle(
    color: AppColors.backgroundColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}

class AppBorders {
  static OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(50),
    borderSide: const BorderSide(width: 2, color: AppColors.grey),
  );
  static OutlineInputBorder errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(50),
    borderSide: BorderSide(width: 1.5, color: AppColors.red),
  );
}
