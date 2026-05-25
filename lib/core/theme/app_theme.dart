import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: const ColorScheme.light(
          primary: AppColors.navyDeep,
          onPrimary: AppColors.cream,
          secondary: AppColors.gold,
          onSecondary: AppColors.navyDeep,
          tertiary: AppColors.ballRed,
          surface: Colors.white,
          onSurface: AppColors.ink,
          error: AppColors.danger,
          onError: Colors.white,
          surfaceContainerHighest: AppColors.creamSoft,
          outline: AppColors.line,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.navyDeep,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppTextStyles.headlineMedium,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: const IconThemeData(color: AppColors.navyDeep),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ballRed,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.button,
            minimumSize: const Size(0, 52),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navyDeep,
            side: const BorderSide(color: AppColors.line, width: 1.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.labelLarge,
            backgroundColor: Colors.white,
            minimumSize: const Size(0, 48),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.goldDeep,
            textStyle: AppTextStyles.labelLarge.copyWith(letterSpacing: 0.18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: AppTextStyles.fraunces(
            size: 13,
            weight: FontWeight.w400,
            italic: true,
            color: AppColors.grey,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.creamSoft,
          labelStyle: AppTextStyles.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: AppColors.line),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.goldDeep,
          unselectedItemColor: AppColors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showUnselectedLabels: true,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.line,
          thickness: 1,
          space: 1,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.navyDeep,
          unselectedLabelColor: AppColors.grey,
          indicatorColor: AppColors.gold,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelLarge,
        ),
        textTheme: TextTheme(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayMedium,
          headlineLarge: AppTextStyles.headlineLarge,
          headlineMedium: AppTextStyles.headlineMedium,
          titleLarge: AppTextStyles.titleLarge,
          titleMedium: AppTextStyles.titleMedium,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelSmall: AppTextStyles.caption,
        ),
      );
}
