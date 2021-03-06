import 'package:flutter/material.dart';

// Color definition
final Color baseWhiteColor = Colors.grey[200]; // Google title black

final TextStyle baseTextStyle = TextStyle(color: baseWhiteColor);

final double _masonryGridBorderRadius = 12;

final TextTheme baseTextTheme = TextTheme(
    bodyText2: baseTextStyle,
    bodyText1: baseTextStyle,
    button: TextStyle(color: baseWhiteColor),
    headline5: baseTextStyle.copyWith(fontSize: 24),
    headline6:
        baseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
    subtitle2: baseTextStyle // Subtitle
    );

// Theme
final ThemeData darkTheme = ThemeData.dark().copyWith(
  backgroundColor: Colors.grey[900],
  primaryColorLight: Colors.white,
  primaryColorBrightness: Brightness.light,
  brightness: Brightness.dark,
  primaryColor: Colors.pink,
  accentColor: Colors.pink,
  textTheme: baseTextTheme,
  iconTheme: IconThemeData(color: baseWhiteColor),
  primaryTextTheme: baseTextTheme,
  appBarTheme: AppBarTheme(color: Colors.grey[900], textTheme: baseTextTheme),
  cardTheme: CardTheme(
    clipBehavior: Clip.antiAliasWithSaveLayer,
    elevation: 4,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_masonryGridBorderRadius)),
  ),
);
