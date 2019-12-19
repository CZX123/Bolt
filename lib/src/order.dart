import '../library.dart';

class OrderScreen extends StatefulWidget {
  OrderScreen({Key key}) : super(key: key);

  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final windowPadding = Provider.of<EdgeInsets>(context);
    final orderSheetController = Provider.of<BottomSheetController>(context);
    orderSheetController.activeScrollController = scrollController;
    return CustomBottomSheet(
      color: Theme.of(context).cardColor,
      controller: orderSheetController,
      body: (context) {
        return Stack(
          children: <Widget>[
            SingleChildScrollView(
              controller: scrollController,
              physics: NeverScrollableScrollPhysics(),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: -0.25,
                  end: 1.5,
                ).animate(orderSheetController.altAnimation),
                child: Column(
                  children: <Widget>[
                    ValueListenableBuilder(
                      valueListenable: orderSheetController.altAnimation,
                      builder: (context, value, child) {
                        return SizedBox(
                          height:
                              value.clamp(0.0, 1.0) * (windowPadding.top - 20) +
                                  20,
                        );
                      },
                    ),
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            windowPadding.top -
                            windowPadding.bottom,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: ListOfOrders(),
                    ),
                    SizedBox(
                      height: windowPadding.bottom,
                    ),
                  ],
                ),
              ),
            ),
            OrderPreview(),
          ],
        );
      },
    );
  }
}

/// [OrderPreview] is the row of small thumbnail icons in the order screen that exist when order sheet is collapsed
class OrderPreview extends StatelessWidget {
  const OrderPreview({Key key}) : super(key: key);

  /// Transition Builder for the [AnimatedSwitcher] used
  Widget transitionBuilder(
    num diff,
    Widget child,
    Animation<double> animation,
  ) {
    final fadeCurveAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(.3, 1),
      reverseCurve: Interval(.65, 1),
    );
    final scaleCurveAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(.3, 1, curve: Curves.fastOutSlowIn),
      reverseCurve: Interval(.65, 1, curve: Curves.fastOutSlowIn),
    );
    final offsetCurveAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn.flipped,
    );
    return ScaleTransition(
      scale: Tween<double>(begin: .95, end: 1).animate(scaleCurveAnimation),
      child: FadeTransition(
        opacity: fadeCurveAnimation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final offsetTween = Tween<Offset>(
              begin: Offset(
                (animation.status == AnimationStatus.reverse)
                    ? -diff * 52.0
                    : diff * 52.0,
                0,
              ),
              end: Offset.zero,
            );
            return Transform.translate(
              offset: offsetTween.evaluate(offsetCurveAnimation),
              child: child,
            );
          },
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool rebuildToggle = false;
    final windowPadding = Provider.of<EdgeInsets>(context);
    final cart = Provider.of<CartModel>(
      context,
      listen: false,
    );
    int previousLength = max(cart.orderThumbnails.length, 1);
    List<String> previousThumbnails = [];
    final orderSheetController = Provider.of<BottomSheetController>(context);
    return ValueListenableBuilder(
      valueListenable: orderSheetController.altAnimation,
      builder: (context, value, child) {
        return IgnorePointer(
          ignoring: value > 0.05,
          child: child,
        );
      },
      child: Stack(
        children: <Widget>[
          ValueListenableBuilder(
            valueListenable: orderSheetController.altAnimation,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    height:
                        value.clamp(0.0, 1.0) * (windowPadding.top - 12) + 12,
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 4,
                      width: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  child,
                ],
              );
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: windowPadding.bottom),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 1,
                  end: -4,
                ).animate(orderSheetController.altAnimation),
                child: SizedBox(
                  height: 66,
                  child: Selector<CartModel, bool>(
                    selector: (context, cart) {
                      if (cart.orderThumbnails.length < 6 &&
                          !listEquals(
                              previousThumbnails, cart.orderThumbnails)) {
                        rebuildToggle = !rebuildToggle;
                        previousThumbnails = List.from(cart.orderThumbnails);
                      }
                      return rebuildToggle;
                    },
                    builder: (context, value, child) {
                      final length = min(cart.orderThumbnails.length, 5);
                      final diff = max(length, 1) - previousLength;
                      previousLength = max(length, 1);
                      return AnimatedSwitcher(
                        transitionBuilder: (child, animation) {
                          return transitionBuilder(diff, child, animation);
                        },
                        duration: 280.milliseconds,
                        child: Row(
                          key: ValueKey(value),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            for (int i = 0; i < length; i++)
                              OrderPreviewThumbnail(
                                last: i == length - 1,
                                image: cart.orderThumbnails[i],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: FlatButton(
              shape: ContinuousRectangleBorder(),
              onPressed: () {
                orderSheetController.animateTo(BottomSheetPosition.start);
              },
              child: Container(
                height: 66 + 12 + windowPadding.bottom + 20,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual thumbnail for the [OrderPreview]
class OrderPreviewThumbnail extends StatelessWidget {
  final bool last;
  final String image;
  const OrderPreviewThumbnail({
    Key key,
    this.last = false,
    @required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: 48,
      child: CustomImage(
        image,
        fadeInDuration: null,
        fallbackMemoryImage: kErrorImage,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 9, 4, 9),
      child: Material(
        color: Theme.of(context).dividerColor,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: last
            ? Selector<CartModel, int>(
                selector: (context, cart) {
                  return max(cart.orderThumbnails.length, 5);
                },
                builder: (context, length, _) {
                  return CustomAnimatedSwitcher(
                    duration: 200.milliseconds,
                    child: length > 5
                        ? Container(
                            key: ValueKey(length),
                            height: 48,
                            width: 48,
                            alignment: Alignment.center,
                            child: Text('+${length - 4}'),
                          )
                        : child,
                  );
                },
              )
            : child,
      ),
    );
  }
}

class ListOfOrders extends StatelessWidget {
  const ListOfOrders({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<CartModel, Orders>(
      selector: (context, cart) => cart.orders,
      builder: (context, orders, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                orders.value.length == 0 ? 'No Orders' : 'Orders',
                style: Theme.of(context).textTheme.display3,
              ),
            ),
            Column(
              children: <Widget>[
                if (orders.value.length == 0)
                  FlatButton(
                    child: Text('Go back'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                else
                  for (var stallId in orders.value.keys)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Selector<StallDetailsMap, String>(
                            selector: (context, stallDetailsMap) {
                              return stallDetailsMap.value[stallId].name;
                            },
                            builder: (context, name, child) {
                              return Text(
                                name,
                                style: Theme.of(context).textTheme.display2,
                              );
                            },
                          ),
                        ),
                        for (var orderedDish in orders.value[stallId].keys)
                          OrderDishRow(
                            stallId: stallId,
                            quantity: orders.value[stallId][orderedDish],
                            orderedDish: orderedDish,
                          ),
                      ],
                    ),
              ],
            ),
            TotalCostWidget(orders: orders),
            const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class OrderDishRow extends StatelessWidget {
  final StallId stallId;
  final int quantity;
  final OrderedDish orderedDish;
  const OrderDishRow({
    Key key,
    @required this.stallId,
    @required this.quantity,
    @required this.orderedDish,
  }) : super(key: key);

  List<Widget> dishOptions(BuildContext context, List<DishOption> options) {
    return options.map((option) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(69),
            bottomLeft: Radius.circular(69),
            bottomRight: Radius.circular(69),
          ),
          color: Colors.primaries[option.colourCode],
        ),
        child: Text(
          option.name,
          style: Theme.of(context).textTheme.subtitle.copyWith(
                color:
                    Colors.primaries[option.colourCode].computeLuminance() < .6
                        ? Colors.white
                        : Colors.black87,
              ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    num price = orderedDish.dish.unitPrice;
    orderedDish.enabledOptions.forEach((option) {
      price += option.addCost;
    });
    price *= quantity;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          final windowPadding = Provider.of<EdgeInsets>(context);
          final bottomSheetController =
              Provider.of<BottomSheetController>(context);
          Navigator.push(context, CrossFadePageRoute(
            builder: (_) {
              return MultiProvider(
                providers: [
                  Provider.value(
                    value: windowPadding,
                  ),
                  ChangeNotifierProvider.value(
                    value: bottomSheetController,
                  ),
                ],
                child: DishEditScreen(
                  tag: orderedDish.toString(),
                  dish: orderedDish.dish,
                ),
              );
            },
          ));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 24, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 96,
                height: 88,
                child: Hero(
                  tag: orderedDish.toString(),
                  createRectTween: (a, b) {
                    return MaterialRectCenterArcTween(begin: a, end: b);
                  },
                  child: Material(
                    type: MaterialType.transparency,
                    child: DishImage(
                      dish: orderedDish.dish,
                      animation: AlwaysStoppedAnimation(1),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(quantity.toString() + '× ' + orderedDish.dish.name),
                    const SizedBox(
                      height: 1,
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    if (orderedDish.enabledOptions.isNotEmpty)
                      SizedBox(
                        width: width - 192.1,
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 3,
                          children:
                              dishOptions(context, orderedDish.enabledOptions),
                        ),
                      ),
                    const SizedBox(
                      height: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TotalCostWidget extends StatelessWidget {
  final Orders orders;
  const TotalCostWidget({Key key, @required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    num cost = 0;
    orders.value.forEach((stallId, stallOrders) {
      stallOrders.forEach((dish, quantity) {
        num price = dish.dish.unitPrice;
        dish.enabledOptions.forEach((option) {
          price += option.addCost;
        });
        price *= quantity;
        cost += price;
      });
    });
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Total Cost',
            style: Theme.of(context).textTheme.subtitle.copyWith(
                  fontSize: 15,
                ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            '\$${cost.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.display3,
          ),
        ],
      ),
    );
  }
}
