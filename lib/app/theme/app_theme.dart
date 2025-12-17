import 'package:flutter/material.dart';
import 'colors.dart';

ThemeData lightTheme = ThemeData(
primaryColor: primaryColor,
scaffoldBackgroundColor: backgroundColor,
cardColor: cardColor,
appBarTheme: AppBarTheme(
backgroundColor: primaryColor,
elevation: 0,
titleTextStyle: TextStyle(
color: Colors.white,
fontSize: 20,
fontWeight: FontWeight.bold,
),
iconTheme: IconThemeData(color: Colors.white),
),
elevatedButtonTheme: ElevatedButtonThemeData(
style: ElevatedButton.styleFrom(
backgroundColor: primaryColor,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(10),
),
),
),
textTheme: TextTheme(
displayLarge: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
displayMedium: TextStyle(color: textSecondary, fontSize: 16),
displaySmall: TextStyle(color: textHint, fontSize: 14),
),
inputDecorationTheme: InputDecorationTheme(
filled: true,
fillColor: Colors.white,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
borderSide: BorderSide.none,
),
hintStyle: TextStyle(color: textHint),
),
);
