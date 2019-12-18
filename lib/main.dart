import 'library.dart';
import 'dart:ui' as ui;

void main() {
  // Force app to be only in portrait mode, and upright
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(BoltApp());
}

class BoltApp extends StatefulWidget {
  @override
  _BoltAppState createState() => _BoltAppState();
}

class _BoltAppState extends State<BoltApp> {
  final _firebaseDatabase = FirebaseDatabase.instance;

  /// Whether it is the user's first time using the app
  // TODO: Implement onboarding
  bool _firstTime = false;

  /// Stream that checks whether user is connected to Firebase
  final _streamController =
      StreamController<FirebaseConnectionState>(sync: true);

  /// Actual subscription to the Firebase connected stream.
  /// More info: https://firebase.google.com/docs/database/web/offline-capabilities#section-connection-state
  StreamSubscription<Event> _firebaseConnectionSubscription;
  void _initFirebaseConnectionSubscription() {
    // Wait for 3 seconds, then listen to the firebase connection stream
    // This is because the stream below returns [FirebaseConnectionState.disconnected] initially when app is loading, which is not ideal as it shows no internet momentarily even if app instantly loads
    Future.delayed(3.seconds, () {
      _firebaseConnectionSubscription = _firebaseDatabase
          .reference()
          .child('.info/connected')
          .onValue
          .listen((event) {
        // Forward the value to _streamController when the actual subscription changes
        _streamController.add(
          event.snapshot.value
              ? FirebaseConnectionState.connected
              : FirebaseConnectionState.disconnected,
        );
      });
    });
  }

  final _stallIdList = StallIdList();

  Stream<StallDetailsMap> _stallDetailsStream;
  void _initStallDetailsStream() {
    _stallDetailsStream = _firebaseDatabase
        .reference()
        .child('stalls')
        .onValue
        .map<StallDetailsMap>((event) {
      if (event == null) return null;
      Map map;
      try {
        map = Map.from(event.snapshot.value);
      } catch (e) {
        map = List.from(event.snapshot.value).asMap();
      }
      Map<StallId, StallDetails> stallDetails = {};
      map.forEach((key, value) {
        final id = StallId(key is int ? key : int.tryParse(key));
        if (id.value != null) {
          stallDetails[id] = StallDetails.fromJson(id, value);
        }
      });
      // Also update stall id list here
      _stallIdList.value = stallDetails.keys.toList();
      return StallDetailsMap(stallDetails);
    });
  }

  Stream<StallMenuMap> _stallMenuStream;
  void _initStallMenuStream() {
    _stallMenuStream = FirebaseDatabase.instance
        .reference()
        .child('stallMenu')
        .onValue
        .map<StallMenuMap>((event) {
      if (event == null) return null;
      Map map;
      try {
        map = Map.from(event.snapshot.value);
      } catch (e) {
        map = List.from(event.snapshot.value).asMap();
      }
      Map<StallId, StallMenu> stallMenus = {};
      map.forEach((key, value) {
        final id = StallId(key is int ? key : int.tryParse(key));
        if (id.value != null) {
          stallMenus[id] = StallMenu.fromJson(id, value);
        }
      });
      return StallMenuMap(stallMenus);
    });
  }

  final _themeModel = ThemeModel();

  void _initSharedPreferences() {
    SharedPreferences.getInstance().then((prefs) {
      final isDark = prefs.getBool('isDark');
      if (isDark == null) _firstTime = true;
      _themeModel.isDark = isDark ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _initFirebaseConnectionSubscription();
    _initStallDetailsStream();
    _initStallMenuStream();
  }

  @override
  void dispose() {
    _firebaseConnectionSubscription?.cancel();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider is a convenience widget to wrap multiple providers.
    // The resulting structure is the same as nesting multiple providers.
    return MultiProvider(
      providers: [
        // Save the directory path into a provider, so later references does not require to wait for a Future
        FutureProvider.value(
          value: getApplicationDocumentsDirectory(),
        ),
        // Provider for ThemeData. Only used in settings, and rebuilding entire MaterialApp
        ChangeNotifierProvider.value(
          value: _themeModel,
        ),
        // Provider for list of stall ids. Should never change, unless stalls are added or removed.
        ChangeNotifierProvider.value(
          value: _stallIdList,
        ),
        // Provider to check whether user is connected to Firebase
        StreamProvider.value(
          initialData: FirebaseConnectionState.connected,
          value: _streamController.stream,
        ),
        // Stream of stall details
        StreamProvider.value(
          value: _stallDetailsStream,
        ),
        // Stream of stall menus
        StreamProvider.value(
          value: _stallMenuStream,
        ),
        // Provider for currently ordered items. See order_data.dart for more.
        ChangeNotifierProvider(
          builder: (_) => CartModel(),
        ),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, widget) {
          return Container(
            color: themeModel.currentThemeData.scaffoldBackgroundColor,
            child: MaterialApp(
              title: 'Bolt',
              theme: themeModel.currentThemeData,
              onGenerateRoute: (settings) {
                return CrossFadePageRoute(
                  builder: (_) => Home(),
                );
              },
            ),
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
  BottomSheetController _mainBottomSheetController;
  BottomSheetController _orderSheetController;
  int _pageIndex = 0;
  StallIdList _stallIdList;

  @override
  void initState() {
    super.initState();
    mainPageController.addListener(pageListener);
  }

  void pageListener() {
    final pageIndex = mainPageController.page.round();
    if (_pageIndex != pageIndex) {
      _pageIndex = pageIndex;
      _mainBottomSheetController.activeScrollController =
          scrollControllers[pageIndex];
      _mainBottomSheetController.isScrolled.value =
          scrollControllers[pageIndex].offset > 5;
    }
  }

  // This function is to sync the scroll positions of the stall images and the stall content. They are 2 separate PageViews.
  bool _handlePageNotification(
    ScrollNotification notification,
    PageController leader,
    PageController follower,
  ) {
    if (notification.depth == 0 && notification is ScrollUpdateNotification) {
      if (follower.offset != leader.offset) {
        follower.position.jumpToWithoutSettling(
            leader.offset); // ignore deprecated use, no other easier way
      }
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stallIdList = Provider.of<StallIdList>(context);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    // Combines both padding and viewInsets, since on Android the bottom padding due to navigation bar is actually in the viewInsets, not the padding
    windowPadding =
        MediaQuery.of(context).padding + MediaQuery.of(context).viewInsets;
    if (_stallIdList != stallIdList && stallIdList.value != null) {
      _stallIdList = stallIdList;
      _mainBottomSheetController ??= BottomSheetController(
        end: width / 2560 * 1600 / height,
        endCorrection: windowPadding.top,
        swipeArea: SwipeArea.entireScreen,
        seamlessScrolling: true,
      );
      _orderSheetController ??= BottomSheetController(
        end: (height - 66 - 12 - windowPadding.bottom) / height,
        endCorrection: windowPadding.top,
        initialPosition: BottomSheetPosition.hidden,
      );
      scrollControllers = List.generate(stallIdList.value.length, (_) {
        return ScrollController(
          keepScrollOffset: false,
        );
      });
      _mainBottomSheetController.activeScrollController =
          scrollControllers[_pageIndex];
    }
  }

  @override
  void dispose() {
    _mainBottomSheetController.dispose();
    _orderSheetController.dispose();
    stallImagesPageController.dispose();
    mainPageController
      ..removeListener(pageListener)
      ..dispose();
    for (var controller in scrollControllers) controller.dispose();
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
        body: AnimatedSwitcher(
          duration: 400.milliseconds,
          child: _stallIdList == null
              ? LoadingScreen()
              : ChangeNotifierProvider.value(
                  value: _orderSheetController,
                  child: Stack(
                    children: <Widget>[
                      // The main page with stalls is just one gigantic custom bottom sheet.
                      CustomBottomSheet(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        controller: _mainBottomSheetController,
                        background: (context) {
                          return NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              return _handlePageNotification(
                                notification,
                                stallImagesPageController,
                                mainPageController,
                              );
                            },
                            child: PageView(
                              controller: stallImagesPageController,
                              children: <Widget>[
                                for (int i = 0;
                                    i < _stallIdList.value.length;
                                    i++)
                                  StallImage(
                                    key: ValueKey(_stallIdList.value[i]),
                                    stallId: _stallIdList.value[i],
                                    index: i,
                                    animation:
                                        _mainBottomSheetController.altAnimation,
                                    defaultAnimation:
                                        _mainBottomSheetController.animation,
                                    pageController: stallImagesPageController,
                                    last: i == _stallIdList.value.length - 1,
                                  ),
                              ],
                            ),
                          );
                        },
                        body: (context) {
                          return Stack(
                            children: <Widget>[
                              NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  return _handlePageNotification(
                                    notification,
                                    mainPageController,
                                    stallImagesPageController,
                                  );
                                },
                                child: PageView(
                                  controller: mainPageController,
                                  children: <Widget>[
                                    for (int i = 0;
                                        i < _stallIdList.value.length;
                                        i++)
                                      Stall(
                                        stallId: _stallIdList.value[i],
                                        animation: _mainBottomSheetController
                                            .altAnimation,
                                        scrollController: scrollControllers[i],
                                      ),
                                  ],
                                ),
                              ),
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        _mainBottomSheetController.isScrolled,
                                    builder: (context, value, child) {
                                      return AnimatedContainer(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor
                                            .withOpacity(.92),
                                        foregroundDecoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: value
                                                  ? Theme.of(context)
                                                      .dividerColor
                                                  : Theme.of(context)
                                                      .dividerColor
                                                      .withOpacity(0),
                                            ),
                                          ),
                                        ),
                                        duration: 200.milliseconds,
                                        curve: Curves.ease,
                                        child: Material(
                                          type: MaterialType.transparency,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: ValueListenableBuilder(
                                      valueListenable:
                                          _mainBottomSheetController
                                              .altAnimation,
                                      builder: (context, value, child) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              top: value.clamp(0.0, 1.0) *
                                                  windowPadding.top),
                                          child: child,
                                        );
                                      },
                                      child: CustomTabBar(
                                        pageController: mainPageController,
                                        stallIdList: _stallIdList.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                  ),
                ),
        ),
      ),
    );
  }
}
