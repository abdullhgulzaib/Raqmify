import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static const String fontOutfit = 'Outfit';

  static TextTheme _buildTextTheme(Color mainColor, Color mutedColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: mainColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: mainColor,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: mainColor,
      ),
      titleMedium: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      titleSmall: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      // U2: Body at least 14 sp, secondary at least 12 sp
      bodyLarge: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: mainColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      bodySmall: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      labelLarge: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: mainColor,
      ),
      labelMedium: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mutedColor,
      ),
      labelSmall: TextStyle(
        fontFamily: fontOutfit,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mutedColor,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(AppColors.darkInk, AppColors.textMuted);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontOutfit,
      scaffoldBackgroundColor: AppColors.offWhite,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepEmerald,
        primary: AppColors.deepEmerald,
        secondary: AppColors.teal,
        tertiary: AppColors.mutedGold,
        surface: AppColors.cardWhite,
        error: AppColors.errorRed,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkInk),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontOutfit,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepEmerald,
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontOutfit,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: fontOutfit,
          color: AppColors.textMuted,
          fontSize: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.deepEmerald, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: AppColors.deepEmerald,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(Colors.white, const Color(0xFF9EABA7));

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontOutfit,
      scaffoldBackgroundColor: AppColors.darkSurface,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.teal,
        secondary: AppColors.deepEmerald,
        tertiary: AppColors.mutedGold,
        surface: AppColors.darkCard,
        error: AppColors.errorRed,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.darkSurface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontOutfit,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontOutfit,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: fontOutfit,
          color: Color(0xFF6B7280),
          fontSize: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        elevation: 8,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
