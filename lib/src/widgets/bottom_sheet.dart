import '../../library.dart';

typedef CustomBottomSheetHeaderBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  VoidCallback expandSheetCallback,
  ValueNotifier<bool> innerBoxIsScrolled,
);

typedef CustomBottomSheetContentBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  // This animation here works differently. Value of 0 means sheet is collapsed, DOES NOT MEAN THAT SHEET IS FULLY BELOW THE SCREEN. Value of 1 means sheet is fully expanded. Opposite of the definitions way below.
);

enum SwipeArea { entireScreen, bottomSheet }

typedef CustomBottomSheetBackgroundContentBuilder = Widget Function(
  BuildContext context,
  Animation<double> defaultAnimation, // The animation below
  Animation<double> animation, // Same as above
);

class CustomBottomSheet extends StatefulWidget {
  final bool swipeParallax;
  final bool enableLocalHistoryEntry;
  final double headerHeight;
  final bool overscrollAfterDownwardDrag;
  final bool overscrollAfterUpwardDrag;
  final Duration headerHeightTransitionDuration;
  final Curve headerHeightTransitionCurve;
  final List<ScrollController> controllers;
  final TabController tabController;
  final PageController pageController;
  final CustomBottomSheetHeaderBuilder headerBuilder;
  final CustomBottomSheetContentBuilder contentBuilder;
  final CustomBottomSheetBackgroundContentBuilder backgroundContentBuilder;
  final ShapeBorder shape;
  final SwipeArea swipeArea;
  final Color color;
  CustomBottomSheet({
    this.swipeParallax: true,
    this.enableLocalHistoryEntry: true,
    this.overscrollAfterDownwardDrag: false,
    this.overscrollAfterUpwardDrag: false,
    @required this.headerBuilder,
    @required this.contentBuilder,
    this.backgroundContentBuilder,
    this.headerHeight,
    this.headerHeightTransitionDuration: const Duration(milliseconds: 400),
    this.headerHeightTransitionCurve: Curves.fastOutSlowIn,
    @required this.controllers,
    this.tabController,
    this.pageController,
    this.shape: const ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
    ),
    this.swipeArea: SwipeArea.bottomSheet,
    this.color,
    Key key,
  }) : super(key: key);

  _CustomBottomSheetState createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet>
    with SingleTickerProviderStateMixin {
  double windowHeight;
  double headerHeight;
  double initialValue; // Derived from windowHeight and headerHeight
  GlobalKey headerKey =
      GlobalKey(); // key for finding headerHeight if not given
  final SpringDescription spring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100,
    ratio: 1.1,
  );
  int tabIndex;
  ScrollController activeScrollController = ScrollController();
  AnimationController animationController;
  ScrollHoldController scrollHold;
  Drag scrollDrag;
  bool scrolling = false; // Scrolling in the scroll view within the sheet
  LocalHistoryEntry localHistoryEntry;
  bool localHistoryEntryAdded = false;
  bool disablePopAnimation = false;
  Timer scrollTimer;
  ValueNotifier<bool> innerBoxIsScrolled = ValueNotifier(false);
  double frictionFactor(double overscrollFraction) =>
      0.52 * pow(1 - overscrollFraction, 2);

  // user has touched the screen and may begin to drag
  void dragDown(DragDownDetails details) {
    // This line here is to stop the bottom sheet from moving and hold it in place should the user tap on the bottom sheet again while it is shifting
    animationController.value = animationController.value;
    scrollTimer?.cancel();

    // Check if the [SingleChildScrollView] is scrollable in the first place
    if (activeScrollController.hasClients &&
        activeScrollController.position.maxScrollExtent > 0)
      // simulate a hold on the [SingleChildScrollView]
      scrollHold = activeScrollController.position.hold(disposeScrollHold);
    // I don't really know if this is needed, but it is best to mimic and simulate actual scrolling on the [SingleChildScrollView] as close as possible, and that included holding
  }

  // user has just started to drag
  void dragStart(DragStartDetails details) {
    // Check if the [SingleChildScrollView] is scrollable in the first place
    if (activeScrollController.hasClients &&
        activeScrollController.position.maxScrollExtent > 0 &&
        animationController.value == 0) {
      // simulate a scroll on the [SingleChildScrollView]
      scrollDrag =
          activeScrollController.position.drag(details, disposeScrollDrag);
    }
  }

  // user is in the process of dragging
  void dragUpdate(DragUpdateDetails details) {
    if (animationController.value == 0 &&
        (details.primaryDelta < 0 || activeScrollController.offset > 0)) {
      if (scrollDrag == null)
        scrollDrag = activeScrollController.position.drag(
            DragStartDetails(
              sourceTimeStamp: details.sourceTimeStamp,
              globalPosition: details.globalPosition,
            ),
            disposeScrollDrag);
      scrolling = true;
      scrollDrag.update(details);
    } else {
      activeScrollController.jumpTo(0);
      dragCancel();
      scrolling = false;
      double delta = details.primaryDelta / windowHeight;
      if (widget.swipeParallax)
        delta *= initialValue /
            (initialValue -
                Provider.of<EdgeInsets>(context).top / windowHeight);
      if (animationController.value > initialValue)
        delta *= frictionFactor(
            (animationController.value - initialValue) / (1 - initialValue));
      animationController.value += delta;
    }
  }

  // user has finished dragging
  void dragEnd(DragEndDetails details) {
    final bool isExpanded = createBallistics(details);
    if (widget.enableLocalHistoryEntry) {
      if (isExpanded) {
        if (!localHistoryEntryAdded) {
          ModalRoute.of(context).addLocalHistoryEntry(localHistoryEntry);
          localHistoryEntryAdded = true;
        }
      } else if (localHistoryEntryAdded) {
        disablePopAnimation = true;
        Navigator.pop(context);
      }
    }
  }

  bool createBallistics(DragEndDetails details) {
    double velocity = details.primaryVelocity;
    scrollDrag?.end(details);
    if (velocity == 0) {
      Simulation simulation = ScrollSpringSimulation(
        spring,
        animationController.value,
        animationController.value > initialValue / 2 ? initialValue : 0,
        0,
      );
      animationController.animateWith(simulation);
      scrolling = false;
      return animationController.value <= initialValue / 2;
    }
    if (scrolling) {
      scrolling = false;
      FrictionSimulation scrollingSimulation = FrictionSimulation(
          0.135,
          activeScrollController.offset,
          -velocity *
              0.91); // https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/widgets/scroll_physics.dart
      double simulationEndTime = scrollingSimulation.timeAtX(0);
      if (simulationEndTime != double.infinity &&
          activeScrollController.offset <=
              activeScrollController.position.maxScrollExtent) {
        double velocityEnd =
            scrollingSimulation.dx(simulationEndTime) / windowHeight;
        scrollTimer = Timer(
          Duration(
              microseconds:
                  (simulationEndTime * Duration.microsecondsPerSecond).toInt()),
          () {
            activeScrollController.jumpTo(0);
            Simulation simulation = BouncingScrollSimulation(
              spring: spring,
              leadingExtent: 0,
              position: 0,
              trailingExtent: scrollingSimulation.x(double.infinity) <=
                          -initialValue * windowHeight &&
                      widget.overscrollAfterDownwardDrag
                  ? initialValue
                  : 0,
              velocity: -velocityEnd,
            );
            animationController.animateWith(simulation);
            scrollTimer = null;
          },
        );
        return false;
      }
      return true;
    }
    if (widget.overscrollAfterUpwardDrag) {
      FrictionSimulation frictionSimulation = FrictionSimulation(
          0.135, animationController.value, velocity / windowHeight);
      if (frictionSimulation.x(double.infinity) < 0) {
        animationController.animateWith(frictionSimulation);
        double simulationEndTime = frictionSimulation.timeAtX(0);
        double velocityEnd = frictionSimulation.dx(simulationEndTime);
        scrollTimer = Timer(
          Duration(
              microseconds:
                  (simulationEndTime * Duration.microsecondsPerSecond).toInt()),
          () {
            scrollDrag = activeScrollController.position
                .drag(DragStartDetails(), disposeScrollDrag);
            scrollDrag.end(DragEndDetails(
              velocity: Velocity(
                pixelsPerSecond: Offset(0, velocityEnd * windowHeight),
              ),
              primaryVelocity: velocityEnd * windowHeight,
            ));
            scrollTimer = null;
          },
        );
        return true;
      }
    }
    Simulation simulation = ScrollSpringSimulation(
      spring,
      animationController.value,
      velocity > 0 ? initialValue : 0,
      animationController.value >= initialValue ? 0 : velocity / windowHeight,
    );
    animationController.animateWith(simulation);
    return velocity <= 0;
  }

  // something unexpected happened that cause user to suddenly stopped dragging
  // e.g. random popup or dialog
  void dragCancel() {
    scrollHold?.cancel();
    scrollDrag?.cancel();
    scrollHold = null;
    scrollDrag = null;
  }

  void disposeScrollHold() {
    scrollHold = null;
  }

  void disposeScrollDrag() {
    scrollDrag = null;
  }

  void onPop() {
    if (!disablePopAnimation)
      animationController.animateWith(
        ScrollSpringSimulation(
          spring,
          animationController.value,
          initialValue,
          0,
        ),
      );
    disablePopAnimation = false;
    localHistoryEntryAdded = false;
  }

  void viewSheet() {
    animationController.animateWith(
      ScrollSpringSimulation(
        spring,
        animationController.value,
        0,
        0,
      ),
    );
    if (!localHistoryEntryAdded)
      ModalRoute.of(context).addLocalHistoryEntry(localHistoryEntry);
    localHistoryEntryAdded = true;
  }

  void updateIndexTabController() {
    final int newIndex = widget.tabController.index;
    if (tabIndex != newIndex) {
      dragCancel();
      tabIndex = newIndex;
      activeScrollController = widget.controllers[tabIndex];
      innerBoxIsScrolled.value = activeScrollController.hasClients &&
          activeScrollController.offset > 0;
    }
  }

  void updateIndexPageController() {
    final int newIndex = widget.pageController.page.round();
    if (tabIndex != newIndex) {
      dragCancel();
      tabIndex = newIndex;
      activeScrollController = widget.controllers[tabIndex];
      innerBoxIsScrolled.value = activeScrollController.hasClients &&
          activeScrollController.offset > 0;
    }
  }

  @override
  void initState() {
    super.initState();
    localHistoryEntry = LocalHistoryEntry(
      onRemove: onPop,
    );
    animationController = AnimationController(
      vsync: this,
      value:
          1, // value of 1 means sheet completely below the screen, value of 0 means sheet is fully expanded
    );
    if (widget.tabController == null && widget.pageController == null) {
      activeScrollController = widget.controllers[0];
    } else if (widget.pageController != null) {
      tabIndex = widget.pageController.hasClients
          ? widget.pageController.page.round()
          : widget.pageController.initialPage;
      activeScrollController = widget.controllers[tabIndex];
      widget.pageController.addListener(updateIndexPageController);
    } else {
      tabIndex = widget.tabController.index;
      activeScrollController = widget.controllers[tabIndex];
      widget.tabController.addListener(updateIndexTabController);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    double oldHeight = windowHeight;
    windowHeight = MediaQuery.of(context).size.height;
    if (windowHeight == 0 || oldHeight == windowHeight)
      return; // Don't need to run the code below
    if (widget.headerHeight != null) {
      headerHeight = widget.headerHeight;
      initialValue = 1 - headerHeight / windowHeight;
      animationController.value = initialValue;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((duration) {
        setState(() {
          headerHeight = headerKey.currentContext.size.height;
          initialValue = 1 - headerHeight / windowHeight;
          animationController.value = initialValue;
        });
      });
    }
  }

  @override
  void didUpdateWidget(CustomBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllers != widget.controllers) {
      if (widget.tabController == null && widget.pageController == null) {
        activeScrollController = widget.controllers[0];
      } else if (widget.pageController != null) {
        tabIndex = widget.pageController.hasClients
            ? widget.pageController.page.round()
            : widget.pageController.initialPage;
        // TODO: solve range error where the current page user is on is removed
        if (tabIndex >= widget.controllers.length)
          tabIndex = widget.controllers.length - 1;
        activeScrollController = widget.controllers[tabIndex];
      } else {
        tabIndex = widget.tabController.index;
        activeScrollController = widget.controllers[tabIndex];
      }
    }
    if (oldWidget.pageController != null && widget.pageController == null)
      oldWidget.pageController.removeListener(updateIndexPageController);
    if (oldWidget.tabController != null && widget.tabController == null)
      oldWidget.tabController.removeListener(updateIndexTabController);
    if (widget.headerHeight != null &&
        oldWidget.headerHeight != widget.headerHeight) {
      double oldIntialValue = initialValue;
      headerHeight = widget.headerHeight;
      initialValue = 1 - headerHeight / windowHeight;
      if (animationController.value >= oldIntialValue ||
          animationController.value >= initialValue)
        animationController.animateBack(initialValue,
            duration: widget.headerHeightTransitionDuration,
            curve: widget.headerHeightTransitionCurve);
    } else if (widget.headerHeight == null &&
        (oldWidget.headerHeight != null ||
            oldWidget.headerBuilder != widget.headerBuilder)) {
      double oldIntialValue = initialValue;
      WidgetsBinding.instance.addPostFrameCallback((duration) {
        setState(() {
          headerHeight = headerKey.currentContext.size.height;
          initialValue = 1 - headerHeight / windowHeight;
          if (animationController.value == oldIntialValue)
            animationController.animateTo(initialValue,
                duration: widget.headerHeightTransitionDuration,
                curve: widget.headerHeightTransitionCurve);
        });
      });
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(updateIndexPageController);
    widget.tabController.removeListener(updateIndexTabController);
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Modified animation values as shown at the top. Values can be negative (representing the overscroll pulling the sheet down), but cannot go over 1 (when sheet is fully expanded).
    Animation<double> animation = Tween<double>(
      begin: 1,
      end: 1 - 1 / (initialValue ?? 1),
    ).animate(animationController);
    Animation<Offset> offsetAnimation = Tween<Offset>(
      begin: Offset(0, 0), // sheet is fully expanded
      end: Offset(0, 1),
    ).animate(animationController);
    SlideTransition slideTransition = SlideTransition(
      position: offsetAnimation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          Animation<ShapeBorder> shapeAnimation = ShapeBorderTween(
            begin: widget.shape,
            end: const ContinuousRectangleBorder(),
          ).animate(animation);
          return Container(
            decoration: BoxDecoration(
              boxShadow: kElevationToShadow[6],
            ),
            child: PhysicalShape(
              color: widget.color ?? Theme.of(context).canvasColor,
              clipper: ShapeBorderClipper(
                shape:
                    animation.value < 0 ? widget.shape : shapeAnimation.value,
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          );
        },
        child: SizedBox(
          height: windowHeight,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: <Widget>[
              NotificationListener(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.depth == 1) {
                    if (notification.metrics.pixels <= 5 &&
                        innerBoxIsScrolled.value == true) {
                      innerBoxIsScrolled.value = false;
                    } else if (notification.metrics.pixels > 5 &&
                        innerBoxIsScrolled.value == false)
                      innerBoxIsScrolled.value = true;
                  }
                  return null;
                },
                child: Positioned.fill(
                  child: widget.contentBuilder(context, animation),
                ),
              ),
              SizedBox(
                key: headerKey,
                child: widget.headerBuilder(
                    context, animation, viewSheet, innerBoxIsScrolled),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.swipeArea == SwipeArea.entireScreen) {
      return GestureDetector(
        onVerticalDragDown: dragDown,
        onVerticalDragStart: dragStart,
        onVerticalDragUpdate: dragUpdate,
        onVerticalDragEnd: dragEnd,
        onVerticalDragCancel: dragCancel,
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            if (widget.backgroundContentBuilder != null)
              widget.backgroundContentBuilder(
                  context, animationController.view, animation),
            slideTransition,
          ],
        ),
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        if (widget.backgroundContentBuilder != null)
          widget.backgroundContentBuilder(
              context, animationController.view, animation),
        GestureDetector(
          onVerticalDragDown: dragDown,
          onVerticalDragStart: dragStart,
          onVerticalDragUpdate: dragUpdate,
          onVerticalDragEnd: dragEnd,
          onVerticalDragCancel: dragCancel,
          child: slideTransition,
        ),
      ],
    );
  }
}
