import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeNotifier();

  bool _isDarkMode = false;
  set isDarkMode(bool value) {
    _isDarkMode = value;
    _currentThemeData = themeList[value ? 1 : 0];
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkMode', value);
    });
    notifyListeners();
  }
  bool get isDarkMode => _isDarkMode;

  ThemeData _currentThemeData = themeList[0];
  ThemeData get currentThemeData => _currentThemeData;
}

// light theme
// dark theme
List<ThemeData> themeList = [
  ThemeData(
    platform: TargetPlatform.iOS,
    fontFamily: 'Manrope',
    brightness: Brightness.light,
    primaryColor: Color(0xFFFFC800),
    accentColor: Color(0xFF2176FF),
    scaffoldBackgroundColor: Color(0xFFFCFAF4),
    canvasColor: Color(0xFFF9F6EA),
    textTheme: textTheme.merge(lightThemeText),
    toggleableActiveColor: Color(0xFF2176FF),
  ),
  ThemeData(
    platform: TargetPlatform.iOS,
    fontFamily: 'Manrope',
    brightness: Brightness.dark,
    primaryColor: Color(0xFF2176FF),
    accentColor: Color(0xFFFFC800),
    scaffoldBackgroundColor: Color(0xFF000A14),
    canvasColor: Color(0xFF020F1C),
    appBarTheme: AppBarTheme(
      color: Color(0xFF0A1826),
    ),
    textTheme: textTheme.merge(darkThemeText),
    toggleableActiveColor: Color(0xFFFFC800),
  ),
];

TextTheme textTheme = const TextTheme(
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
    fontSize: 12.0,
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

const TextTheme lightThemeText = TextTheme(
  display2: TextStyle(
    color: Colors.black87,
  ),
  display3: TextStyle(
    color: Colors.black87,
  ),
  display4: TextStyle(
    color: Colors.black87,
  ),
  subtitle: TextStyle(
    color: Colors.black54,
  ),
);

const TextTheme darkThemeText = TextTheme(
  display2: TextStyle(
    color: Colors.white,
  ),
  display3: TextStyle(
    color: Colors.white,
  ),
  display4: TextStyle(
    color: Colors.white,
  ),
  subtitle: TextStyle(
    color: Colors.white70,
  ),
);
