import 'package:flutter/material.dart';

// Color definition
final Color baseBlackColor =
    Color.fromARGB(255, 95, 99, 104); // Google title black

final TextStyle baseTextStyle = TextStyle(color: baseBlackColor);

final TextTheme baseTextTheme = TextTheme(
  bodyText2: baseTextStyle,
  bodyText1: baseTextStyle,
  button: TextStyle(color: baseBlackColor),
  headline6: baseTextStyle.copyWith(fontSize: 28),
);

// Theme
final ThemeData lightTheme = ThemeData(
    backgroundColor: Colors.white,
    primaryColor: Colors.pink,
    textTheme: baseTextTheme,
    brightness: Brightness.light,
    primaryColorBrightness: Brightness.dark,
    iconTheme: IconThemeData(color: baseBlackColor),
    primaryTextTheme: baseTextTheme,
    appBarTheme: AppBarTheme(color: Colors.white, textTheme: baseTextTheme));
