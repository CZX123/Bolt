import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings.dart';
import 'widgets.dart';

void main() {
  runApp(AppTheme());
}

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
  int _fontCode = 3;
  int get fontCode => _fontCode;
  final List<String> fonts = [
    'Orkney',
    'Manrope',
    'Poppins',
    'Grantipo',
    'Montserrat'
  ];
  // Just for testing fonts

  void changeTheme(int code) {
    setState(() {
      _themeCode = code;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('themeCode', code);
    });
  }

  void changeFont(int code) {
    setState(() {
      _fontCode = code;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('fontCode', code);
    });
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _themeCode = prefs.getInt('themeCode') ?? 0;
        _fontCode = prefs.getInt('fontCode') ?? 3;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData _lightTheme = ThemeData(
      platform: TargetPlatform.iOS,
      fontFamily: fonts[_fontCode],
      brightness: Brightness.light,
      primarySwatch: Colors.indigo,
      accentColor: Colors.yellowAccent,
      scaffoldBackgroundColor: Colors.grey[50],
    );
    ThemeData _darkTheme = ThemeData(
      platform: TargetPlatform.iOS,
      fontFamily: fonts[_fontCode],
      brightness: Brightness.dark,
      primarySwatch: Colors.deepPurple,
      accentColor: Colors.orangeAccent,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        color: Colors.deepPurple,
      ),
    );
    ThemeData _blackTheme = ThemeData(
      platform: TargetPlatform.iOS,
      fontFamily: fonts[_fontCode],
      brightness: Brightness.dark,
      primarySwatch: Colors.teal,
      accentColor: Colors.redAccent,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        color: Colors.teal,
      ),
    );
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

class _HomeState extends State<Home> with TickerProviderStateMixin {
  TabController _tabController;

  Widget tabContent;

  void changeTheme(int newThemeCode) {
    AppTheme.of(context).changeTheme(newThemeCode);
    setState(() {});
  }

  void changeFont(int newFontCode) {
    AppTheme.of(context).changeFont(newFontCode);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    int _themeCode = AppTheme.of(context).themeCode;
    int _fontCode = AppTheme.of(context).fontCode;
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(
                'THEME',
                style: Theme.of(context).textTheme.subhead,
              ),
            ),
            RadioListTile<int>(
              title: Text('Light Theme'),
              value: 0,
              groupValue: _themeCode,
              onChanged: changeTheme,
            ),
            RadioListTile<int>(
              title: Text('Dark Theme'),
              value: 1,
              groupValue: _themeCode,
              onChanged: changeTheme,
            ),
            RadioListTile<int>(
              title: Text('Black Theme'),
              value: 2,
              groupValue: _themeCode,
              onChanged: changeTheme,
            ),
            Divider(),
            ListTile(
              title: Text(
                'FONT',
                style: Theme.of(context).textTheme.subhead,
              ),
            ),
            RadioListTile<int>(
              title: Text('Orkney'),
              value: 0,
              groupValue: _fontCode,
              onChanged: changeFont,
            ),
            RadioListTile<int>(
              title: Text('Manrope'),
              value: 1,
              groupValue: _fontCode,
              onChanged: changeFont,
            ),
            RadioListTile<int>(
              title: Text('Poppins'),
              value: 2,
              groupValue: _fontCode,
              onChanged: changeFont,
            ),
            RadioListTile<int>(
              title: Text('Grantipo'),
              value: 3,
              groupValue: _fontCode,
              onChanged: changeFont,
            ),
            RadioListTile<int>(
              title: Text('Montserrat'),
              value: 4,
              groupValue: _fontCode,
              onChanged: changeFont,
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          TabBarView(
            controller: _tabController,
            children: <Widget>[
              Stall(),
              Stall(),
              Stall(),
              Stall(),
              Stall(),
              Stall(),
            ],
          ),
          Positioned(
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
            child: Material(
              borderRadius: BorderRadius.circular(12.0),
              elevation: 8.0,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.onSurface,
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorColor: Theme.of(context).colorScheme.onSurface,
                isScrollable: true,
                tabs: <Widget>[
                  Tab(
                    text: 'NOODLES',
                  ),
                  Tab(
                    text: 'JAPANESE',
                  ),
                  Tab(
                    text: 'WESTERN',
                  ),
                  Tab(
                    text: 'STALL 4',
                  ),
                  Tab(
                    text: 'STALL 5',
                  ),
                  Tab(
                    text: 'STALL 6',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
/*       bottomNavigationBar: Material(
        elevation: 8.0,
        child: TabBar(
          labelColor: Theme.of(context).colorScheme.onSurface,
          controller: _tabController,
          indicator: BoxDecoration(),
          isScrollable: true,
          tabs: <Widget>[
            Tab(
              text: 'NOODLES',
            ),
            Tab(
              text: 'JAPANESE',
            ),
            Tab(
              text: 'WESTERN',
            ),
            Tab(
              text: 'STALL 4',
            ),
            Tab(
              text: 'STALL 5',
            ),
            Tab(
              text: 'STALL 6',
            ),
          ],
        ),
      ), */
    );
  }
}

class Stall extends StatefulWidget {
  @override
  StallState createState() => StallState();
}

class StallState extends State<Stall> {
  double actualTop = 0;
  double top = 0;
  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (v) {
        if (v is ScrollUpdateNotification) {
          actualTop -= v.scrollDelta / 2;
          if (actualTop * -2 < MediaQuery.of(context).size.width / 2560 * 1600) {
            setState(() => top = actualTop <= 0 ? actualTop : 0);
          }
        }
      },
      child: Container(
        color: Theme.of(context).canvasColor,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: top,
              child: Container(
                height: MediaQuery.of(context).size.width / 2560 * 1600,
                child: Image.network(
                    'https://images.wallpaperscraft.com/image/torii_landscape_lake_127598_2560x1600.jpg'),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).size.width / 2560 * 1600,
                  ),
                  Container(
                    color: Theme.of(context).canvasColor,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(72.0, 24.0, 72.0, 8.0),
                          child: const Text(
                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed quis mauris vel quam tempor luctus ac id est. Phasellus nibh metus, iaculis id elit vitae, efficitur pretium elit. In quis porttitor mauris, ac commodo eros. Suspendisse elit sapien, iaculis quis fermentum vitae, luctus eget diam. Suspendisse pretium ex vitae libero facilisis lacinia. Cras dictum purus at sapien consectetur consectetur. Aenean diam lectus, dapibus blandit erat vel, lobortis tempor leo.',
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 8.0),
                          child: Text(
                            'These are some big words.',
                            style: Theme.of(context).textTheme.display1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 8.0),
                          child: Text(
                            'And a heading',
                            style: Theme.of(context).textTheme.display2,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 8.0),
                          child: Text(
                            'And another heading',
                            style: Theme.of(context).textTheme.display3,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 8.0),
                          child: Text(
                            'Big',
                            style: Theme.of(context).textTheme.display4,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(72.0, 8.0, 72.0, 0.0),
                          child: const Text(
                            'Suspendisse venenatis ligula et lectus suscipit, sit amet tempus sem fermentum. Fusce efficitur dictum ornare. Morbi nisl ipsum, hendrerit tincidunt efficitur eget, congue a nisi. Nullam scelerisque iaculis tellus non commodo. In id turpis orci. Etiam non maximus ex, in accumsan tortor. Fusce eget tempor felis, id elementum orci. Vivamus pretium dapibus eros, efficitur iaculis nibh lobortis nec. Maecenas mattis nec tellus sit amet efficitur. Proin eu dapibus nulla, mattis semper lectus. Pellentesque interdum enim eu lacus malesuada dictum eget eget sem. Aliquam in tristique felis. Donec ac imperdiet lectus, eu mattis lectus. Maecenas eu elementum enim, sed viverra ex.',
                          ),
                        ),
                        const SizedBox(
                          height: 88.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
