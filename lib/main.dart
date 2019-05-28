import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'theme.dart';
import 'settings.dart';
import 'widgets.dart';
import 'CustomBottomSheet.dart';

void main() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(BoltApp());
}

class ViewOrder extends ChangeNotifier {
  ViewOrder();
  bool viewOrder = false;
  void toggle() {
    viewOrder = !viewOrder;
    notifyListeners();
  }
}

class BoltApp extends StatefulWidget {
  @override
  BoltAppState createState() => BoltAppState();
}

class BoltAppState extends State<BoltApp> {
  // Stream<Event> stalls;
  // dynamic previousData;
  @override
  void initState() {
    super.initState();
    // stalls = FirebaseDatabase.instance.reference().child('stalls').onValue;
    // stalls.listen((data) {
    //   Map<dynamic, dynamic> values = data.snapshot.value;
    //   List<String> stallList = values.keys.whereType<String>().toList();
    //   Map<String, List<String>> menuList = values.map((key, value) {
    //     String stall = key.toString();
    //     List<String> menu = value['menu'].keys.whereType<String>().toList();
    //     return MapEntry(stall, menu);
    //   });
    //   print(stallList);
    //   print(menuList);
    //   print("DataReceived: " + data.snapshot.value.toString());
    // }, onDone: () {
    //   print("Task Done");
    // }, onError: (error) {
    //   print("Some Error");
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          builder: (_) => ThemeState(),
        ),
        ChangeNotifierProvider(
          builder: (_) => ViewOrder(),
        )
      ],
      child: Consumer<ThemeState>(
        builder: (context, themeState, widget) {
          return MaterialApp(
            title: 'Bolt',
            theme: themeList[themeState.themeCode],
            home: Home(),
          );
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    SharedPreferences.getInstance().then((prefs) {
      Provider.of<ThemeState>(context)
          .setThemeCode(prefs.getInt('themeCode') ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool viewOrder = Provider.of<ViewOrder>(context).viewOrder;
    return Scaffold(
      key: _scaffoldKey,
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
          CustomBottomSheet(
            windowHeight: MediaQuery.of(context).size.height,
            headerBuilder: (context, viewSheet) {
              return FlatButton(
                textColor: Theme.of(context).primaryColor,
                child: Container(
                  height: 52,
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  child: Text('View Order'),
                ),
                onPressed: viewSheet,
              );
            },
            contentBuilder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    0, MediaQuery.of(context).padding.top, 0, 72),
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < 30; i++)
                      Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text('${i + 1}'),
                      ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: IgnorePointer(
              ignoring: viewOrder,
              child: AnimatedOpacity(
                opacity: viewOrder ? 0 : 1,
                duration: Duration(milliseconds: 200),
                child: Material(
                  color: Theme.of(context).canvasColor,
                  child: Column(
                    children: <Widget>[
                      TabBar(
                        labelColor: Theme.of(context).colorScheme.onSurface,
                        controller: _tabController,
                        indicatorColor: Theme.of(context).colorScheme.onSurface,
                        indicatorSize: TabBarIndicatorSize.label,
                        isScrollable: true,
                        tabs: <Widget>[
                          for (String name in stallList)
                            SizedBox(
                              height: 48.0,
                              child: Tab(
                                text: name,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  ),
                ),
              ),
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
  _StallState createState() => _StallState();
}

class _StallState extends State<Stall> {
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    ViewOrder viewOrder = Provider.of<ViewOrder>(context);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: <Widget>[
          StallImage(
            controller: scrollController,
          ),
          SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.width / 2560 * 1600,
                ),
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    children: <Widget>[
                      StallQueue(
                        stallName: widget.name,
                        padding: EdgeInsets.only(top: 24),
                      ),
                      FlatButton(
                        child: Text('Toggle View Order'),
                        onPressed: () {
                          viewOrder.toggle();
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 72.0),
                        child: Wrap(
                          spacing: 8.0,
                          children: <Widget>[
                            for (int i = 0; i < 10; i++) FoodItem(),
                          ],
                        ),
                      ),
                      StreamBuilder<Event>(
                        stream: FirebaseDatabase.instance
                            .reference()
                            .child('stalls')
                            .onValue,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: LinearProgressIndicator(),
                            );
                          Map<dynamic, dynamic> stallData =
                              snapshot.data.snapshot.value;
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StallQueue extends StatefulWidget {
  final String stallName;
  final EdgeInsetsGeometry padding;
  const StallQueue({
    @required this.stallName,
    this.padding = const EdgeInsets.symmetric(vertical: 24.0),
  });
  @override
  _StallQueueState createState() => _StallQueueState();
}

class _StallQueueState extends State<StallQueue> {
  bool showSecond = false;
  String queue1 = '  ';
  String queue2 = '  ';

  @override
  void initState() {
    super.initState();
    Stream<Event> queueStream = FirebaseDatabase.instance
        .reference()
        .child('stalls')
        .child(widget.stallName.toLowerCase())
        .child('queue')
        .onValue;
    queueStream.listen((data) {
      setState(() {
        if (showSecond)
          queue1 = data.snapshot.value.toString();
        else
          queue2 = data.snapshot.value.toString();
        showSecond = !showSecond;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.accessibility,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  AnimatedCrossFade(
                    firstChild: Text(queue1),
                    secondChild: Text(queue2),
                    duration: Duration(milliseconds: 200),
                    firstCurve: Interval(0, .5),
                    secondCurve: Interval(.5, 1),
                    crossFadeState: showSecond
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                  ),
                  Text(' people'),
                  const SizedBox(
                    width: 24.0,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  AnimatedCrossFade(
                    firstChild: Text(int.tryParse(queue1) != null
                        ? '${int.parse(queue1) ~/ 1.5}'
                        : 'null'),
                    secondChild: Text(int.tryParse(queue2) != null
                        ? '${int.parse(queue2) ~/ 1.5}'
                        : 'null'),
                    duration: Duration(milliseconds: 200),
                    firstCurve: Interval(0, .5),
                    secondCurve: Interval(.5, 1),
                    crossFadeState: showSecond
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                  ),
                  Text(' mins'),
                  const SizedBox(
                    width: 24.0,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 16.0,
          ),
          Material(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    int currentValue = showSecond
                        ? int.tryParse(queue2)
                        : int.tryParse(queue1);
                    if (currentValue != null) {
                      FirebaseDatabase.instance
                          .reference()
                          .child('stalls')
                          .child(widget.stallName.toLowerCase())
                          .child('queue')
                          .set(currentValue + 1);
                    }
                  },
                ),
                const SizedBox(
                  width: 24.0,
                ),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    int currentValue = showSecond
                        ? int.tryParse(queue2)
                        : int.tryParse(queue1);
                    if (currentValue != null && currentValue != 0) {
                      FirebaseDatabase.instance
                          .reference()
                          .child('stalls')
                          .child(widget.stallName.toLowerCase())
                          .child('queue')
                          .set(currentValue - 1);
                    }
                  },
                ),
              ],
            ),
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
