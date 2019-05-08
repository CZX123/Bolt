import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'theme.dart' as theme;
import 'settings.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
  bool isDarkTheme = false;
  bool blackOverDark = false;

  void darkTheme(bool isDark) {
    setState(() {
      isDarkTheme = isDark;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isDarkTheme', isDark);
    });
  }

  void blackTheme(bool isBlack) {
    setState(() {
      blackOverDark = isBlack;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('blackOverDark', isBlack);
    });
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
        blackOverDark = prefs.getBool('blackOverDark') ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeInherited(
      data: this,
      child: MaterialApp(
        title: 'Bolt',
        theme: theme.themeList[isDarkTheme ? blackOverDark ? 2 : 1 : 0],
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
    return Scaffold(
      drawer: Drawer(
        child: SettingsWidget(),
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
                    text: 'Noodles',
                  ),
                  Tab(
                    text: 'Japanese',
                  ),
                  Tab(
                    text: 'Western',
                  ),
                  Tab(
                    text: "Mum's Cooking",
                  ),
                  Tab(
                    text: 'Chicken Rice',
                  ),
                  Tab(
                    text: 'Malay',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Stall extends StatefulWidget {
  @override
  StallState createState() => StallState();
}

class StallState extends State<Stall>
    with AutomaticKeepAliveClientMixin<Stall> {
  ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

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
                                      style:
                                          Theme.of(context).textTheme.display3,
                                    ),
                                    Text(
                                      'people',
                                      style: Theme.of(context)
                                          .textTheme
                                          .body1
                                          .copyWith(
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
                                      style:
                                          Theme.of(context).textTheme.display3,
                                    ),
                                    Text(
                                      'mins',
                                      style: Theme.of(context)
                                          .textTheme
                                          .body1
                                          .copyWith(
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
                            style: Theme.of(context).textTheme.display2,
                          ),
                        ),
                        FlatButton(
                          onPressed: () {
                            getTemporaryDirectory().then((dir) {
                              File imageFile = File(
                                  '${dir.path}/torii_landscape_lake_127598_2560x1600.jpg');
                              imageFile.exists().then((exists) {
                                if (exists) imageFile.delete();
                              });
                            });
                          },
                          child: Text('Clear Image File'),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              SliverToBoxAdapter(
                child: StreamBuilder<Event>(
                  stream: FirebaseDatabase.instance.reference().child('food').onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return LinearProgressIndicator();
                    Map<dynamic, dynamic> stallData = snapshot.data.snapshot.value;
                    List<Widget> stallWidgetList = [];
                    stallData.forEach((key, value) {
                      stallWidgetList.add(
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 16.0),
                          child: Text(
                            '$key: $value',
                            style: Theme.of(context).textTheme.display2,
                          ),
                        ),
                      );
                    });
                    return Column(
                      children: stallWidgetList,
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(4.0, 24.0, 4.0, 96.0),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
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
  File imageFile;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      double offset = widget.controller.offset;
      actualTop = -offset / 2;
      double imageHeight = MediaQuery.of(context).size.width / 2560 * 1600;
      if (actualTop * -2 < imageHeight) {
        setState(() => top = actualTop <= 0 ? actualTop : 0);
      } else if (top != -imageHeight) {
        setState(() => top = -imageHeight);
      }
    });
    getTemporaryDirectory().then((dir) {
      File file = File('${dir.path}/torii_landscape_lake_127598_2560x1600.jpg');
      file.exists().then((exists) {
        if (exists)
          setState(() => imageFile = file);
        else {
          print('Downloading Image');
          http
              .get(
                  'https://images.wallpaperscraft.com/image/torii_landscape_lake_127598_2560x1600.jpg')
              .then((response) {
            print('Saving Image');
            file.writeAsBytes(response.bodyBytes).then((file) {
              print('Done');
              setState(() {
                imageFile = file;
              });
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      child: Container(
        color: Theme.of(context).dividerColor,
        height: MediaQuery.of(context).size.width / 2560 * 1600,
        child: AnimatedOpacity(
          opacity: imageFile != null ? 1.0 : 0.0,
          duration: Duration(
            milliseconds: 500,
          ),
          child: imageFile != null ? Image.file(imageFile) : SizedBox(),
        ),
      ),
    );
  }
}
