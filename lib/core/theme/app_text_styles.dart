import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const section = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: AppColors.text,
  );

  static const muted = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: AppColors.muted,
  );
}
