import 'library.dart';

class ThemeModel with ChangeNotifier {

  bool _isDark = false;
  set isDark(bool value) {
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
    accentColor: Color(0xFFFFC800),
    // scaffoldBackgroundColor: Color(0xFF000A14),
    scaffoldBackgroundColor: Color(0xFF1a2330),
    canvasColor: Color(0xFF020F1C),
    cardColor: Color(0xFF031230),
    appBarTheme: AppBarTheme(
      color: Color(0xFF0A1826),
    ),
    textTheme: textTheme.merge(darkThemeText),
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
];

TextTheme textTheme = const TextTheme(
  body1: const TextStyle(
    height: 1.2,
    fontSize: 14,
  ),
  body2: const TextStyle(
    height: 1.2,
    fontSize: 14,
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
    fontSize: 14,
    fontWeight: FontWeight.w700,
  ),
  display2: const TextStyle(
    height: 1.2,
    fontSize: 18,
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
