import 'package:flutter/material.dart';
import 'settings.dart';

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
    fontFamily: 'Orkney',
    brightness: Brightness.light,
    primarySwatch: Colors.indigo,
    accentColor: Colors.yellowAccent,
    scaffoldBackgroundColor: Colors.grey[50],
  );
  final ThemeData _darkTheme = ThemeData(
    fontFamily: 'Orkney',
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    accentColor: Colors.orangeAccent,
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      color: Colors.deepPurple,
    ),
  );
  final ThemeData _blackTheme = ThemeData(
    fontFamily: 'Orkney',
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
  double top = 0;

  void changeTheme(int newThemeCode) {
    AppTheme.of(context).changeTheme(newThemeCode);
  }

  @override
  Widget build(BuildContext context) {
    int _themeCode = AppTheme.of(context).themeCode;
    String currentTheme =
        _themeCode == 0 ? 'light' : _themeCode == 1 ? 'dark' : 'black';
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 128.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Bolt',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(72.0, 24.0, 72.0, 8.0),
                  child: Text(
                    'This is the $currentTheme theme!',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 8.0),
                  child: const Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed quis mauris vel quam tempor luctus ac id est. Phasellus nibh metus, iaculis id elit vitae, efficitur pretium elit. In quis porttitor mauris, ac commodo eros. Suspendisse elit sapien, iaculis quis fermentum vitae, luctus eget diam. Suspendisse pretium ex vitae libero facilisis lacinia. Cras dictum purus at sapien consectetur consectetur. Aenean diam lectus, dapibus blandit erat vel, lobortis tempor leo.',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 8.0),
                  child: const Text(
                    'Aenean finibus ex lectus, eget luctus erat tincidunt et. Etiam at sollicitudin est. Mauris sagittis viverra ullamcorper. Fusce porta posuere odio. Vivamus ac semper mi. Quisque porttitor velit id auctor tincidunt. Sed sagittis nunc vel lorem viverra, vel tincidunt ipsum finibus. Cras fermentum fermentum iaculis. Donec eget interdum sapien. Sed a neque auctor, varius quam ut, tempus nibh. Nunc in arcu eros. Suspendisse potenti. Aenean consequat, erat id vehicula varius, quam lectus vehicula orci, sed lacinia diam dolor varius elit. In id enim ut diam porttitor lacinia. Proin et ultricies elit, ac faucibus urna. Pellentesque cursus ullamcorper velit, vitae dapibus sem venenatis vel.',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 8.0),
                  child: const Text(
                    'Suspendisse venenatis ligula et lectus suscipit, sit amet tempus sem fermentum. Fusce efficitur dictum ornare. Morbi nisl ipsum, hendrerit tincidunt efficitur eget, congue a nisi. Nullam scelerisque iaculis tellus non commodo. In id turpis orci. Etiam non maximus ex, in accumsan tortor. Fusce eget tempor felis, id elementum orci. Vivamus pretium dapibus eros, efficitur iaculis nibh lobortis nec. Maecenas mattis nec tellus sit amet efficitur. Proin eu dapibus nulla, mattis semper lectus. Pellentesque interdum enim eu lacus malesuada dictum eget eget sem. Aliquam in tristique felis. Donec ac imperdiet lectus, eu mattis lectus. Maecenas eu elementum enim, sed viverra ex.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Does Nothing',
        onPressed: () {},
      ),
    );
  }
}
