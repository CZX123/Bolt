import 'package:flutter/foundation.dart';
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
import 'src/firebase/firebase.dart';

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
        StreamProvider<FirebaseConnectionState>(
          initialData: FirebaseConnectionState.connected,
          builder: (context) {
            return FirebaseDatabase.instance
                .reference()
                .child('.info/connected')
                .onValue
                .map((event) {
              return event.snapshot.value
                  ? FirebaseConnectionState.connected
                  : FirebaseConnectionState.disconnected;
            });
          },
        ),
        // Provider for all values in FirebaseDatabase. This provider updates whenever database value changes (which is quite frequently). All other providers for indivual values in the database listen to this main provider and update accordingly.
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
                return stallDataList;
              }),
          catchError: (context, object) {
            // TODO: handle errors
            print(object);
          },
        ),
        // Provider for the list of stall names. This should be rarely updated.
        ProxyProvider<List<StallData>, List<StallNameAndImage>>(
          builder: (context, stallDataList, stallNameAndImage) {
            if (stallDataList == null) return null;
            return stallDataList
                .map((stallData) => StallNameAndImage.fromStallData(stallData))
                .toList();
          },
          updateShouldNotify: (list1, list2) {
            if (list1?.length != list2?.length) return true;
            int i = -1;
            return !list1.every((item) {
              i++;
              return item.name == list2[i].name && item.image == list2[i].image;
            });
          },
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
        follower.position.jumpToWithoutSettling(
            leader.offset); // ignore deprecated use, no other easier way
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
        body: Consumer<List<StallNameAndImage>>(
          builder: (context, stallNamesAndImages, child) {
            Widget element = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  if (Provider.of<FirebaseConnectionState>(context) ==
                      FirebaseConnectionState.disconnected)
                    Column(
                      children: <Widget>[
                        const SizedBox(height: 32),
                        Text('Oh No!',
                            style: Theme.of(context).textTheme.display2),
                        const SizedBox(height: 8),
                        const Text("Internet is down!"),
                      ],
                    ),
                ],
              ),
            );
            if (stallNamesAndImages != null) {
              scrollControllers = [for (var _ in stallNamesAndImages) ScrollController()];
              element = Stack(
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
                        onNotification: (notification) =>
                            _handlePageNotification(notification,
                                stallImagesPageController, mainPageController),
                        child: PageView(
                          controller: stallImagesPageController,
                          children: <Widget>[
                            for (int i = 0; i < stallNamesAndImages.length; i++)
                              StallImage(
                                key: ObjectKey(stallNamesAndImages[i].name),
                                offsetNotifier: offsetNotifier,
                                index: i,
                                stallName: stallNamesAndImages[i].name,
                                animation: animation,
                                defaultAnimation: defaultAnimation,
                                pageController: stallImagesPageController,
                                last: i == stallNamesAndImages.length - 1,
                              ),
                          ],
                        ),
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
                            tabs: [for (var s in stallNamesAndImages) s.name],
                          ),
                        ),
                      );
                    },
                    contentBuilder: (context, animation) {
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) =>
                            _handlePageNotification(notification,
                                mainPageController, stallImagesPageController),
                        child: PageView(
                          controller: mainPageController,
                          children: <Widget>[
                            for (int i = 0; i < stallNamesAndImages.length; i++)
                              Stall(
                                name: stallNamesAndImages[i].name,
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
            }
            return AnimatedSwitcher(
              switchOutCurve: Interval(0.5, 1, curve: Curves.easeIn),
              switchInCurve: Interval(0.5, 1, curve: Curves.easeOut),
              duration: Duration(milliseconds: 500),
              child: element,
            );
          },
        ),
      ),
    );
  }
}
