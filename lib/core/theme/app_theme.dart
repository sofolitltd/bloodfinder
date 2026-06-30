import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.light,
  ).copyWith(surface: Colors.white),
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  fontFamily: GoogleFonts.anekBangla().fontFamily,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    titleTextStyle: GoogleFonts.anekBangla(
      fontWeight: FontWeight.w600,
      fontSize: 18.sp,
      color: Colors.black,
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
  elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.r)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red.shade700,
      minimumSize: const Size(double.infinity, 40),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.anekBangla(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 64.h,
  
    indicatorColor: Colors.red.shade50,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: Colors.red);
      }
      return const IconThemeData(color: Colors.grey);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TextStyle(color: Colors.red, fontSize: 12.sp);
      }
      return TextStyle(color: Colors.grey, fontSize: 12.sp);
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    contentPadding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.r)),
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Colors.white,
    headerBackgroundColor: Colors.red.shade700,
    headerForegroundColor: Colors.white,
  ),
);

final Color _bluishDarkBg = const Color(0xFF1A1C30);
final Color _bluishDarkSurface = const Color(0xFF2E3058);
final Color _bluishDarkCard = const Color(0xFF3A3E6E);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.red,
    brightness: Brightness.dark,
  ).copyWith(
    surface: _bluishDarkSurface,
    surfaceContainerHighest: _bluishDarkCard,
  ),
  scaffoldBackgroundColor: _bluishDarkBg,
  fontFamily: GoogleFonts.anekBangla().fontFamily,
  appBarTheme: AppBarTheme(
    backgroundColor: _bluishDarkSurface,
    surfaceTintColor: _bluishDarkSurface,
    titleTextStyle: GoogleFonts.anekBangla(
      fontWeight: FontWeight.w600,
      fontSize: 18.sp,
      color: Colors.white,
    ),
  ),
  cardTheme: CardThemeData(
    color: _bluishDarkCard,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.r)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red[700],
      minimumSize: const Size(double.infinity, 40),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.anekBangla(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _bluishDarkSurface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 64.h,
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.r),
    ),
    indicatorColor: Colors.red.shade900,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: Colors.red);
      }
      return const IconThemeData(color: Colors.grey);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TextStyle(color: Colors.red, fontSize: 12.sp);
      }
      return TextStyle(color: Colors.grey, fontSize: 12.sp);
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    contentPadding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _bluishDarkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.r)),
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: _bluishDarkSurface,
    headerBackgroundColor: _bluishDarkCard,
    headerForegroundColor: Colors.white,
  ),
);
