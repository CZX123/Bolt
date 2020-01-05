import '../library.dart';

class CurrentOrdersScreen extends StatelessWidget {
  const CurrentOrdersScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.get<User>().value;
    final userData = context.get<UserData>();
    final isDark = context.get<ThemeModel>().isDark;
    return AnimatedTheme(
      data: context.theme.copyWith(
        scaffoldBackgroundColor: isDark ? Color(0xFF0e131a) : Color(0xFFE1E8EB),
        cardColor: isDark ? Color(0xFF222d3d) : Colors.grey[50],
      ),
      child: Builder(
        builder: (context) => Material(
          color: context.theme.scaffoldBackgroundColor,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                backgroundColor: context.theme.scaffoldBackgroundColor,
                brightness: Brightness.dark,
                textTheme: context.theme.textTheme,
                stretch: true,
                centerTitle: true,
                expandedHeight: 192,
                leading: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: context.theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Current Orders',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.theme.colorScheme.onSurface,
                    ),
                  ),
                  titlePadding: EdgeInsets.only(bottom: 8),
                ),
              ),
              SliverPadding(
                padding:
                    EdgeInsets.only(bottom: context.windowPadding.bottom + 8),
                sliver: FirebaseSliverAnimatedList(
                  query: FirebaseDatabase.instance
                      .reference()
                      .child('users/${user.uid}/orders'),
                  itemBuilder: (context, snapshot, animation, index) {
                    return OrderCard(
                      key: ValueKey(snapshot.key),
                      data: snapshot,
                      animation: animation,
                    );
                  },
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: true,
                child: AnimatedOpacity(
                  opacity: userData.hasOrders ? 0 : 1,
                  duration: 200.milliseconds,
                  child: userData.hasOrders
                      ? SizedBox.shrink()
                      : Padding(
                          padding: EdgeInsets.only(
                              bottom: context.windowPadding.bottom + 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: context.theme.disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No current orders',
                                style: context.theme.textTheme.body2.copyWith(
                                  color: context.theme.disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserOrderAPI {
  static final _removeUserOrderCallable =
      CloudFunctions.instance.getHttpsCallable(
    functionName: 'removeUserOrder',
  );

  static Future<void> removeUserOrder({StallId stallId, int orderId}) async {
    final data = {
      'stallId': stallId.value,
      'orderId': orderId,
    };
    await _removeUserOrderCallable(data);
  }
}

/// An individual order
class OrderCard extends StatefulWidget {
  final DataSnapshot data;
  final Animation<double> animation;
  const OrderCard({
    Key key,
    @required this.data,
    @required this.animation,
  }) : super(key: key);

  @override
  _OrderCardState createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard>
    with SingleTickerProviderStateMixin {
  List _dishes;
  StallId _stallId;
  TimeOfDay _time;
  int _orderId;

  @override
  void initState() {
    super.initState();
    _dishes = widget.data.value['dishes'];
    _stallId = StallId(widget.data.value['stallId']);
    _time = widget.data.value['time'].toString().toTime();
    _orderId = widget.data.value['orderId'];
    _updateStatus();
  }

  @override
  void didUpdateWidget(OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateStatus();
  }

  /// 0: Pending
  /// 1: Rejected
  /// 2: Completed
  /// 3: Collected
  int _status;
  void _updateStatus() {
    if (widget.data.value['collected']) {
      _status = 3;
    } else if (widget.data.value['completed']) {
      _status = 2;
    } else if (widget.data.value['rejected']) {
      _status = 1;
    } else {
      _status = 0;
    }
  }

  Color get _statusColor {
    final isDark = context.get<ThemeModel>().isDark;
    switch (_status) {
      case 0:
        return isDark ? Colors.blueAccent : Colors.blue;
      case 1:
        return isDark ? Colors.redAccent : Colors.red;
      default:
        return isDark ? Colors.greenAccent : Colors.green;
    }
  }

  IconData get _statusIconData {
    switch (_status) {
      case 0:
        return Icons.access_time;
      case 1:
        return Icons.clear;
      default:
        return Icons.check;
    }
  }

  String get _statusText {
    switch (_status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Rejected';
      case 2:
        return 'Completed';
      default:
        return 'Collected';
    }
  }

  List<Widget> _generateDishOptions(List<DishOption> options) {
    return options.map((option) {
      return Container(
        padding: const EdgeInsets.fromLTRB(6, 1, 6, 2),
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
          style: Theme.of(context).textTheme.caption.copyWith(
                color:
                    Colors.primaries[option.colourCode].computeLuminance() < .6
                        ? Colors.white
                        : Colors.black87,
              ),
        ),
      );
    }).toList();
  }

  List<Widget> _generateDishes() {
    final stallMenuMap = Provider.of<StallMenuMap>(context);
    if (stallMenuMap == null) return [];
    final stallMenu = Provider.of<StallMenuMap>(context).value[_stallId].menu;
    return _dishes.map((dish) {
      final int id = dish['id'];
      final Dish menuDish = stallMenu.firstWhere((menuDish) {
        return menuDish.id == id;
      });
      final List<DishOption> options = dish['options'] != null
          ? (dish['options'] as List).map((optionId) {
              return menuDish.options
                  .firstWhere((option) => optionId == option.id);
            }).toList()
          : [];
      final int quantity = dish['quantity'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('$quantity× ${menuDish.name}',
                style: context.theme.textTheme.subhead),
            if (options.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 5,
                runSpacing: 3,
                children: _generateDishOptions(options),
              ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        curve: Curves.fastOutSlowIn,
        parent: widget.animation,
      ),
      child: FadeTransition(
        opacity: widget.animation.drive(Tween(
          begin: -1.0,
          end: 1.0,
        )),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Material(
            color: context.theme.cardColor,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '#$_orderId',
                        style: Theme.of(context).textTheme.display2,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _generateDishes(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Time',
                            style: context.theme.textTheme.subtitle,
                          ),
                          Text(
                            _time.format(context),
                            style: context.theme.textTheme.subhead,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'Status',
                            style: context.theme.textTheme.subtitle,
                          ),
                          AnimatedSwitcher(
                            switchInCurve: Interval(.5, 1),
                            switchOutCurve: Interval(.5, 1),
                            duration: 240.milliseconds,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                                alignment: Alignment.centerRight,
                              );
                            },
                            child: AnimatedTheme(
                              key: ValueKey(_status),
                              data: context.theme.copyWith(
                                indicatorColor: _statusColor,
                              ),
                              child: Builder(
                                builder: (context) => Row(
                                  children: <Widget>[
                                    Icon(
                                      _statusIconData,
                                      color: context.theme.indicatorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _statusText,
                                      style: context.theme.textTheme.subhead
                                          .copyWith(
                                        color: context.theme.indicatorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  vsync: this,
                  duration: 240.milliseconds,
                  curve: Curves.fastOutSlowIn,
                  child: _status == 1 || _status == 3
                      ? Column(
                          children: <Widget>[
                            Divider(
                              height: 1,
                              thickness: 1,
                            ),
                            InkWell(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.remove_circle,
                                      color: context.theme.accentColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: context.theme.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                UserOrderAPI.removeUserOrder(
                                  stallId: _stallId,
                                  orderId: _orderId,
                                );
                              },
                            ),
                          ],
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
