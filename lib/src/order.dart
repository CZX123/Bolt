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
  int _previousLength = 0;
  @override
  Widget build(BuildContext context) {
    final orderNotifier = Provider.of<OrderNotifier>(context);
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    if (orderNotifier.orderHistory.length > _previousLength) {
      int _newLength = orderNotifier.orderHistory.length;
      orderNotifier.orderHistory.sublist(_previousLength, _newLength).forEach((item) {
        item[0]
          ? _listKey.currentState.insertItem(item[1])
          : _listKey.currentState.removeItem(item[1],
          (context, animation) {
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
                  ),
                ),
              ),
            ),
          ),
        );
      }, duration: const Duration(milliseconds: 200));
      });
      _previousLength = _newLength;
    }
    return CustomBottomSheet(
      // TODO: find better colors for the OrderScreen
      //color: Theme.of(context).primaryColorLight,
      controllers: [scrollController],
      headerHeight:
          orderNotifier.orders.length > 0 ? 66 + 12 + windowPadding.bottom : 0,
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
                      height: 66,
                      child: AnimatedList(
                        padding: EdgeInsets.all(8),
                        key: _listKey,
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemBuilder: (context, index, animation) {
                          return SizeTransition(
                            axis: Axis.horizontal,
                            sizeFactor: CurvedAnimation(
                                curve: Curves.fastOutSlowIn, parent: animation),
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                  curve: Curves.fastOutSlowIn,
                                  parent: animation),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                                child: ClipPath(
                                  clipper: ShapeBorderClipper(
                                      shape: ContinuousRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20))),
                                  child: SizedBox(
                                    height: 48,
                                    child: FirebaseImage(
                                      orderNotifier
                                          .orders[index].menuItem.image,
                                      fadeInDuration: null,
                                    ),
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
        // TODO: build a nice layout for the OrderScreen
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
