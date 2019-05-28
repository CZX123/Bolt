import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  ThemeState();

  int _themeCode = 0;

  Brightness _inverseBrightness(Brightness brightness) {
    return brightness == Brightness.light ? Brightness.dark : Brightness.light;
  }

  void setThemeCode(int newCode) {
    // make navigation bar same collor as bottom sheet color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: themeList[newCode].canvasColor,
        systemNavigationBarIconBrightness: _inverseBrightness(themeList[newCode].brightness),
      ),
    );
    // Save the new theme code to device storage
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('themeCode', newCode);
    });
    _themeCode = newCode;
    notifyListeners();
  }

  int get themeCode => _themeCode;
}

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
