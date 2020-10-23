import 'package:flutter/material.dart';

// Color definition
final Color baseBlackColor =
    Color.fromARGB(255, 95, 99, 104); // Google title black

final TextStyle baseTextStyle = TextStyle(color: baseBlackColor);

final double _masonryGridBorderRadius = 12;

final TextTheme baseTextTheme = TextTheme(
    bodyText2: baseTextStyle,
    bodyText1: baseTextStyle,
    button: TextStyle(color: baseBlackColor),
    headline5: baseTextStyle.copyWith(fontSize: 24),
    headline6:
        baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
    subtitle2: baseTextStyle // Subtitle
    );

// Theme
final ThemeData lightTheme = ThemeData(
  backgroundColor: Colors.white,
  primaryColor: Colors.pink,
  accentColor: Colors.pink,
  textTheme: baseTextTheme,
  brightness: Brightness.light,
  primaryColorBrightness: Brightness.dark,
  iconTheme: IconThemeData(color: baseBlackColor),
  primaryTextTheme: baseTextTheme,
  appBarTheme: AppBarTheme(color: Colors.white, textTheme: baseTextTheme),
  cardTheme: CardTheme(
    clipBehavior: Clip.antiAliasWithSaveLayer,
    elevation: 4,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_masonryGridBorderRadius)),
  ),
);
