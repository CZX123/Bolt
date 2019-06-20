import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase/firebase.dart';
import 'order_data.dart';
import 'widgets/bottom_sheet.dart';

class OrderScreen extends StatefulWidget {
  OrderScreen({Key key}) : super(key: key);

  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  ScrollController scrollController = ScrollController();
  final _listKey = GlobalKey<AnimatedListState>();
  List<Order> _previousOrders;
  @override
  Widget build(BuildContext context) {
    final orderNotifier = Provider.of<OrderNotifier>(context);
    final List<Order> orders = orderNotifier.orders;
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    if (_previousOrders == null) {
      _previousOrders = List<Order>.from(orders);
    } else if (orders.length == _previousOrders.length + 1) {
      _previousOrders = List<Order>.from(orders);
      // WidgetsBinding.instance.addPostFrameCallback((_) {});
      _listKey.currentState.insertItem(orderNotifier.index,
          duration: const Duration(milliseconds: 200));
    } else if (orders.length == _previousOrders.length - 1) {
      final previousItem = _previousOrders[orderNotifier.index].menuItem;
      _previousOrders = List<Order>.from(orders);
      _listKey.currentState.removeItem(orderNotifier.index,
          (context, animation) {
        return SizeTransition(
          axis: Axis.horizontal,
          sizeFactor: CurvedAnimation(curve: Curves.easeIn, parent: animation),
          child: ScaleTransition(
            scale: CurvedAnimation(curve: Curves.easeIn, parent: animation),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: ClipPath(
                clipper: ShapeBorderClipper(
                    shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Image(
                  height: 34,
                  gaplessPlayback: true,
                  image: FirebaseImage(previousItem.image),
                ),
              ),
            ),
          ),
        );
      }, duration: const Duration(milliseconds: 200));
    }
    return CustomBottomSheet(
      controllers: [scrollController],
      headerHeight:
          orderNotifier.orders.length > 0 ? 52 + 12 + windowPadding.bottom : 0,
      headerBuilder:
          (context, animation, viewSheetCallback, innerBoxIsScrolled) {
        return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return FlatButton(
                textColor: Theme.of(context).primaryColor,
                child: Column(
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
                    SizedBox(
                      height: 52,
                      child: AnimatedList(
                        padding: EdgeInsets.all(8),
                        key: _listKey,
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemBuilder: (context, index, animation) {
                          return SizeTransition(
                            axis: Axis.horizontal,
                            sizeFactor: CurvedAnimation(curve: Curves.fastOutSlowIn, parent: animation),
                            child: ScaleTransition(
                              scale: CurvedAnimation(curve: Curves.fastOutSlowIn, parent: animation),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                                child: ClipPath(
                                  clipper: ShapeBorderClipper(
                                      shape: ContinuousRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  child: Image(
                                    height: 34,
                                    gaplessPlayback: true,
                                    image: FirebaseImage(orderNotifier
                                        .orders[index].menuItem.image),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: windowPadding.bottom,
                    ),
                  ],
                ),
                onPressed: viewSheetCallback,
              );
            });
      },
      contentBuilder: (context, animation) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, windowPadding.top, 0, 72),
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
              for (int i = 0; i < 30; i++)
                Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Text('${i + 1}'),
                ),
            ],
          ),
        );
      },
    );
  }
}
