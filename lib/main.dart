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
      canvasColor: Colors.grey[850],
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
      canvasColor: Colors.grey[900],
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
      drawer: Drawer(
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
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: Material(
              color: Theme.of(context).canvasColor,
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
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: <Widget>[
          StallImage(
            controller: scrollController,
          ),
          CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate([
                  SizedBox(
                    height: MediaQuery.of(context).size.width / 2560 * 1600,
                  ),
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(
                          height: 24.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.accessibility,
                                  color: Theme.of(context).dividerColor,
                                  size: 128.0,
                                ),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      '18',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 36.0,
                                        height: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'people',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 15.0,
                                        height: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.access_time,
                                  color: Theme.of(context).dividerColor,
                                  size: 128.0,
                                ),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      '12',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 36.0,
                                        height: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'mins',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 15.0,
                                        height: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 24.0,
                        ),
                        Center(
                          child: Text(
                            'Menu',
                            style: Theme.of(context).textTheme.title,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(2.0, 24.0, 2.0, 96.0),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 2.0,
                  crossAxisSpacing: 2.0,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StallImage extends StatefulWidget {
  final ScrollController controller;
  StallImage({this.controller});
  _StallImageState createState() => _StallImageState();
}

class _StallImageState extends State<StallImage> {
  double actualTop = 0;
  double top = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      double offset = widget.controller.offset;
      actualTop = -offset / 2;
      double imageHeight = MediaQuery.of(context).size.width / 2560 * 1600;
      if (actualTop * -2 < imageHeight) {
        setState(() => top = actualTop <= 0 ? actualTop : 0);
      }
      else if (top != -imageHeight) {
        setState(() => top = -imageHeight);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      child: Container(
        height: MediaQuery.of(context).size.width / 2560 * 1600,
        child: Image.network(
            'https://images.wallpaperscraft.com/image/torii_landscape_lake_127598_2560x1600.jpg'),
      ),
    );
  }
}
