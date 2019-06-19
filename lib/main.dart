import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme.dart';
import 'settings.dart';
import 'src/widgets/bottom_sheet.dart';
import 'src/widgets/tab_bar.dart';
import 'dart:ui';
import 'src/stall.dart';
import 'src/stall_data.dart';
import 'src/order.dart';

void main() async {
  // force app to be only in portrait mode, and upright
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(BoltApp());
}

class BoltApp extends StatefulWidget {
  @override
  _BoltAppState createState() => _BoltAppState();
}

class _BoltAppState extends State<BoltApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider for ThemeData. Only used in settings, and rebuilding entire MaterialApp
        ChangeNotifierProvider.value(
          value: ThemeNotifier(),
        ),
        // Provider for all values in FirebaseDatabase. All other providers for indivual keys in the database listen to this main provider and update accordingly.
        StreamProvider<List<StallData>>(
          builder: (context) => FirebaseDatabase.instance
                  .reference()
                  .child('stalls')
                  .onValue
                  .map<List<StallData>>((event) {
                if (event == null) return null;
                Map<String, dynamic> map =
                    Map<String, dynamic>.from(event.snapshot.value);
                var stallDataList = map
                    .map((key, value) {
                      return MapEntry(StallData.fromJson(key, value), 0);
                    })
                    .keys
                    .toList();
                print(stallDataList);
                return stallDataList;
              }),
          catchError: (context, object) {
            // TODO: handle errors
            print(object);
          },
        ),
        // Provider for the list of stall names. This should be rarely updated.
        ProxyProvider<List<StallData>, List<String>>(
          builder: (context, stallDataList, stallList) {
            if (stallDataList == null) return null;
            return stallDataList.map((stallData) => stallData.name).toList();
          },
          updateShouldNotify: (list1, list2) => list1 != list2,
          dispose: (context, list) => list == null,
        ),
        // ChangeNotifierProvider(
        //   builder: (_) => ThemeNotifier(),
        // ),
        ChangeNotifierProvider(
          builder: (_) => ViewOrder(),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, widget) {
          return MaterialApp(
            title: 'Bolt',
            theme: themeNotifier.currentThemeData,
            home: Home(),
          );
        },
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  EdgeInsets windowPadding;
  PageController stallImagesPageController = PageController();
  PageController mainPageController = PageController();
  List<ScrollController> scrollControllers;
  ValueNotifier<double> offsetNotifier = ValueNotifier(0);

  bool _handlePageNotification(ScrollNotification notification,
      PageController leader, PageController follower) {
    if (notification.depth == 0 && notification is ScrollUpdateNotification) {
      if (follower.offset != leader.offset) {
        offsetNotifier.value = leader.offset;
        follower.position.jumpToWithoutSettling(leader.offset);
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      Provider.of<ThemeNotifier>(context).isDarkMode =
          prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    windowPadding =
        MediaQuery.of(context).padding + MediaQuery.of(context).viewInsets;
  }

  @override
  void dispose() {
    stallImagesPageController.dispose();
    mainPageController.dispose();
    scrollControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: windowPadding,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: Drawer(
          child: SettingsPage(),
        ),
        body: Consumer<List<String>>(
          builder: (context, stallList, child) {
            if (stallList == null) return SizedBox();
            scrollControllers = [for (var _ in stallList) ScrollController()];
            return Stack(
              children: <Widget>[
                CustomBottomSheet(
                  enableLocalHistoryEntry: false,
                  swipeArea: SwipeArea.entireScreen,
                  overscrollAfterUpwardDrag: true,
                  overscrollAfterDownwardDrag: true,
                  pageController: mainPageController,
                  controllers: scrollControllers,
                  headerHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).size.width / 2560 * 1600,
                  backgroundContentBuilder:
                      (context, defaultAnimation, animation) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) => _handlePageNotification(
                          notification,
                          stallImagesPageController,
                          mainPageController),
                      child: PageView(
                        controller: stallImagesPageController,
                        children: <Widget>[
                          for (int i = 0; i < stallList.length; i++)
                            StallImage(
                              key: ObjectKey(stallList[i]),
                              offsetNotifier: offsetNotifier,
                              index: i,
                              stallName: stallList[i],
                              animation: animation,
                              defaultAnimation: defaultAnimation,
                              pageController: stallImagesPageController,
                              last: i == stallList.length - 1,
                            ),
                        ],
                      ),
                      // child: AnimatedBuilder(
                      //     animation: animation,
                      //     child: FadeInImage(
                      //       placeholder: MemoryImage(kTransparentImage),
                      //       image: NetworkImage(
                      //         'https://firebasestorage.googleapis.com/v0/b/bolt12345.appspot.com/o/stall.jpg?alt=media&token=02392581-982b-4a9f-896b-61f46225e2af',
                      //       ),
                      //       fit: BoxFit.cover,
                      //     ),
                      //     builder: (context, child) {
                      //       double height;
                      //       double y = 0;
                      //       if (animation.value < 0)
                      //         height = defaultAnimation.value *
                      //                 MediaQuery.of(context).size.height +
                      //             32;
                      //       else {
                      //         height = MediaQuery.of(context).size.width /
                      //                 2560 *
                      //                 1600 +
                      //             32;
                      //         y = animation.value *
                      //             -(MediaQuery.of(context).size.width /
                      //                     2560 *
                      //                     1600 +
                      //                 32) /
                      //             2;
                      //       }
                      //       return Container(
                      //         height: height,
                      //         child: PageView(
                      //           controller: stallImagesPageController,
                      //           children: <Widget>[
                      //             for (var _ in stallList)
                      //               Transform.translate(
                      //                 offset: Offset(0, y),
                      //                 child: child,
                      //               ),
                      //           ],
                      //         ),
                      //       );
                      //     }),
                    );
                  },
                  headerBuilder: (context, animation, expandSheetCallback,
                      innerBoxIsScrolled) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: innerBoxIsScrolled,
                      builder: (context, value, child) {
                        return Material(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16)),
                          color: Theme.of(context).canvasColor,
                          elevation: value ? 8 : 0,
                          child: child,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Padding(
                            padding: EdgeInsets.only(
                                top: animation.value
                                        .clamp(0.0, double.infinity) *
                                    windowPadding.top),
                            child: child,
                          );
                        },
                        child: CustomTabBar(
                          offsetNotifier: offsetNotifier,
                          pageController: mainPageController,
                          tabs: [for (var name in stallList) name],
                        ),
                      ),
                    );
                  },
                  contentBuilder: (context, animation) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) => _handlePageNotification(
                          notification,
                          mainPageController,
                          stallImagesPageController),
                      child: PageView(
                        controller: mainPageController,
                        children: <Widget>[
                          for (int i = 0; i < stallList.length; i++)
                            Stall(
                              name: stallList[i],
                              animation: animation,
                              scrollController: scrollControllers[i],
                            ),
                        ],
                      ),
                    );
                  },
                ),
                ViewOrderScreen(),
              ],
            );
            // return AnimatedOpacity(
            //   duration: Duration(milliseconds: 1000),
            //   opacity: stallList == null ? 0 : 1,
            //   child: Stack(
            //     children: <Widget>[
            //       TabBarView(
            //         controller: _tabController,
            //         children: <Widget>[
            //           if (stallList != null)
            //             for (String name in stallList)
            //               Stall(
            //                 name: name,
            //               ),
            //         ],
            //       ),
            //       CustomBottomSheet(
            //         headerHeight: 52 + 52 + windowPadding.bottom,
            //         windowHeight: MediaQuery.of(context).size.height,
            //         headerBuilder: (context, viewSheet) => Column(
            //               children: <Widget>[
            //                 Material(
            //                   type: MaterialType.transparency,
            //                   child: TabBar(
            //                     unselectedLabelStyle: Theme.of(context).textTheme.body1.copyWith(
            //                       textBaseline: TextBaseline.ideographic,
            //                       fontSize: 12,
            //                       color: Colors.black38,
            //                     ),
            //                     labelColor:
            //                         Theme.of(context).colorScheme.onSurface,
            //                     controller: _tabController,
            //                     indicator: BoxDecoration(),
            //                     isScrollable: true,
            //                     tabs: <Widget>[
            //                       if (stallList != null)
            //                         for (String name in stallList)
            //                           SizedBox(
            //                             height: 48.0,
            //                             child: Tab(
            //                               child: Container(
            //                                 height: 36,
            //                                 alignment: Alignment(0, 0.5),
            //                                 child: Text(name),
            //                               ),
            //                               //text: name,
            //                             ),
            //                           ),
            //                     ],
            //                   ),
            //                 ),
            //                 FlatButton(
            //                   textColor: Theme.of(context).primaryColor,
            //                   child: Container(
            //                     height: 52,
            //                     width: MediaQuery.of(context).size.width,
            //                     alignment: Alignment.center,
            //                     child: Text('View Order'),
            //                   ),
            //                   onPressed: viewSheet,
            //                 ),
            //                 SizedBox(
            //                   height: windowPadding.bottom,
            //                 ),
            //               ],
            //             ),
            //         contentBuilder: (context, scrollController) {
            //           return SingleChildScrollView(
            //             controller: scrollController,
            //             physics: NeverScrollableScrollPhysics(),
            //             padding: EdgeInsets.fromLTRB(0, windowPadding.top, 0, 72),
            //             child: Column(
            //               children: <Widget>[
            //                 for (int i = 0; i < 30; i++)
            //                   Container(
            //                     height: 48,
            //                     alignment: Alignment.center,
            //                     child: Text('${i + 1}'),
            //                   ),
            //               ],
            //             ),
            //           );
            //         },
            //       ),
            //     ],
            //   ),
            // );
          },
        ),
      ),
    );
  }
}
