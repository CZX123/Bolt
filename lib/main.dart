import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'src/widgets/animated_fade.dart';
import 'theme.dart';
import 'settings.dart';
import 'src/widgets/bottom_sheet.dart';
import 'src/widgets/tab_bar.dart';
import 'dart:ui';
import 'src/stall.dart';
import 'src/stall_data.dart';
import 'src/order.dart';
import 'src/order_data.dart';
import 'src/widgets/firebase.dart';
import 'src/widgets/shimmer.dart';

void main() {
  // force app to be only in portrait mode, and upright
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
    // MultiProvider is a convenience widget to wrap multiple providers. The resulting structure is the same as nesting multiple providers. This just makes it neater.
    return MultiProvider(
      providers: [
        // Provider for ThemeData. Only used in settings, and rebuilding entire MaterialApp
        ChangeNotifierProvider.value(
          value: ThemeNotifier(),
        ),
        // 3 second delay on startup before app informs user that they do not have internet
        FutureProvider.value(
          initialData: false,
          value: Future.delayed((Duration(seconds: 3)), () => true),
        ),
        // This is the provider to check if user is connected to Firebase. Strangely, this returns FirebaseConnectionState.disconnected when app starts, so the delay above is needed.
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
        // The provider below is to combine both the delay and actual connection state above to a new FirebaseConnectionState provider that returns 'FirebaseConnectionState.connected' for the first 3 seconds
        ProxyProvider2<bool, FirebaseConnectionState, FirebaseConnectionState>(
          initialBuilder: (context) => FirebaseConnectionState.connected,
          builder: (context, delayCompleted, actualState, modifiedState) {
            if (!delayCompleted)
              return FirebaseConnectionState.connected;
            else
              return actualState;
          },
          dispose: (context, modifiedState) =>
              modifiedState = FirebaseConnectionState.connected,
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
            // TODO: handle errors, e.g. number of users exceeded Firebase maximum
            print(object);
          },
        ),
        // Provider for the list of stall names and stall images. More is said in stall_data.dart. This should be rarely updated.
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
            // Checking if every item in list is equivalent. Normal '==' operator does not work for lists.
            return !list1.every((item) {
              i++;
              return item.name == list2[i].name && item.image == list2[i].image;
            });
          },
        ),
        // The actual byte data of images is stored here. Initially, it's an empty map, with the key being the image's path name, and the Uint8List being the raw data. This is needed because images in the app will rebuild due to theme changes or stall data changes, and when they rebuild, they can easily access the stored data here instead of getting the image from device storage or Firebase again.
        Provider<Map<String, Uint8List>>.value(
          value: {},
        ),
        // Provider for currently ordered items. See order_data.dart for more.
        ChangeNotifierProvider(
          builder: (_) => OrderNotifier(),
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

  // This function is to sync the scroll positions of the stall images and the stall content. They are 2 separate PageViews.
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
    // Get theme preference from SharedPreferences when first initialising HomeState, and set accordingly
    SharedPreferences.getInstance().then((prefs) {
      Provider.of<ThemeNotifier>(context).isDarkMode =
          prefs.getBool('isDarkMode') ?? false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Combines both padding and viewInsets, since on Android the bottom padding due to navigation bar is actually in the viewInsets, not the padding
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
      // Provide the windowPadding value to all descendants
      value: windowPadding,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: Drawer(
          child: SettingsPage(),
        ),
        body: Consumer<List<StallNameAndImage>>(
          builder: (context, stallNamesAndImages, child) {
            // NOTE: there will be a lot of error messages on RenderFlex overflow, and Shimmer having negative constraints. Just ignore all those, a bit hard to fix, they are for the loading screen here.
            Widget element = LoadingScreen();
            if (stallNamesAndImages != null) {
              scrollControllers = [
                for (var _ in stallNamesAndImages) ScrollController()
              ];
              element = Stack(
                children: <Widget>[
                  // The main page with stalls is just one gigantic custom bottom sheet.
                  CustomBottomSheet(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    enableLocalHistoryEntry: false,
                    swipeArea: SwipeArea.entireScreen,
                    overscrollAfterUpwardDrag: true, // Not iOS overscroll, but more of carried momentum after sheet is fully expanded
                    overscrollAfterDownwardDrag: true, // same but for when user scrolls to top when sheet is fully expanded and whether the carried momentum while close the sheet
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
                            color: Theme.of(context).scaffoldBackgroundColor,
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
                  OrderScreen(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          8, 0, 8, windowPadding.bottom + 8),
                      child: NoInternetWidget(),
                    ),
                  ),
                ],
              );
            }
            // Cross fades between loading screen and actual screen
            return AnimatedSwitcher(
              switchOutCurve: Interval(0.1, 1, curve: Curves.easeIn),
              switchInCurve: Interval(0.1, 1, curve: Curves.easeOut),
              duration: Duration(milliseconds: 400),
              child: element,
            );
          },
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final windowPadding = Provider.of<EdgeInsets>(context);
    final double width = MediaQuery.of(context).size.width;
    final bool isDark = Provider.of<ThemeNotifier>(context).isDarkMode;
    Color baseColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.14);
    Color highlightColor =
        isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.07);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Shimmer.fromColors(
          key: ValueKey(isDark),
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: width / 2560 * 1600 + 32,
            color: Colors.white,
          ),
        ),
        Positioned.fill(
          top: width / 2560 * 1600,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: kElevationToShadow[6],
            ),
            child: PhysicalShape(
              color: Color(Theme.of(context).canvasColor.value),
              clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Shimmer.fromColors(
                key: ValueKey(isDark),
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        SizedBox(
                          height: 16,
                        ),
                        ClipRect(
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: (width - 72) / 2,
                              ),
                              for (int i = 0; i < 4; i++)
                                ClipRect(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 24),
                                    child: Container(
                                      height: 24,
                                      width: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 14,
                        ),
                        Center(
                          child: Container(
                            height: 2,
                            width: 96,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 36,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              height: 32,
                              width: 124,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
                              child: Container(
                                height: 32,
                                width: 112,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 42,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 13,
                            children: <Widget>[
                              for (int i = 0; i < 6; i++)
                                Column(
                                  children: <Widget>[
                                    ClipPath(
                                      clipper: ShapeBorderClipper(
                                        shape: ContinuousRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: Container(
                                        height: (width - 8.0 * 3) / 2,
                                        width: (width - 8.0 * 3) / 2,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 7,
                                    ),
                                    Container(
                                      height: 16,
                                      width: (width - 8.0 * 3) / 2 * .65,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Container(
                                      height: 14,
                                      width: (width - 8.0 * 3) / 2 * .25,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, windowPadding.bottom + 8),
            child: NoInternetWidget(),
          ),
        ),
      ],
    );
  }
}

class NoInternetWidget extends StatelessWidget {
  const NoInternetWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedFade(
        opacity: Provider.of<FirebaseConnectionState>(context) ==
                FirebaseConnectionState.disconnected
            ? 1
            : 0,
        child: Material(
          borderRadius: BorderRadius.circular(60),
          color: Colors.black.withOpacity(0.6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Text(
              Provider.of<List<StallNameAndImage>>(context) == null
                  ? 'Waiting for internet…'
                  : 'No Internet',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
