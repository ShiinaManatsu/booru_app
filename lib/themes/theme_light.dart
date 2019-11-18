import 'package:flutter/material.dart';

// Color definition
final Color baseBlackColor=Color.fromARGB(255, 95, 99, 104);  // Google title black
final Color blueTextColor=Colors.lightBlue; // Accent blue color

final TextStyle baseTextStyle=TextStyle(color: baseBlackColor);
final TextTheme baseTextTheme=TextTheme(
    body1: baseTextStyle,
    body2: baseTextStyle,
    button: TextStyle(color: blueTextColor),
    title: baseTextStyle,
  );

// Theme
final ThemeData lightTheme=ThemeData(
  backgroundColor: Colors.white,
  textTheme: baseTextTheme,
  iconTheme: IconThemeData(color: baseBlackColor),
  appBarTheme: AppBarTheme(color: Colors.white,textTheme: baseTextTheme)
);