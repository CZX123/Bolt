import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/bottom_sheet.dart';

// class StallOrder {
//   List<String> items;
// }

// class Order extends ChangeNotifier {
//   Order();
//   String
//   List<String> _orderList = [];
// }

class ViewOrder extends ChangeNotifier {
  ViewOrder();
  bool viewOrder = false;
  void toggle() {
    viewOrder = !viewOrder;
    notifyListeners();
  }
}

class ViewOrderScreen extends StatefulWidget {
  ViewOrderScreen({Key key}) : super(key: key);

  _ViewOrderScreenState createState() => _ViewOrderScreenState();
}

class _ViewOrderScreenState extends State<ViewOrderScreen> {
  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    bool viewOrder = Provider.of<ViewOrder>(context).viewOrder;
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    return CustomBottomSheet(
      controllers: [scrollController],
      headerHeight: viewOrder ? 52 + 20 + windowPadding.bottom : 0,
      headerBuilder:
          (context, animation, viewSheetCallback, innerBoxIsScrolled) {
        return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    height: animation.value.clamp(0.0, double.infinity) *
                            (windowPadding.top - 20) +
                        20,
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
                  FlatButton(
                    textColor: Theme.of(context).primaryColor,
                    child: Container(
                      height: 52,
                      width: MediaQuery.of(context).size.width,
                      alignment: Alignment.center,
                      child: Text('View Order'),
                    ),
                    onPressed: viewSheetCallback,
                  ),
                  SizedBox(
                    height: windowPadding.bottom,
                  ),
                ],
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
