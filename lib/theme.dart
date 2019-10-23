import 'library.dart';

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
    canvasColor: Color(0xFFFFFBE6),
    // cardColor: Color(0xFFFFF9DB),
    cardColor: Color(0xFFE9EEF0),
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
    fontSize: 15,
  ),
  body2: const TextStyle(
    height: 1.2,
    fontSize: 15,
  ),
  title: const TextStyle(
    height: 1.2,
  ),
  subtitle: const TextStyle(
    height: 1.2,
    fontSize: 13.5,
  ),
  button: const TextStyle(
    height: 1.2,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  ),
  display1: const TextStyle(
    height: 1.2,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  ),
  display2: const TextStyle(
    height: 1.2,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  ),
  display3: const TextStyle(
    height: 1.2,
    fontSize: 36,
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
