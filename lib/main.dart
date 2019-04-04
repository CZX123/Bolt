import 'package:flutter/material.dart';

void main() => runApp(AppTheme());

class AppThemeInherited extends InheritedWidget {
  final AppThemeState data;
  AppThemeInherited({this.data, Widget child}) : super(child: child);

  @override
  bool updateShouldNotify(AppThemeInherited old) => data != old.data;
}

class AppTheme extends StatefulWidget {
  @override
  AppThemeState createState() => AppThemeState();

  static AppThemeState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(AppThemeInherited)
            as AppThemeInherited)
        .data;
  }
}

class AppThemeState extends State<AppTheme> {
  int _themeCode = 0;
  int get themeCode => _themeCode;
  // 0 for light theme
  // 1 for dark theme
  // 2 for black theme
  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.indigo,
    accentColor: Colors.yellowAccent,
    scaffoldBackgroundColor: Colors.grey[50],
  );
  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    accentColor: Colors.orangeAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      color: Colors.deepPurple,
    ),
  );
  final ThemeData _blackTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    accentColor: Colors.redAccent,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
      color: Colors.teal,
    ),
  );

  void changeTheme(int code) {
    setState(() {
      _themeCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeInherited(
      data: this,
      child: MaterialApp(
        title: 'Bolt',
        theme: _themeCode == 0
            ? _lightTheme
            : _themeCode == 1 ? _darkTheme : _blackTheme,
        home: Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void changeTheme(int newThemeCode) {
    AppTheme.of(context).changeTheme(newThemeCode);
  }

  @override
  Widget build(BuildContext context) {
    int themeCode = AppTheme.of(context).themeCode;
    String currentTheme =
        themeCode == 0 ? 'light' : themeCode == 1 ? 'dark' : 'black';
    return Scaffold(
      appBar: AppBar(
        title: Text('Bolt'),
      ),
      body: Center(
        child: Text('This is the $currentTheme theme!'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            RadioListTile<int>(
              title: Text('Light Theme'),
              value: 0,
              groupValue: themeCode,
              onChanged: changeTheme,
            ),
            RadioListTile<int>(
              title: Text('Dark Theme'),
              value: 1,
              groupValue: themeCode,
              onChanged: changeTheme,
            ),
            RadioListTile<int>(
              title: Text('Black Theme'),
              value: 2,
              groupValue: themeCode,
              onChanged: changeTheme,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Does Nothing',
        onPressed: () {},
      ),
    );
  }
}
