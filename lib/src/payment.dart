import '../library.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key key}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
    return CustomBottomSheet(
      controllers: [_scrollController],
      headerHeight: 56 + 12 + windowPadding.bottom,
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
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Text('Confirm Order'),
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
                    height: 56 + 12 + windowPadding.bottom + 20,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      contentBuilder: (context, animation) {
        return SingleChildScrollView(
          controller: _scrollController,
          physics: NeverScrollableScrollPhysics(),
          child: FadeTransition(
            opacity: Tween<double>(begin: -0.25, end: 1.5).animate(animation),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 30; i++)
                  ListTile(
                    title: Text('$i'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
