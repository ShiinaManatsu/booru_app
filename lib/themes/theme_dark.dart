import 'package:flutter/material.dart';

// Color definition
final Color baseWhiteColor = Colors.grey[200]; // Google title black

final TextStyle baseTextStyle = TextStyle(color: baseWhiteColor);

final TextTheme baseTextTheme = TextTheme(
    bodyText2: baseTextStyle,
    bodyText1: baseTextStyle,
    button: TextStyle(color: baseWhiteColor),
    headline6: baseTextStyle.copyWith(fontSize: 28), // Title
    subtitle2: baseTextStyle // Subtitle
    );

// Theme
final ThemeData darkTheme = ThemeData.dark().copyWith(
    backgroundColor: Colors.grey[900],
    primaryColorLight: Colors.white,
    primaryColorBrightness: Brightness.light,
    brightness: Brightness.dark,
    primaryColor: Colors.pink,
    
    // textTheme: baseTextTheme,
    iconTheme: IconThemeData(color: baseWhiteColor),
    // primaryTextTheme: baseTextTheme,
    appBarTheme: AppBarTheme(color: Colors.white, textTheme: baseTextTheme));
