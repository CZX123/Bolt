import 'library.dart';
import 'dart:ui' as ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // force app to be only in portrait mode, and upright
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(BoltApp());
}

class BoltApp extends StatefulWidget {
  @override
  _BoltAppState createState() => _BoltAppState();
}

class _BoltAppState extends State<BoltApp> {
  final _sharedPreferences = SharedPreferences.getInstance();
  final _firebaseDatabase = FirebaseDatabase.instance;

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

  @override
  void initState() {
    super.initState();
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
      child: FutureBuilder<SharedPreferences>(
        future: _sharedPreferences,
        builder: (context, snapshot) {
          final prefs = snapshot.data;
          // TODO: show loading screen here instead
          if (prefs == null) return SizedBox.shrink();
          _themeModel.isDark = prefs.getBool('isDark') ?? false;
          return Provider.value(
            value: prefs,
            child: ChangeNotifierProvider.value(
              value: _themeModel,
              child: Container(
                color: _themeModel.currentThemeData.scaffoldBackgroundColor,
                child: MaterialApp(
                  title: 'Bolt',
                  theme: _themeModel.currentThemeData,
                  home: Home(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Extra [Home] widget required to provide the corrected [MediaQuery] padding to all descendants and new routes, as well as a better [Hero] animation curve
class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _routes = <String, WidgetBuilder>{
    '/home': (context) => MainScreen(),
    '/login': (context) => LoginScreen(),
  };
  final _navigatorKey = GlobalKey<NavigatorState>();
  HeroController _heroController;
  List<NavigatorObserver> _navigatorObservers = [];

  EdgeInsets _windowPadding;
  OrderSheetController _orderSheetController;

  RectTween _createRectTween(Rect begin, Rect end) {
    return MaterialRectCenterArcTween(begin: begin, end: end);
  }

  @override
  void initState() {
    super.initState();
    _heroController = HeroController(createRectTween: _createRectTween);
    _navigatorObservers.add(_heroController);
  }

  @override
  void dispose() {
    _orderSheetController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final height = MediaQuery.of(context).size.height;
    if (height == 0) return;
    // Combines both padding and viewInsets, since on Android the bottom padding due to navigation bar is actually in the viewInsets, not the padding
    _windowPadding =
        MediaQuery.of(context).padding + MediaQuery.of(context).viewInsets;
    _orderSheetController ??= OrderSheetController(
      end: (height - 66 - 12 - _windowPadding.bottom) / height,
      endCorrection: _windowPadding.top,
      initialPosition: BottomSheetPosition.hidden,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_windowPadding == null) return const SizedBox.shrink();
    final prefs = Provider.of<SharedPreferences>(context);
    return Provider.value(
      value: _windowPadding,
      child: ChangeNotifierProvider.value(
        value: _orderSheetController,
        child: WillPopScope(
          onWillPop: () async {
            if (_navigatorKey.currentState.canPop()) {
              _navigatorKey.currentState.pop();
              return false;
            }
            return true;
          },
          child: Navigator(
            key: _navigatorKey,
            observers: _navigatorObservers,
            onGenerateRoute: (settings) {
              WidgetBuilder builder;
              if (settings.isInitialRoute) {
                final success = prefs.getBool('success');
                if (success == null) {
                  // TODO: Implement onboarding. For now show the login page.
                  builder = _routes['/login'];
                } else {
                  builder = _routes[success ? '/home' : '/login'];
                }
              } else {
                switch (settings.name) {
                  case '/dishEdit':
                    assert(settings.arguments != null);
                    assert(settings.arguments is DishEditScreenArguments);
                    final DishEditScreenArguments typedArguments =
                        settings.arguments;
                    builder = (context) {
                      return DishEditScreen(
                        tag: typedArguments.tag,
                        dish: typedArguments.dish,
                      );
                    };
                    break;
                  default:
                    builder = _routes[settings.name];
                }
              }
              return CrossFadePageRoute(
                builder: builder,
              );
            },
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key key}) : super(key: key);
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  EdgeInsets _windowPadding;
  PageController stallImagesPageController = PageController();
  PageController mainPageController = PageController();
  List<ScrollController> scrollControllers;
  BottomSheetController _mainBottomSheetController;
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
    _windowPadding = Provider.of<EdgeInsets>(context);
    final stallIdList = Provider.of<StallIdList>(context);
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    if (_stallIdList != stallIdList && stallIdList.value != null) {
      _stallIdList = stallIdList;
      _mainBottomSheetController ??= BottomSheetController(
        end: width / 2560 * 1600 / height,
        endCorrection: _windowPadding.top,
        swipeArea: SwipeArea.entireScreen,
        seamlessScrolling: true,
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
    stallImagesPageController.dispose();
    mainPageController
      ..removeListener(pageListener)
      ..dispose();
    for (var controller in scrollControllers) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: SettingsPage(),
      ),
      body: AnimatedSwitcher(
        duration: 400.milliseconds,
        child: _stallIdList == null
            ? LoadingScreen()
            : Stack(
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
                            for (int i = 0; i < _stallIdList.value.length; i++)
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
                                    animation:
                                        _mainBottomSheetController.altAnimation,
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
                                              ? Theme.of(context).dividerColor
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
                                      _mainBottomSheetController.altAnimation,
                                  builder: (context, value, child) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          top: value.clamp(0.0, 1.0) *
                                              _windowPadding.top),
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
                  OrderSheet(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        8,
                        0,
                        8,
                        _windowPadding.bottom + 8,
                      ),
                      child: NoInternetWidget(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
