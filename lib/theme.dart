import 'package:flutter/material.dart';

// light theme
// dark theme
// black theme (for OLED screens)
List<ThemeData> themeList = [
  ThemeData(
    platform: TargetPlatform.iOS,
    fontFamily: 'Manrope',
    brightness: Brightness.light,
    primaryColor: Colors.blue[800],
    accentColor: Colors.yellowAccent,
    scaffoldBackgroundColor: Colors.grey[50],
    textTheme: textTheme.merge(lightThemeText),
    toggleableActiveColor: Colors.yellowAccent,
  ),
  ThemeData(
    platform: TargetPlatform.iOS,
    fontFamily: 'Manrope',
    brightness: Brightness.dark,
    primaryColor: Colors.blue[800],
    accentColor: Colors.yellowAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    canvasColor: Colors.grey[850],
    appBarTheme: AppBarTheme(
      color: Colors.blue[800],
    ),
    textTheme: textTheme.merge(darkThemeText),
    toggleableActiveColor: Colors.yellowAccent,
  ),
  ThemeData(
    platform: TargetPlatform.iOS,
    fontFamily: 'Manrope',
    brightness: Brightness.dark,
    primaryColor: Colors.blue[800],
    accentColor: Colors.yellowAccent,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      color: Colors.blue[800],
    ),
    textTheme: textTheme.merge(darkThemeText),
    toggleableActiveColor: Colors.yellowAccent,
  ),
];

TextTheme textTheme = const TextTheme().copyWith(
  body1: const TextStyle(
    height: 0.8,
  ),
  body2: const TextStyle(
    height: 0.8,
  ),
  title: const TextStyle(
    height: 0.8,
  ),
  subtitle: const TextStyle(
    height: 0.8,
  ),
  button: const TextStyle(
    height: 0.8,
  ),
  display1: const TextStyle(
    height: 0.8,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
  ),
  display2: const TextStyle(
    height: 0.8,
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
  ),
  display3: const TextStyle(
    height: 0.8,
    fontSize: 36.0,
    fontWeight: FontWeight.w700,
  ),
  display4: const TextStyle(
    height: 0.8,
    fontSize: 48.0,
    fontWeight: FontWeight.w700,
  ),
);

TextTheme lightThemeText = const TextTheme(
  display2: TextStyle(
    color: Colors.black87,
  ),
  display3: TextStyle(
    color: Colors.black87,
  ),
  display4: TextStyle(
    color: Colors.black87,
  ),
);

TextTheme darkThemeText = const TextTheme(
  display2: TextStyle(
    color: Colors.white,
  ),
  display3: TextStyle(
    color: Colors.white,
  ),
  display4: TextStyle(
    color: Colors.white,
  ),
);
