import '../../library.dart';

class CustomBottomSheet extends StatefulWidget {
  final BottomSheetPosition initialPosition;
  final BottomSheetController controller;
  final WidgetBuilder body;
  final WidgetBuilder footer;
  final WidgetBuilder background;
  final ShapeBorder shape;
  final Color color;
  CustomBottomSheet({
    this.initialPosition = BottomSheetPosition.end,
    @required this.controller,
    @required this.body,
    this.footer,
    this.background,
    this.color,
    this.shape: const ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
    ),
    Key key,
  }) : super(key: key);

  _CustomBottomSheetState createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet>
    with SingleTickerProviderStateMixin {
  /// Default spring used in spring simulations
  static final SpringDescription spring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100,
    ratio: 1.1,
  );

  /// Height of window, as given by [MediaQuery]
  double _windowHeight;

  /// Main [AnimationController]
  AnimationController _animationController;

  Drag _scrollDrag;
  ScrollHoldController _scrollHold;

  /// Whether bottom sheet is at or going to be at [BottomSheetPosition.hidden]
  bool _isHidden = false;

  /// Whether the inner scroll view within the bottom sheet is scrolling
  bool _isScrolling = false;
  LocalHistoryEntry _localHistoryEntry;
  bool _localHistoryEntryAdded = false;

  /// Whether to call the [LocalHistoryEntry]'s onRemove method.
  bool _callLocalHistoryOnRemove = true;

  /// Timer used to correctly account for seamless scrolling between bottom sheet and inner scroll view
  Timer _scrollTimer;

  @override
  void initState() {
    super.initState();
    _localHistoryEntry = LocalHistoryEntry(
      onRemove: _onLocalHistoryRemove,
    );
    _animationController = AnimationController(
      vsync: this,
      value: 1, // Fully expanded by default
    );
    switch (widget.controller.initialPosition) {
      case BottomSheetPosition.start:
        _animationController.value = widget.controller.start;
        break;
      case BottomSheetPosition.end:
        _animationController.value = widget.controller.end;
        break;
      case BottomSheetPosition.hidden:
        _animationController.value = 1;
        _isHidden = true;
        break;
    }
    // range = widget.controller.end - widget.controller.start;
    // gradient = 1 / (widget.controller.start - widget.controller.end);
    // y = 1 / (widget.controller.start - widget.controller.end) * (x - widget.controller.end);
    // Sub x = 0 or x = 1
    widget.controller.altAnimation = Tween<double>(
      begin: widget.controller.end /
          (widget.controller.end - widget.controller.start),
      end: (1 - widget.controller.end) /
          (widget.controller.start - widget.controller.end),
    ).animate(_animationController);
    widget.controller
      ..animation = _animationController.view
      ..animateTo = _animateTo;
  }

  // For overscroll on the bottom sheet
  double _frictionFactor(double overscrollFraction) {
    return 0.52 * pow(1 - overscrollFraction, 2);
  }

  /// Check if the [ScrollController] supplied by the [BottomSheetNotifier] is legit & scrollable
  bool _isScrollable(ScrollController controller) {
    return controller != null && controller.hasClients;
  }

  void _animateTo(BottomSheetPosition position) {
    if (position == BottomSheetPosition.hidden) {
      _isHidden = true;
      _animationController.animateTo(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInCubic,
      );
    } else {
      _isHidden = false;
      final simulation = ScrollSpringSimulation(
        spring,
        _animationController.value,
        position == BottomSheetPosition.start
            ? widget.controller.start
            : widget.controller.end,
        0,
      );
      _animationController.animateWith(simulation);
    }
    _handleLocalHistory(position, false);
  }

  void _handleLocalHistory(
    BottomSheetPosition position, [
    bool callOnRemove = true,
  ]) {
    if (widget.controller.seamlessScrolling) return;
    if (position == BottomSheetPosition.start) {
      if (!_localHistoryEntryAdded) {
        ModalRoute.of(context).addLocalHistoryEntry(_localHistoryEntry);
        _localHistoryEntryAdded = true;
      }
    } else if (_localHistoryEntryAdded) {
      _callLocalHistoryOnRemove = callOnRemove;
      ModalRoute.of(context).removeLocalHistoryEntry(_localHistoryEntry);
    }
  }

  void _onLocalHistoryRemove() {
    _localHistoryEntryAdded = false;
    if (!_callLocalHistoryOnRemove) {
      _callLocalHistoryOnRemove = true;
      return;
    }
    _animationController.animateWith(
      ScrollSpringSimulation(
        spring,
        _animationController.value,
        widget.controller.end,
        0,
      ),
    );
  }

  // User has touched the screen and may begin to drag
  void dragDown(DragDownDetails details) {
    if (_isHidden) return;
    final controller = widget.controller.activeScrollController;

    // This line here is to stop the bottom sheet from moving and hold it in place should the user tap on the bottom sheet again while it is shifting
    if (_animationController.isAnimating) {
      _animationController.value = _animationController.value;
    }

    // Cancel any timers that will move the bottom sheet
    _scrollTimer?.cancel();

    if (_isScrollable(controller)) {
      // simulate a hold on the [SingleChildScrollView]
      // I don't really know if this is needed, but it is best to mimic and simulate actual scrolling on the [SingleChildScrollView] as close as possible, and that includes holding
      _scrollHold = controller.position.hold(_removeHold);
    }
  }

  // user has just started to drag
  void dragStart(DragStartDetails details) {
    if (_isHidden) return;
    final controller = widget.controller.activeScrollController;
    // Check if the [SingleChildScrollView] is scrollable in the first place
    if (_isScrollable(controller) && _animationController.value == 0) {
      // simulate a scroll on the [SingleChildScrollView]
      _scrollDrag = controller.position.drag(details, _removeDrag);
    }
  }

  // user is in the process of dragging
  void dragUpdate(DragUpdateDetails details) {
    if (_isHidden) return;
    final controller = widget.controller.activeScrollController;
    // Scrolling the inner scroll view
    if (_isScrollable(controller) &&
        _animationController.value == 0 &&
        (details.primaryDelta < 0 || controller.offset > 0)) {
      if (_scrollDrag == null) {
        _scrollDrag = controller.position.drag(
          DragStartDetails(
            sourceTimeStamp: details.sourceTimeStamp,
            globalPosition: details.globalPosition,
          ),
          _removeDrag,
        );
      }
      _isScrolling = true;
      // Pass on the dragging onto the inner scroll view
      _scrollDrag.update(details);
    } else {
      // Dragging the outer bottom sheet
      cancelScrollDragHold();
      _isScrolling = false;
      double delta = details.primaryDelta / _windowHeight;
      final range = widget.controller.end - widget.controller.start;
      if (_animationController.value > widget.controller.end) {
        delta *= _frictionFactor(
            (_animationController.value - widget.controller.end) /
                (1 - widget.controller.end));
      } else {
        delta *=
            range / (range - widget.controller.endCorrection / _windowHeight);
      }
      _animationController.value += delta;
    }
  }

  // user has finished dragging
  void dragEnd(DragEndDetails details) {
    if (_isHidden) return;
    double velocity = details.primaryVelocity;
    if (velocity == 0) {
      if (_isScrolling) {
        _isScrolling = false;
        _scrollDrag?.end(details);
        return;
      }
      final midpoint = (widget.controller.start + widget.controller.end) / 2;
      _animateTo(_animationController.value > midpoint
          ? BottomSheetPosition.end
          : BottomSheetPosition.start);
    } else if (_isScrolling) {
      _isScrolling = false;
      final controller = widget.controller.activeScrollController;
      if (!widget.controller.seamlessScrolling ||
          controller.offset > controller.position.maxScrollExtent) {
        // Scroll offset exceeds the max scroll extent, so no need to go further, as default behavior of [BouncingScrollPhysics] is to do a [SpringSimulation] back to maxScrollExtent, without going to zero offset.
        _scrollDrag?.end(details);
        return;
      }
      // https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/widgets/scroll_physics.dart
      final scrollingSimulation = FrictionSimulation(
        0.135,
        controller.offset,
        -velocity * 0.91,
      );
      // Time at which the the scroll reaches the top, i.e. zero offset
      final simulationEndTime = scrollingSimulation.timeAtX(0);
      _scrollDrag?.end(details);
      // Scrolling does reach the top
      if (simulationEndTime != double.infinity) {
        final endVelocity =
            scrollingSimulation.dx(simulationEndTime) / _windowHeight;
        final durationInMicroseconds =
            (simulationEndTime * Duration.microsecondsPerSecond).toInt();
        // Start a perfectly timed timer that will animate the bottom sheet the moment the inner scroll view reaches the top.
        _scrollTimer = Timer(
          Duration(microseconds: durationInMicroseconds),
          () {
            controller.jumpTo(0);
            Simulation simulation = BouncingScrollSimulation(
              spring: spring,
              leadingExtent: widget.controller.start,
              position: 0,
              trailingExtent: widget.controller.end,
              velocity: -endVelocity,
            );
            _animationController.animateWith(simulation);
            _scrollTimer = null;
          },
        );
      }
    } else {
      /// Whether the gesture is so drastic that the inner scroll view also has to scroll for seamless scrolling
      bool overscroll = false;
      Simulation simulation;
      if (widget.controller.seamlessScrolling) {
        simulation = FrictionSimulation(
          0.135,
          _animationController.value,
          velocity / _windowHeight,
        );
        // If bottom sheet gets fully expanded, i.e. its animation goes to 0
        overscroll = simulation.x(double.infinity) < 0;
      }
      if (overscroll) {
        final simulationEndTime = (simulation as FrictionSimulation).timeAtX(0);
        double endVelocity = simulation.dx(simulationEndTime);
        _scrollTimer = Timer(
          Duration(
              microseconds:
                  (simulationEndTime * Duration.microsecondsPerSecond).toInt()),
          () {
            final controller = widget.controller.activeScrollController;
            _scrollDrag =
                controller.position.drag(DragStartDetails(), _removeDrag);
            _scrollDrag.end(DragEndDetails(
              velocity: Velocity(
                pixelsPerSecond: Offset(0, endVelocity * _windowHeight),
              ),
              primaryVelocity: endVelocity * _windowHeight,
            ));
            _scrollDrag = null;
            _scrollTimer = null;
          },
        );
      } else if (velocity > 0) {
        simulation = ScrollSpringSimulation(
          spring,
          _animationController.value,
          widget.controller.end,
          _animationController.value > widget.controller.end
              ? 0
              : velocity / _windowHeight,
        );
        _handleLocalHistory(BottomSheetPosition.end);
      } else {
        simulation = ScrollSpringSimulation(
          spring,
          _animationController.value,
          widget.controller.start,
          _animationController.value > widget.controller.end
              ? 0
              : velocity / _windowHeight,
        );
        _handleLocalHistory(BottomSheetPosition.start);
      }
      _animationController.animateWith(simulation);
    }
  }

  // something unexpected happened that cause user to suddenly stopped dragging
  // e.g. random popup or dialog
  void dragCancel() {
    cancelScrollDragHold();
    dragEnd(DragEndDetails(primaryVelocity: 0));
  }

  void _removeHold() {
    _scrollHold = null;
  }

  void _removeDrag() {
    _scrollDrag = null;
  }

  void cancelScrollDragHold() {
    _scrollHold?.cancel();
    _scrollDrag?.cancel();
    _removeHold();
    _removeDrag();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _windowHeight = MediaQuery.of(context).size.height;
  }

  @override
  void didUpdateWidget(CustomBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      switch (widget.controller.initialPosition) {
        case BottomSheetPosition.start:
          _animationController.value = widget.controller.start;
          _isHidden = false;
          break;
        case BottomSheetPosition.end:
          _animationController.value = widget.controller.end;
          _isHidden = false;
          break;
        case BottomSheetPosition.hidden:
          _animationController.value = 1;
          _isHidden = true;
          break;
      }
      // range = widget.controller.end - widget.controller.start;
      // gradient = 1 / (widget.controller.start - widget.controller.end);
      // y = 1 / (widget.controller.start - widget.controller.end) * (x - widget.controller.end);
      // Sub x = 0 or x = 1
      widget.controller.altAnimation = Tween<double>(
        begin: widget.controller.end /
            (widget.controller.end - widget.controller.start),
        end: (1 - widget.controller.end) /
            (widget.controller.start - widget.controller.end),
      ).animate(_animationController);
      widget.controller
        ..animation = _animationController.view
        ..animateTo = _animateTo;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Animation<Offset> offsetAnimation = Tween<Offset>(
      begin: Offset(0, 0), // sheet is fully expanded
      end: Offset(0, 1),
    ).animate(_animationController);
    final child = Stack(
      children: <Widget>[
        SlideTransition(
          position: offsetAnimation,
          child: ValueListenableBuilder(
            valueListenable: widget.controller.altAnimation,
            builder: (context, value, child) {
              final shapeTween = ShapeBorderTween(
                begin: widget.shape,
                end: const ContinuousRectangleBorder(),
              );
              return Container(
                decoration: BoxDecoration(
                  boxShadow: kElevationToShadow[6],
                ),
                child: PhysicalShape(
                  color: widget.color ?? Theme.of(context).canvasColor,
                  clipper: ShapeBorderClipper(
                    shape: shapeTween.transform(value.clamp(0.0, 1.0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
              );
            },
            child: SizedBox(
              height: _windowHeight,
              width: MediaQuery.of(context).size.width,
              child: NotificationListener(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification &&
                      notification.depth == 1) {
                    widget.controller.isScrolled.value =
                        notification.metrics.pixels > 5;
                  }
                  return null;
                },
                child: widget.body(context),
              ),
            ),
          ),
        ),
        if (widget.footer != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: widget.footer(context),
          ),
      ],
    );
    if (widget.controller.swipeArea == SwipeArea.entireScreen) {
      return GestureDetector(
        onVerticalDragDown: dragDown,
        onVerticalDragStart: dragStart,
        onVerticalDragUpdate: dragUpdate,
        onVerticalDragEnd: dragEnd,
        onVerticalDragCancel: dragCancel,
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            if (widget.background != null) widget.background(context),
            child,
          ],
        ),
      );
    }
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        if (widget.background != null) widget.background(context),
        GestureDetector(
          onVerticalDragDown: dragDown,
          onVerticalDragStart: dragStart,
          onVerticalDragUpdate: dragUpdate,
          onVerticalDragEnd: dragEnd,
          onVerticalDragCancel: dragCancel,
          child: child,
        ),
      ],
    );
  }
}

enum BottomSheetPosition {
  /// Bottom sheet is expanded and is at its start value
  start,

  /// Bottom sheet is at its end value
  end,

  /// Bottom sheet is fully collapsed and hidden
  hidden,
}

enum SwipeArea { entireScreen, bottomSheet }

/// Use this to get the animations of the bottom sheet, and to change the active scroll controller should the inner scroll view change, with many other customisation settings
class BottomSheetController extends ChangeNotifier {
  BottomSheetController({
    this.activeScrollController,
    this.initialPosition = BottomSheetPosition.end,
    this.endCorrection = 0,
    double start = 0,
    @required double end,
    SwipeArea swipeArea = SwipeArea.bottomSheet,
    this.seamlessScrolling = false,
  })  : _start = start,
        _end = end,
        _swipeArea = swipeArea;

  /// Default bottom sheet animation, that goes from 0 to 1.
  ///
  /// 0: Fully expanded bottom sheet, filling up entire window
  ///
  /// 1: Fully collapsed bottom sheet, below the visible window
  Animation<double> animation;

  /// Alternative bottom sheet animation.
  ///
  /// 0: Bottom sheet position is at [BottomSheetPosition.end]
  ///
  /// 1: Bottom sheet position is at [BottomSheetPosition.start]
  ValueListenable<double> altAnimation;

  /// animateTo function for bottom sheet. Animates the bottom sheet to the start value (fully expanded) or to the end value (semi collapsed height), or to the hidden value (fully collapsed height)
  void Function(BottomSheetPosition) animateTo;

  /// Current active scroll controller that the bottom sheet uses. Change this to match the new scroll controller in the bottom sheet body when the content changes, so the scroll gestures will still function.
  ScrollController activeScrollController;

  /// Whether the inner scroll view is scrolled such that its offset > 5
  ValueNotifier<bool> isScrolled = ValueNotifier(false);

  /// Initial position of the bottom sheet. Used only when initially building the bottom sheet.
  BottomSheetPosition initialPosition;

  /// A value of 0 indicates that the bottom sheet should move together with the finger.
  ///
  /// A non-zero value indicates that the bottom sheet should at a different speed to the finger, and the amount indicates the amount of pixels the bottom sheet will move over the course of moving from the end position to the start position.
  ///
  /// A positive value indicates that the bottom sheet should move faster than the finger, while a negative one means that is should move slower.
  ///
  /// This is more commonly used to account for the MediaQuery's top padding, in which the end correction is equivalent to that.
  double endCorrection;

  /// Start value. Must be between 0 and 1.
  double get start => _start;
  double _start;

  /// End value. Must be between 0 and 1.
  double get end => _end;
  double _end;

  /// Set start and end values. Must be between 0 and 1.
  void setPositions({@required double start, @required double end}) {
    if (start == _start && end == _end) return;
    assert(0 <= start && start <= end && end <= 1);
    _start = start;
    _end = end;
    notifyListeners();
  }

  /// Area where user can swipe to drag the bottom sheet
  SwipeArea get swipeArea => _swipeArea;
  SwipeArea _swipeArea;
  set swipeArea(SwipeArea swipeArea) {
    if (swipeArea == _swipeArea) return;
    _swipeArea = swipeArea;
    notifyListeners();
  }

  /// Whether the scrolling of the bottom sheet, and the inner
  /// scroll view should be combined when user finishes dragging
  bool seamlessScrolling;
}
