import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'stall_data.dart';
import 'order_data.dart';
import 'images/transparent_image.dart';
import 'images/error_image.dart';
import 'firebase/firebase.dart';

class Stall extends StatefulWidget {
  final String name;
  final Animation<double> animation;
  final ScrollController scrollController;
  const Stall({
    Key key,
    @required this.name,
    @required this.animation,
    @required this.scrollController,
  }) : super(key: key);

  @override
  _StallState createState() => _StallState();
}

class _StallState extends State<Stall> {
  @override
  Widget build(BuildContext context) {
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: widget.animation,
            builder: (context, child) {
              return SizedBox(
                height: widget.animation.value.clamp(0.0, double.infinity) *
                    windowPadding.top,
              );
            },
          ),
          StallQueue(
            stallName: widget.name,
            padding: const EdgeInsets.fromLTRB(0, 80, 0, 16),
          ),
          ProxyProvider<List<StallData>, List<MenuItem>>(
            builder: (context, stallDataList, menuItemList) {
              return stallDataList
                  .firstWhere((stallData) => stallData.name == widget.name)
                  .menu;
            },
            updateShouldNotify: (list1, list2) {
              if (list1?.length != list2?.length) return true;
              int i = -1;
              // Checking if every item in list is equivalent. Normal '==' operator does not work for lists
              return !list1.every((item) {
                i++;
                return item.name == list2[i].name &&
                    item.image == list2[i].image &&
                    item.available == list2[i].available &&
                    item.price == list2[i].price;
              });
            },
            child: Consumer<List<MenuItem>>(
              builder: (context, menuList, child) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 72.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: <Widget>[
                      for (var item in menuList)
                        FoodItem(
                          stallName: widget.name,
                          menuItem: item,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StallQueue extends StatelessWidget {
  final String stallName;
  final EdgeInsetsGeometry padding;
  const StallQueue({
    @required this.stallName,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });
  @override
  Widget build(BuildContext context) {
    return ProxyProvider<List<StallData>, int>(
      builder: (context, stallDataList, queue) {
        return stallDataList
            .firstWhere((stallData) => stallData.name == stallName,
                orElse: () => null)
            ?.queue;
      },
      child: Material(
        child: Padding(
          padding: padding,
          child: Consumer<int>(
            builder: (context, queue, child) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        if (queue != null) {
                          FirebaseDatabase.instance
                              .reference()
                              .child('stalls/${stallName.toLowerCase()}/queue')
                              .set(queue + 1);
                        }
                      },
                      customBorder: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.accessibility,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Container(
                              alignment: Alignment.center,
                              constraints: BoxConstraints(
                                minWidth: queue != null && queue > 99 ? 27 : 18,
                              ),
                              child: AnimatedSwitcher(
                                switchOutCurve:
                                    Interval(0.5, 1, curve: Curves.easeIn),
                                switchInCurve:
                                    Interval(0.5, 1, curve: Curves.easeOut),
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  queue?.toString() ?? '',
                                  key: ValueKey<int>(queue),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            const Text('people'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: InkWell(
                        onTap: () {
                          if (queue != null && queue > 0) {
                            FirebaseDatabase.instance
                                .reference()
                                .child(
                                    'stalls/${stallName.toLowerCase()}/queue')
                                .set(queue - 1);
                          }
                        },
                        customBorder: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.access_time,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Container(
                                alignment: Alignment.center,
                                constraints: BoxConstraints(
                                  minWidth: queue != null && queue ~/ 1.5 > 99
                                      ? 27
                                      : 18,
                                ),
                                child: AnimatedSwitcher(
                                  switchOutCurve:
                                      Interval(0.5, 1, curve: Curves.easeIn),
                                  switchInCurve:
                                      Interval(0.5, 1, curve: Curves.easeOut),
                                  duration: Duration(milliseconds: 300),
                                  child: Text(
                                    queue != null ? '${queue ~/ 1.5}' : '',
                                    key: ValueKey<int>(queue),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text('mins'),
                            ],
                          ),
                        ),
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

class StallImage extends StatefulWidget {
  final String stallName;
  final int index;
  final ValueNotifier<double> offsetNotifier;
  final Animation<double> defaultAnimation; // From CustomButtomSheet
  final Animation<double> animation;
  final PageController pageController;
  final bool last;
  const StallImage({
    Key key,
    @required this.stallName,
    @required this.index,
    @required this.offsetNotifier,
    @required this.defaultAnimation,
    @required this.animation,
    @required this.pageController,
    this.last: false,
  }) : super(key: key);

  @override
  _StallImageState createState() => _StallImageState();
}

class _StallImageState extends State<StallImage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        double height;
        double y = 0;
        if (widget.animation.value < 0)
          height = widget.defaultAnimation.value *
                  MediaQuery.of(context).size.height +
              32;
        else {
          final double width = MediaQuery.of(context).size.width;
          height = width / 2560 * 1600 + 32;
          y = widget.animation.value * -(width / 2560 * 1600 + 32) / 2;
        }
        return Transform.translate(
          offset: Offset(0, y),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: height,
              child: child,
            ),
          ),
        );
      },
      child: ValueListenableBuilder<double>(
        valueListenable: widget.offsetNotifier,
        builder: (context, value, child) {
          final double width = MediaQuery.of(context).size.width;
          double imageOffset = (value / width - widget.index).clamp(-1, 1) / 2;
          bool clipping = true;
          double scale = 1;
          Alignment alignment = Alignment.centerLeft;
          if (widget.index == 0 && imageOffset < 0) {
            clipping = false;
            scale -= imageOffset;
          } else if (widget.last && imageOffset > 0) {
            clipping = false;
            alignment = Alignment.centerRight;
            scale += imageOffset;
          }
          return Material(
            type: MaterialType.transparency,
            clipBehavior: clipping ? Clip.hardEdge : Clip.none,
            child: Transform.translate(
              offset: Offset(imageOffset * width * (clipping ? 1 : 2), 0),
              child: Transform.scale(
                scale: scale,
                alignment: alignment,
                child: child,
              ),
            ),
          );
        },
        child: OverflowBox(
          minWidth: MediaQuery.of(context).size.width,
          maxWidth: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
            ),
            child: FadeInImage(
              fadeInDuration: Duration(milliseconds: 400),
              placeholder: MemoryImage(kTransparentImage),
              image: FirebaseImage(
                Provider.of<List<StallNameAndImage>>(context)
                    .firstWhere((s) => s.name == widget.stallName)
                    .image,
                fallbackMemoryImage: kErrorLandscapeImage,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class FoodItem extends StatefulWidget {
  final String stallName;
  final MenuItem menuItem;
  FoodItem({
    Key key,
    @required this.stallName,
    @required this.menuItem,
  }) : super(key: key);
  _FoodItemState createState() => _FoodItemState();
}

class _FoodItemState extends State<FoodItem>
    with AutomaticKeepAliveClientMixin {
  double shadow = 0;
  void Function(Order order) addOrder;
  void Function(Order order) removeOrder;
  Order order;

  @override
  void initState() {
    super.initState();
    order = Order(stallName: widget.stallName, menuItem: widget.menuItem);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 8.0 * 3) / 2;
    return ProxyProvider<OrderNotifier, bool>(
      initialBuilder: (context) => false,
      builder: (context, orderNotifier, isOrdered) {
        final List<Order> orders = orderNotifier.orders;
        addOrder = orderNotifier.addOrder;
        removeOrder = orderNotifier.removeOrder;
        if (orders.isEmpty) return false;
        return !orders.every((order) {
          return order.stallName != widget.stallName ||
              order.menuItem != widget.menuItem;
        });
      },
      dispose: (context, isOrdered) => isOrdered = false,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 6.0,
        ),
        child: Column(
          children: <Widget>[
            Stack(
              fit: StackFit.passthrough,
              children: <Widget>[
                Material(
                  color: Theme.of(context).dividerColor,
                  elevation: shadow,
                  shadowColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.yellowAccent
                      : Colors.black,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FadeInImage(
                    fadeInDuration: const Duration(milliseconds: 300),
                    placeholder: MemoryImage(kTransparentImage),
                    image: FirebaseImage(widget.menuItem.image,
                        fallbackMemoryImage: kErrorImage),
                    height: cardWidth,
                    width: cardWidth,
                  ),
                ),
                Consumer<bool>(
                  builder: (context, isOrdered, child) {
                    return Stack(
                      fit: StackFit.passthrough,
                      children: <Widget>[
                        AnimatedFade(
                          opacity: isOrdered ? 1 : 0,
                          child: ClipPath(
                            clipper: ShapeBorderClipper(
                              shape: ContinuousRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              width: cardWidth,
                              height: cardWidth,
                              child: Icon(
                                Icons.done,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              if (isOrdered)
                                removeOrder(order);
                              else
                                addOrder(order);
                              setState(() => shadow = 0);
                            },
                            onTapDown: (_) {
                              setState(() => shadow = 8);
                            },
                            onTapCancel: () {
                              setState(() => shadow = 0);
                            },
                            child: SizedBox(
                              width: cardWidth,
                              height: cardWidth,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            SizedBox(
              height: 6.0,
            ),
            Text(widget.menuItem.name),
            Text(
              '\$${widget.menuItem.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.subtitle,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class AnimatedFade extends ImplicitlyAnimatedWidget {
  final double opacity;
  final Widget child;

  AnimatedFade({
    @required this.opacity,
    @required this.child,
    Duration duration: const Duration(milliseconds: 200),
    Curve curve: Curves.ease,
    Key key,
  }) : super(duration: duration, curve: curve, key: key);
  @override
  _AnimatedFadeState createState() => _AnimatedFadeState();
}

class _AnimatedFadeState extends AnimatedWidgetBaseState<AnimatedFade> {
  Tween<double> _opacityTween;

  @override
  void forEachTween(visitor) {
    _opacityTween = visitor(
        _opacityTween, widget.opacity, (value) => Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityTween.animate(animation),
      child: widget.child,
    );
  }
}
