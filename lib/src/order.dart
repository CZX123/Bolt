import '../library.dart';

class OrderScreen extends StatefulWidget {
  OrderScreen({Key key}) : super(key: key);

  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  ScrollController scrollController = ScrollController();
  final _listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    final windowPadding = Provider.of<EdgeInsets>(context);
    return Selector<ShoppingCartNotifier, bool>(
      selector: (context, cart) => cart.orders.length > 0,
      builder: (context, value, child) {
        return CustomBottomSheet(
          color: Theme.of(context).cardColor,
          controllers: [scrollController],
          headerHeight: value ? 66 + 12 + windowPadding.bottom : 0,
          headerBuilder:
              (context, animation, viewSheetCallback, innerBoxIsScrolled) {
            final thumbnails =
                Provider.of<ShoppingCartNotifier>(context, listen: false)
                    .orderThumbnails;
            Provider.of<ShoppingCartNotifier>(context, listen: false)
                .animatedListKey = _listKey;
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: animation.value > 0.05,
                  child: child,
                );
              },
              child: Stack(
                children: <Widget>[
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.only(top: 8),
                            height:
                                animation.value.clamp(0.0, double.infinity) *
                                        (windowPadding.top - 12) +
                                    12,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        FadeTransition(
                          opacity: Tween<double>(begin: 1, end: -4)
                              .animate(animation),
                          child: SizedBox(
                            height: 66,
                            child: Selector<ShoppingCartNotifier, int>(
                                selector: (context, cart) =>
                                    max(cart.orderThumbnails.length, 5),
                                builder: (context, value, child) {
                                  return AnimatedList(
                                    padding: EdgeInsets.all(8),
                                    key: _listKey,
                                    scrollDirection: Axis.horizontal,
                                    shrinkWrap: true,
                                    initialItemCount: min(thumbnails.length, 5),
                                    itemBuilder: (context, index, animation) {
                                      Widget element = SizedBox(
                                        height: 48,
                                        child: FirebaseImage(
                                          thumbnails[index],
                                          fadeInDuration: null,
                                          fallbackMemoryImage: kErrorImage,
                                        ),
                                      );
                                      if (index == 4 && thumbnails.length > 5)
                                        element = Container(
                                          color: Theme.of(context).dividerColor,
                                          height: 48,
                                          width: 48,
                                          alignment: Alignment.center,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            switchInCurve: Interval(0.5, 1,
                                                curve: Curves.easeIn),
                                            switchOutCurve: Interval(0.5, 1,
                                                curve: Curves.easeOut),
                                            child: Text(
                                              '+${thumbnails.length - 4}',
                                              key: ValueKey(thumbnails.length),
                                            ),
                                          ),
                                        );
                                      return SizeTransition(
                                        key: ValueKey(index),
                                        axis: Axis.horizontal,
                                        sizeFactor: CurvedAnimation(
                                            curve: Curves.fastOutSlowIn,
                                            parent: animation),
                                        child: ScaleTransition(
                                          scale: CurvedAnimation(
                                              curve: Curves.fastOutSlowIn,
                                              parent: animation),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                4, 0, 4, 0),
                                            child: ClipPath(
                                              clipper: ShapeBorderClipper(
                                                  shape:
                                                      ContinuousRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20))),
                                              child: AnimatedSwitcher(
                                                duration:
                                                    Duration(milliseconds: 100),
                                                child: element,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                          ),
                        ),
                        SizedBox(
                          height: windowPadding.bottom,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: FlatButton(
                      shape: ContinuousRectangleBorder(),
                      onPressed: viewSheetCallback,
                      child: Container(
                        height: 66 + 12 + windowPadding.bottom + 20,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          contentBuilder: (context, animation) {
            return Stack(
              fit: StackFit.passthrough,
              children: <Widget>[
                SingleChildScrollView(
                  controller: scrollController,
                  physics: NeverScrollableScrollPhysics(),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: -0.25, end: 1.5)
                        .animate(animation),
                    child: Column(
                      children: <Widget>[
                        AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return SizedBox(
                              height:
                                  animation.value.clamp(0.0, double.infinity) *
                                          (windowPadding.top - 20) +
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
                          padding: const EdgeInsets.all(32),
                          child: ListOfOrders(),
                        ),
                        SizedBox(
                          height: windowPadding.bottom,
                        ),
                      ],
                    ),
                  ),
                ),
                //PaymentScreen(),
              ],
            );
          },
        );
      },
    );
  }
}

class ListOfOrders extends StatelessWidget {
  const ListOfOrders({Key key}) : super(key: key);

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
    return Selector<ShoppingCartNotifier, Map<int, Map<DishWithOptions, int>>>(
      selector: (context, cart) => cart.orders,
      builder: (context, orders, child) {
        final stallList =
            Provider.of<List<StallDetails>>(context, listen: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Text(
                orders.length == 0 ? 'No Orders' : 'Orders',
                style: Theme.of(context).textTheme.display3,
              ),
            ),
            Column(
              children: <Widget>[
                if (orders.length == 0)
                  FlatButton(
                    child: Text('Go back'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                else
                  for (var stallId in orders.keys)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                          child: Text(
                              stallList.firstWhere((stall) {
                                return stall.id == stallId;
                              }).name,
                              style: Theme.of(context).textTheme.display2),
                        ),
                        for (var dish in orders[stallId].keys)
                          OrderDishRow(
                            quantity: orders[stallId][dish],
                            dish: dish,
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
  final int quantity;
  final DishWithOptions dish;
  const OrderDishRow({Key key, @required this.quantity, @required this.dish})
      : super(key: key);

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
    num price = dish.dish.unitPrice;
    dish.enabledOptions.forEach((option) {
      price += option.addCost;
    });
    price *= quantity;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipPath(
            clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            child: SizedBox(
              height: 80,
              child: FirebaseImage(
                dish.dish.image,
                fadeInDuration: null,
              ),
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(quantity.toString() + '× ' + dish.dish.name),
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
              if (dish.enabledOptions.isNotEmpty)
                SizedBox(
                  width: width - 192.1,
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: dishOptions(context, dish.enabledOptions),
                  ),
                ),
              const SizedBox(
                height: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TotalCostWidget extends StatelessWidget {
  final Map<int, Map<DishWithOptions, int>> orders;
  const TotalCostWidget({Key key, @required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    num cost = 0;
    orders.forEach((stallId, stallOrders) {
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
