import 'package:flutter/material.dart';

class CustomTabBar extends StatefulWidget {
  final ValueNotifier<double> offsetNotifier;
  final PageController pageController;
  final List<String> tabs;
  CustomTabBar(
      {Key key,
      @required this.pageController,
      @required this.tabs,
      @required this.offsetNotifier})
      : super(key: key);

  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  final ScrollController _scrollController = ScrollController();
  double _windowWidth;
  List<GlobalKey> _tabKeys;
  List<double> _tabWidths = [];
  List<double> _indicatorPositions = [];
  List<double> _scrollPositions = [];
  double _frontPadding = 0;
  double _backPadding = 0;
  double _previousOffset = 0;
  bool isListening = true;

  double lerpDouble(num a, num b, double t) {
    return a + (b - a) * t;
  }

  double getIndicatorPosition(double pageOffset) {
    if (pageOffset.isNegative) return 0;
    final int _leftPageIndex = pageOffset.floor();
    return lerpDouble(_indicatorPositions[_leftPageIndex],
        _indicatorPositions[_leftPageIndex + 1], pageOffset - _leftPageIndex);
  }

  double getIndicatorWidth(double pageOffset) {
    if (pageOffset.isNegative) {
      if (pageOffset < -1) return 0;
      return _tabWidths.first + pageOffset * _tabWidths.first;
    }
    final int _leftPageIndex = pageOffset.floor();
    final int _rightPageIndex = _leftPageIndex + 1;
    if (_rightPageIndex >= _tabWidths.length)
      return _tabWidths.last - (pageOffset - _leftPageIndex) * _tabWidths.last;
    return lerpDouble(_tabWidths[_leftPageIndex], _tabWidths[_rightPageIndex],
        pageOffset - _leftPageIndex);
  }

  double getScrollPosition(double pageOffset) {
    if (pageOffset.isNegative) return 0;
    final int _leftPageIndex = pageOffset.floor();
    if (_leftPageIndex >= _scrollPositions.length - 1)
      return _scrollController.position.maxScrollExtent;
    return lerpDouble(_scrollPositions[_leftPageIndex],
        _scrollPositions[_leftPageIndex + 1], pageOffset - _leftPageIndex);
  }

  void updateScrollPosition() {
    double targetOffset =
        getScrollPosition(widget.offsetNotifier.value / _windowWidth);
    if (targetOffset > _scrollController.position.maxScrollExtent)
      targetOffset = _scrollController.position.maxScrollExtent;
    final double currentOffset = _scrollController.offset;
    if (!isListening) {
      _previousOffset = targetOffset;
      return;
    }
    if (_previousOffset != currentOffset) {
      final double newOffset = lerpDouble(targetOffset, currentOffset, 0.9);
      _scrollController.jumpTo(newOffset);
      _previousOffset = targetOffset;
      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 100),
        curve: Curves.ease,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
      _previousOffset = targetOffset;
    }
  }

  void updateValues() {
    if (_tabWidths.length == 0) return;
    _frontPadding = (_windowWidth - _tabWidths.first) / 2;
    _backPadding = (_windowWidth - _tabWidths.last) / 2;
    _scrollPositions = [];
    _indicatorPositions = [];
    double indicatorPosition = 0;
    double scrollPosition = 0;
    _tabWidths.forEach((width) {
      if (scrollPosition != 0) scrollPosition += width / 2;
      _scrollPositions.add(scrollPosition);
      _indicatorPositions.add(indicatorPosition);
      indicatorPosition += width;
      scrollPosition += width / 2;
    });
    _indicatorPositions.add(_indicatorPositions.last +
        _tabWidths.last); // Extra value for overscroll on the last page
  }

  @override
  void initState() {
    super.initState();
    _tabKeys = [for (var _ in widget.tabs) GlobalKey()];
    WidgetsBinding.instance.addPostFrameCallback((duration) {
      setState(() {
        _tabKeys.forEach((key) {
          _tabWidths.add(key.currentContext.size.width);
        });
        updateValues();
      });
    });
    widget.offsetNotifier.addListener(updateScrollPosition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _windowWidth = MediaQuery.of(context).size.width;
    updateValues();
  }

  @override
  void didUpdateWidget(CustomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs != widget.tabs) {
      _tabKeys = [for (var _ in widget.tabs) GlobalKey()];
      _tabWidths = [];
      WidgetsBinding.instance.addPostFrameCallback((duration) {
        setState(() {
          _tabKeys.forEach((key) {
            _tabWidths.add(key.currentContext.size.width);
          });
          updateValues();
        });
      });
    }
  }

  @override
  void dispose() {
    widget.offsetNotifier.removeListener(updateScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(left: _frontPadding, right: _backPadding),
        scrollDirection: Axis.horizontal,
        child: Stack(
          children: <Widget>[
            if (_tabWidths.length > 0)
              Align(
                alignment: Alignment.bottomLeft,
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.offsetNotifier,
                  builder: (context, value, child) {
                    if (value.isNaN) return const SizedBox();
                    return Transform.translate(
                      offset:
                          Offset(getIndicatorPosition(value / _windowWidth), 0),
                      child: PhysicalShape(
                        color: Theme.of(context).colorScheme.onSurface,
                        clipper: ShapeBorderClipper(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 2,
                          width: getIndicatorWidth(value / _windowWidth),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < widget.tabs.length; i++)
                  InkWell(
                    key: _tabKeys[i],
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      height: 56,
                      alignment: Alignment.center,
                      child: Text(widget.tabs[i]),
                    ),
                    onTap: () {
                      isListening = false;
                      _scrollController.animateTo(
                        getScrollPosition(i.toDouble()),
                        duration: Duration(milliseconds: 400),
                        curve: Curves.fastOutSlowIn,
                      );
                      widget.pageController
                          .animateToPage(
                        i,
                        duration: Duration(milliseconds: 400),
                        curve: Curves.fastOutSlowIn,
                      )
                          .then((_) {
                        isListening = true;
                        updateScrollPosition();
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
