import 'library.dart';

class ThemeModel with ChangeNotifier {

  bool _isDark = false;
  set isDark(bool value) {
    if (_isDark == value) return;
    _isDark = value;
    _currentThemeData = themeList[value ? 1 : 0];
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDark', value);
    });
    notifyListeners();
  }
  bool get isDark => _isDark;

  ThemeData _currentThemeData = themeList[0];
  ThemeData get currentThemeData => _currentThemeData;
}

// light theme
// dark theme
final List<ThemeData> themeList = [
  ThemeData(
    platform: TargetPlatform.iOS,
    fontFamily: 'Manrope',
    brightness: Brightness.light,
    primaryColor: Color(0xFFFFC800),
    primaryColorLight: Color(0xFFFEFDE8), // Ignore this light dark thing, they're the same
    primaryColorDark: Color(0xFFFEFDE8),
    accentColor: Color(0xFF54D2D2),
    // scaffoldBackgroundColor: Color(0xFFFFFCED),
    scaffoldBackgroundColor: Colors.grey[50],
    canvasColor: Color(0xFFEDF3F5),
    cardColor: Color(0xFFE1E8EB),
    textTheme: textTheme.merge(lightThemeText),
    toggleableActiveColor: Color(0xFFFFC800),
    buttonTheme: ButtonThemeData(
      minWidth: 64,
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      )
    ),
  ),
  ThemeData(
    platform: TargetPlatform.iOS,
    fontFamily: 'Manrope',
    brightness: Brightness.dark,
    primaryColor: Color(0xFF54D2D2),
    primaryColorLight: Color(0xFF081F44),
    primaryColorDark: Color(0xFF081F44),
    accentColor: Color(0xFF69593d),
    // scaffoldBackgroundColor: Color(0xFF000A14),
    scaffoldBackgroundColor: Color(0xFF0e131a),
    canvasColor: Color(0xFF1a2330),
    cardColor: Color(0xFF222d3d),
    textTheme: textTheme.merge(darkThemeText),
    toggleableActiveColor: Color(0xFF69593d),
    buttonTheme: ButtonThemeData(
      minWidth: 64,
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      )
    ),
  ),
];

TextTheme textTheme = const TextTheme(
  body1: const TextStyle(
    height: 1.2,
    fontSize: 14,
  ),
  body2: const TextStyle(
    height: 1.2,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  ),
  subhead: const TextStyle(
    height: 1.3,
  ),
  title: const TextStyle(
    height: 1.2,
  ),
  subtitle: const TextStyle(
    height: 1.2,
    fontSize: 13,
  ),
  button: const TextStyle(
    height: 1.2,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  ),
  display1: const TextStyle(
    height: 1.2,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  ),
  display2: const TextStyle(
    height: 1.2,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  ),
  display3: const TextStyle(
    height: 1.2,
    fontSize: 32,
    fontWeight: FontWeight.w700,
  ),
  display4: const TextStyle(
    height: 1.2,
    fontSize: 48,
    fontWeight: FontWeight.w700,
  ),
);

const TextTheme lightThemeText = TextTheme(
  display1: TextStyle(
    color: Colors.black87,
  ),
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
  display1: TextStyle(
    color: Colors.white,
  ),
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
