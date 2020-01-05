import 'library.dart';
import 'package:flutter/services.dart';
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
  /// Whether both [_sharedPreferences], and [_currentUser] have loaded
  bool _loaded = false;
  SharedPreferences _sharedPreferences;
  final _currentUser = User(null);
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
    Future.wait([
      SharedPreferences.getInstance(),
      FirebaseAuth.instance.currentUser(),
    ]).then((values) {
      setState(() {
        _loaded = true;
        _sharedPreferences = values.first;
      });
      _currentUser.value = values.last;
      if (_currentUser.value.photoUrl != null) {
        precacheImage(NetworkImage(_currentUser.value.photoUrl), context);
      }
      _themeModel.isDark = _sharedPreferences.getBool('isDark') ?? false;
    });
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
          create: (_) => CartModel(),
        ),
      ],
      child: _loaded
          ? MultiProvider(
              providers: [
                Provider.value(value: _sharedPreferences),
                ChangeNotifierProvider.value(value: _currentUser),
                ChangeNotifierProvider.value(value: _themeModel),
              ],
              child: ValueListenableBuilder<FirebaseUser>(
                valueListenable: _currentUser,
                builder: (context, user, child) {
                  if (user == null) {
                    return Provider<UserData>.value(
                      value: null,
                      child: child,
                    );
                  }
                  return StreamProvider<UserData>.value(
                    value: FirebaseDatabase.instance
                        .reference()
                        .child('users/${user.uid}')
                        .onValue
                        .map((event) {
                      return UserData(
                        balance: event.snapshot.value['balance'],
                        hasOrders: event.snapshot.value['orders'] != null,
                      );
                    }),
                    child: child,
                  );
                },
                child: AnimatedBuilder(
                  animation: _themeModel,
                  builder: (context, child) {
                    return Container(
                      color:
                          _themeModel.currentThemeData.scaffoldBackgroundColor,
                      child: MaterialApp(
                        title: 'Bolt',
                        theme: _themeModel.currentThemeData,
                        home: Home(),
                      ),
                    );
                  },
                ),
              ),
            )
          : SizedBox.shrink(),
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
    final height = context.windowSize.height;
    if (height == 0) return;
    // Combines both padding and viewInsets, since on Android the bottom padding due to navigation bar is actually in the viewInsets, not the padding
    _windowPadding =
        MediaQuery.of(context).padding + MediaQuery.of(context).viewInsets;
    final hasOrders = context.get<CartModel>(listen: false).orders.isNotEmpty;
    _orderSheetController ??= OrderSheetController(
      end: (height - 66 - 12 - _windowPadding.bottom) / height,
      endCorrection: _windowPadding.top,
      initialPosition:
          hasOrders ? BottomSheetPosition.end : BottomSheetPosition.hidden,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_windowPadding == null) return const SizedBox.shrink();
    final user = context.get<User>(listen: false).value;
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
                builder = _routes[user != null ? '/home' : '/login'];
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
  /// Whether the user is on the current orders screen
  bool _isCurrentOrders = false;
  EdgeInsets _windowPadding;
  PageController stallImagesPageController = PageController();
  PageController mainPageController = PageController();
  List<ScrollController> scrollControllers;
  BottomSheetController _mainBottomSheetController;
  int _pageIndex = 0;
  StallIdList _stallIdList;

  Future<void> _showNotificationDialog(Map<String, dynamic> message) {
    return showCustomDialog<void>(
      context: context,
      dialog: AlertDialog(
        backgroundColor: context.theme.canvasColor,
        title: Text(message['notification']['title']),
        content: Text(
          message['notification']['body'],
          style: context.theme.textTheme.body1,
        ),
        actions: <Widget>[
          FlatButton(
            color: context.theme.accentColor,
            highlightColor: Colors.white12,
            splashColor: Colors.white12,
            child: Text(
              'Ok',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    mainPageController.addListener(pageListener);
    FirebaseMessaging().configure(
      onMessage: _showNotificationDialog,
      onResume: (_) {
        _changeScreen(true);
        return null;
      },
      onLaunch: (_) {
        _changeScreen(true);
        return null;
      }
    );
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
    _windowPadding = context.windowPadding;
    final stallIdList = context.get<StallIdList>();
    final height = context.windowSize.height;
    final width = context.windowSize.width;
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

  void _changeScreen(bool isCurrentOrders) {
    if (_isCurrentOrders == isCurrentOrders) return;
    if (isCurrentOrders) {
      setState(() {
        _isCurrentOrders = true;
      });
      ModalRoute.of(context).addLocalHistoryEntry(LocalHistoryEntry(
        onRemove: () {
          setState(() {
            _isCurrentOrders = false;
          });
        },
      ));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: AccountPage(
          changeScreen: _changeScreen,
          isCurrentOrders: _isCurrentOrders,
        ),
      ),
      body: AnimatedSwitcher(
        duration: 400.milliseconds,
        child: _stallIdList == null
            ? LoadingScreen()
            : CustomAnimatedSwitcher(
                child: _isCurrentOrders
                    ? CurrentOrdersScreen()
                    : Stack(
                        children: <Widget>[
                          // The main page with stalls is just one gigantic custom bottom sheet.
                          CustomBottomSheet(
                            color: context.theme.scaffoldBackgroundColor,
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
                                        animation: _mainBottomSheetController
                                            .altAnimation,
                                        defaultAnimation:
                                            _mainBottomSheetController
                                                .animation,
                                        pageController:
                                            stallImagesPageController,
                                        last:
                                            i == _stallIdList.value.length - 1,
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
                                                _mainBottomSheetController
                                                    .altAnimation,
                                            scrollController:
                                                scrollControllers[i],
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
                                            _mainBottomSheetController
                                                .isScrolled,
                                        builder: (context, value, child) {
                                          return AnimatedContainer(
                                            color: context
                                                .theme.scaffoldBackgroundColor
                                                .withOpacity(.92),
                                            foregroundDecoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: value
                                                      ? context
                                                          .theme.dividerColor
                                                      : context
                                                          .theme.dividerColor
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
      ),
    );
  }
}
