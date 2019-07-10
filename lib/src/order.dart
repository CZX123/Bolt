import 'images/error_image.dart';
import 'payment.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/firebase.dart';
import 'order_data.dart';
import 'widgets/bottom_sheet.dart';

class OrderScreen extends StatefulWidget {
  OrderScreen({Key key}) : super(key: key);

  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  ScrollController scrollController = ScrollController();
  final _listKey = GlobalKey<AnimatedListState>();
  List<Order> _previousList = []; // max of 5

  @override
  Widget build(BuildContext context) {
    final orderNotifier = Provider.of<OrderNotifier>(context);
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    if (orderNotifier.orderHistory.length > 0) {
      orderNotifier.orderHistory.forEach((item) {
        if (item[0]) {
          _previousList.add(item[2]);
          if (item[1] < 5) {
            _listKey.currentState.insertItem(item[1],
                duration: const Duration(milliseconds: 200));
          }
        } else {
          if (item[1] < 5) {
            _listKey.currentState.removeItem(item[1], (context, animation) {
              return SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: CurvedAnimation(
                    curve: Curves.fastOutSlowIn.flipped, parent: animation),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                      curve: Curves.fastOutSlowIn.flipped, parent: animation),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: ClipPath(
                      clipper: ShapeBorderClipper(
                          shape: ContinuousRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: SizedBox(
                        height: 48,
                        child: FirebaseImage(
                          item[2].menuItem.image,
                          fadeInDuration: null,
                          fallbackMemoryImage: kErrorImage,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }, duration: const Duration(milliseconds: 200));
            if (_previousList.length > 5) {
              _listKey.currentState.insertItem(
                  _previousList.length == 6 ? 4 : 3,
                  duration: const Duration(milliseconds: 200));
            }
          }
          _previousList.removeAt(item[1]);
        }
      });
      orderNotifier.clearOrderHistory();
    }
    return CustomBottomSheet(
      color: Theme.of(context).cardColor,
      controllers: [scrollController],
      headerHeight:
          orderNotifier.orders.length > 0 ? 66 + 12 + windowPadding.bottom : 0,
      headerBuilder:
          (context, animation, viewSheetCallback, innerBoxIsScrolled) {
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
                        height: animation.value.clamp(0.0, double.infinity) *
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
                      opacity:
                          Tween<double>(begin: 1, end: -4).animate(animation),
                      child: SizedBox(
                        height: 66,
                        child: AnimatedList(
                          padding: EdgeInsets.all(8),
                          key: _listKey,
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemBuilder: (context, index, animation) {
                            print('$index: ${orderNotifier.orders[index].menuItem.name}');
                            Widget element = SizedBox(
                              height: 48,
                              child: FirebaseImage(
                                orderNotifier.orders[index].menuItem.image,
                                fadeInDuration: null,
                                fallbackMemoryImage: kErrorImage,
                              ),
                            );
                            if (index == 4 && orderNotifier.orders.length > 5)
                              element = Container(
                                color: Theme.of(context).dividerColor,
                                height: 48,
                                width: 48,
                                alignment: Alignment.center,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  switchInCurve:
                                      Interval(0.5, 1, curve: Curves.easeIn),
                                  switchOutCurve:
                                      Interval(0.5, 1, curve: Curves.easeOut),
                                  child: Text(
                                    '+${orderNotifier.orders.length - 4}',
                                    key: ValueKey(orderNotifier.orders.length),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(4, 0, 4, 0),
                                  child: ClipPath(
                                    clipper: ShapeBorderClipper(
                                        shape: ContinuousRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20))),
                                    child: AnimatedSwitcher(
                                      duration: Duration(milliseconds: 100),
                                      child: element,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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
                opacity:
                    Tween<double>(begin: -0.25, end: 1.5).animate(animation),
                child: Column(
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return SizedBox(
                          height: animation.value.clamp(0.0, double.infinity) *
                                  (windowPadding.top - 20) +
                              20,
                        );
                      },
                    ),
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            windowPadding.top,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const SizedBox.shrink(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                            child: Text(
                              orderNotifier.orders.length == 0
                                  ? 'No Orders'
                                  : 'Orders',
                              style: Theme.of(context).textTheme.display3,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (orderNotifier.orders.length == 0)
                                FlatButton(
                                  child: Text('Go back'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                )
                              else
                                for (var order in orderNotifier.orders)
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        ClipPath(
                                          clipper: ShapeBorderClipper(
                                              shape: ContinuousRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20))),
                                          child: SizedBox(
                                            height: 96,
                                            child: FirebaseImage(
                                              order.menuItem.image,
                                              fadeInDuration: null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 16,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(order.menuItem.name),
                                            const SizedBox(
                                              height: 1,
                                            ),
                                            Text(
                                              '\$${order.menuItem.price.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle,
                                            ),
                                            const SizedBox(
                                              height: 6,
                                            ),
                                            ButtonTheme.fromButtonThemeData(
                                              data: Theme.of(context)
                                                  .buttonTheme
                                                  .copyWith(
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                              child: Row(
                                                children: <Widget>[
                                                  OutlineButton(
                                                    highlightedBorderColor:
                                                        Theme.of(context)
                                                            .accentColor,
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            8, 5, 9, 5),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Icon(
                                                          Icons.add,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        Text(
                                                          'Add Rice',
                                                        ),
                                                      ],
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                    ),
                                                    onPressed: () {},
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                  OutlineButton(
                                                    highlightedBorderColor:
                                                        Theme.of(context)
                                                            .accentColor,
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            8, 5, 9, 5),
                                                    child: Row(
                                                      children: <Widget>[
                                                        Icon(
                                                          Icons.arrow_upward,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        Text(
                                                          'Upsize',
                                                        ),
                                                      ],
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                    ),
                                                    onPressed: () {},
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                            ],
                          ),
                          Padding(
                            padding:
                                EdgeInsets.only(bottom: windowPadding.bottom),
                            child: FlatButton(
                              child: Container(
                                height: 48,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Text('Confirm Order'),
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
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
  }
}
