import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'theme.dart' as theme;
import 'settings.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'widgets.dart';

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
  final List<String> stallList = [
    'Noodles',
    'Japanese',
    'Western',
    "Mum's Cooking",
    'Chicken Rice',
    'Malay',
  ];

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
              for (String name in stallList)
                Stall(
                  name: name,
                ),
            ],
          ),
          // Positioned(
          //   left: 0.0,
          //   right: 0.0,
          //   bottom: 0.0,
          //   child: Transform.rotate(
          //     angle: pi,
          //     child: Material(
          //       borderRadius: BorderRadius.only(
          //         bottomLeft: Radius.circular(16.0),
          //         bottomRight: Radius.circular(16.0),
          //       ),
          //       color: Theme.of(context).canvasColor,
          //       elevation: 16.0,
          //       child: Transform.rotate(
          //         angle: pi,
          //         child: TabBar(
          //           labelColor: Theme.of(context).colorScheme.onSurface,
          //           controller: _tabController,
          //           indicatorSize: TabBarIndicatorSize.label,
          //           indicatorColor: Theme.of(context).colorScheme.onSurface,
          //           isScrollable: true,
          //           tabs: <Widget>[
          //             Tab(
          //               text: 'Noodles',
          //             ),
          //             Tab(
          //               text: 'Japanese',
          //             ),
          //             Tab(
          //               text: 'Western',
          //             ),
          //             Tab(
          //               text: "Mum's Cooking",
          //             ),
          //             Tab(
          //               text: 'Chicken Rice',
          //             ),
          //             Tab(
          //               text: 'Malay',
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: CustomTabBar(
              tabController: _tabController,
            ),
          ),
        ],
      ),
    );
  }
}

class Stall extends StatefulWidget {
  final String name;
  Stall({@required this.name});
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
    super.build(context);
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
                            '${widget.name} Stall Menu',
                            style: Theme.of(context).textTheme.display2,
                          ),
                        ),
                        // FlatButton(
                        //   onPressed: () {
                        //     getTemporaryDirectory().then((dir) {
                        //       File imageFile = File(
                        //           '${dir.path}/stall.jpg');
                        //       imageFile.exists().then((exists) {
                        //         if (exists) imageFile.delete();
                        //       });
                        //       File imageFile2 = File(
                        //           '${dir.path}/food.jpg');
                        //       imageFile2.exists().then((exists) {
                        //         if (exists) imageFile2.delete();
                        //       });
                        //     });
                        //   },
                        //   child: Text('Clear Images'),
                        // ),
                      ],
                    ),
                  ),
                ]),
              ),
              SliverToBoxAdapter(
                child: StreamBuilder<Event>(
                  stream: FirebaseDatabase.instance.reference().child('food').onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: LinearProgressIndicator(),
                    );
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
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    children: <Widget>[
                      for (int i = 0; i < 10; i++) FoodItem(),
                    ],
                  ),
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
  StallImage({@required this.controller});
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
      File file = File('${dir.path}/stall.jpg');
      file.exists().then((exists) {
        if (exists)
          setState(() => imageFile = file);
        else {
          print('Downloading Image');
          FirebaseStorage.instance
              .ref()
              .child('stall.jpg')
              .getData(10 * 1024 * 1024)
              .then((data) {
            file.writeAsBytes(data).then((file) {
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
    double width = MediaQuery.of(context).size.width;
    return Stack(
      children: <Widget>[
        Positioned(
          top: top,
          child: Container(
            color: Theme.of(context).dividerColor,
            height: width / 2560 * 1600,
            child: AnimatedOpacity(
              opacity: imageFile != null ? 1.0 : 0.0,
              duration: Duration(
                milliseconds: 500,
              ),
              child: imageFile != null ? Image.file(imageFile) : SizedBox(),
            ),
          ),
        ),
        Positioned(
          top: top * 2 + width / 2560 * 1600 - 16.0,
          child: Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              Transform.rotate(
                angle: pi,
                child: Material(
                  elevation: 16.0,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16.0),
                  child: SizedBox(
                    height: 32.0,
                    width: width,
                  ),
                ),
              ),
              Positioned(
                top: 16.0,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  height: 64.0,
                  width: width,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CustomTabBar extends StatefulWidget {
  final TabController tabController;
  CustomTabBar({@required this.tabController});

  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  final List<String> stallList = [
    'Noodles',
    'Japanese',
    'Western',
    "Mum's Cooking",
    'Chicken Rice',
    'Malay',
  ];
  List<GlobalKey> tabKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];
  List<double> positions = [0.0];
  TabController tabController;
  ScrollController scrollController = ScrollController();
  double leftSpacing = 0.0;
  double rightSpacing = 0.0;

  void tabListener() {
    // TODO: Add code
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      setState(() {
        leftSpacing = (MediaQuery.of(context).size.width - 16.0 -
                tabKeys[0].currentContext.size.width) /
            2;
        rightSpacing = (MediaQuery.of(context).size.width - 16.0 -
                tabKeys[5].currentContext.size.width) /
            2;
        for (int i = 1; i < tabKeys.length; i++) {
          positions.add(positions[i - 1] +
              (tabKeys[i - 1].currentContext.size.width +
                      tabKeys[i].currentContext.size.width) /
                  2);
        }
        print(positions);
      });
    });
    tabController = widget.tabController;
    tabController.animation.addListener(tabListener);
  }

  @override
  void dispose() {
    tabController.removeListener(tabListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12.0),
      color: Theme.of(context).canvasColor,
      elevation: 16.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: leftSpacing,
              ),
              for (var i = 0; i < stallList.length; i++)
                FlatButton(
                  key: tabKeys[i],
                  child: Container(
                    alignment: Alignment.center,
                    height: 56.0,
                    child: Text(stallList[i]),
                  ),
                  onPressed: () {
                    scrollController.animateTo(
                      positions[i],
                      duration: Duration(milliseconds: 300),
                      curve: Curves.ease,
                    );
                    tabController.animateTo(i);
                    setState(() {});
                  },
                ),
              SizedBox(
                width: rightSpacing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
