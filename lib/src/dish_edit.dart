import '../library.dart';

double _getPrice({
  @required int quantity,
  @required double unitCost,
  @required List<DishOption> options,
}) {
  assert(quantity != null);
  assert(unitCost != null);
  assert(options != null);
  return quantity * options.fold(unitCost, (a, b) => a + b.addCost);
}

/// A class that takes in an [OrderedDish] and the quantity (type [int]) of that dish. Used in [DishEditScreen]
class OrderedDishWithQuantity {
  OrderedDish orderedDish;
  int quantity;
  OrderedDishWithQuantity({this.orderedDish, this.quantity});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrderedDishWithQuantity &&
            orderedDish == other.orderedDish &&
            quantity == other.quantity;
  }

  @override
  int get hashCode => hashValues(orderedDish, quantity);
}

/// The [DishEditingController] is similar to the [CartModel]. However, it internally works differently, as editing each dish is based on index, instead of a map structure.
class DishEditingController extends ChangeNotifier {
  final Dish dish;
  final GlobalKey<SliverAnimatedListState> animatedListKey;
  DishEditingController({@required this.dish, @required this.animatedListKey});

  List<OrderedDishWithQuantity> _dishes;
  List<OrderedDishWithQuantity> get dishes => _dishes;

  /// Must be called before calling any other method!
  void initDishes(Iterable<MapEntry<OrderedDish, int>> dishList) {
    assert(dishList != null);
    _dishes = dishList.map((entry) {
      return OrderedDishWithQuantity(
        orderedDish: entry.key,
        quantity: entry.value,
      );
    }).toList();
  }

  void addDish() {
    if (animatedListKey.currentState.mounted) {
      animatedListKey.currentState.insertItem(_dishes.length);
    }
    _dishes.add(OrderedDishWithQuantity(
      orderedDish: OrderedDish(
        dish: dish,
        enabledOptions: [],
      ),
      quantity: 1,
    ));
    notifyListeners();
  }

  void removeDish({@required int index}) {
    assert(index != null);
    assert(index < dishes.length);
    final dish = dishes.removeAt(index);
    if (animatedListKey.currentState.mounted) {
      animatedListKey.currentState.removeItem(
        index,
        (context, animation) {
          return DishEditScreen.itemBuilder(
            animation,
            DishEditRow(
              key: ObjectKey(dish),
              index: index,
              dishWithQuantity: dish,
            ),
          );
        },
      );
    }
    notifyListeners();
  }

  void changeOptions({
    @required int index,
    @required List<DishOption> options,
  }) {
    assert(index != null);
    assert(index < dishes.length);
    assert(options != null);
    options.sort((a, b) => a.name.compareTo(b.name));
    if (listEquals(_dishes[index].orderedDish.enabledOptions, options)) return;
    _dishes[index].orderedDish = OrderedDish(
      dish: dish,
      enabledOptions: options,
    );
    notifyListeners();
  }
}

class DishEditScreen extends StatefulWidget {
  /// Required for the hero animation
  final String tag;
  final Dish dish;
  const DishEditScreen({
    Key key,
    @required this.tag,
    @required this.dish,
  }) : super(key: key);

  /// Transition Builder for adding or removing items in the Animated List.
  static Widget itemBuilder(
    Animation<double> animation,
    Widget child,
  ) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        curve: Curves.fastOutSlowIn,
        parent: animation,
      ),
      child: FadeTransition(
        opacity: Tween(
          begin: -1.0,
          end: 1.0,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  _DishEditScreenState createState() => _DishEditScreenState();
}

class _DishEditScreenState extends State<DishEditScreen> {
  bool _init = false;
  final _animatedListKey = GlobalKey<SliverAnimatedListState>();
  DishEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DishEditingController(
      dish: widget.dish,
      animatedListKey: _animatedListKey,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final orders = Provider.of<CartModel>(context, listen: false).orders;
      final stallId = widget.dish.stallId;
      // Add the initial [OrderedDish]s from the [CartModel] first
      final relevantDishes = orders.value[stallId]?.entries?.where((entry) {
        return entry.key.dish == widget.dish;
      });
      _controller.initDishes(relevantDishes ?? []);
      _init = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = Provider.of<EdgeInsets>(context).top;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ChangeNotifierProvider.value(
        value: _controller,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SlideTransition(
            position: Tween(
              begin: Offset(0, .05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              curve: Curves.fastOutSlowIn,
              parent: ModalRoute.of(context).animation,
            )),
            child: CustomScrollView(
              slivers: <Widget>[
                // Top headers containing dish image and name, and stall name
                SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    SizedBox(
                      height: topPadding + 24,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Hero(
                        tag: widget.tag,
                        createRectTween: (a, b) {
                          return MaterialRectCenterArcTween(begin: a, end: b);
                        },
                        flightShuttleBuilder: (
                          BuildContext flightContext,
                          Animation<double> animation,
                          HeroFlightDirection flightDirection,
                          BuildContext fromHeroContext,
                          BuildContext toHeroContext,
                        ) {
                          Hero hero;
                          if (flightDirection == HeroFlightDirection.push) {
                            hero = fromHeroContext.widget;
                          } else {
                            hero = toHeroContext.widget;
                          }
                          return hero.child;
                        },
                        child: SizedBox(
                          width: 96,
                          height: 88,
                          child: DishImage(
                            dish: widget.dish,
                            animation: AlwaysStoppedAnimation(1),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Selector<StallDetailsMap, String>(
                        selector: (context, stallDetailsMap) {
                          return stallDetailsMap
                              .value[widget.dish.stallId].name;
                        },
                        builder: (context, name, child) {
                          return Text(
                            name,
                            style:
                                Theme.of(context).textTheme.display1.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        widget.dish.name,
                        style: Theme.of(context).textTheme.display2,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                  ]),
                ),
                // The dishes themselves
                SliverAnimatedList(
                  key: _animatedListKey,
                  initialItemCount: _controller.dishes.length,
                  itemBuilder: (context, index, animation) {
                    return DishEditScreen.itemBuilder(
                      animation,
                      DishEditRow(
                        key: ObjectKey(_controller.dishes[index]),
                        index: index,
                        dishWithQuantity: _controller.dishes[index],
                      ),
                    );
                  },
                ),
                // Add dish button
                // SliverFillRemaining(
                //   hasScrollBody: false,
                //   child: Center(
                //     child: RaisedButton(
                //       elevation: 0,
                //       color: Theme.of(context).cardColor,
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: <Widget>[
                //           const Icon(Icons.add),
                //           const SizedBox(width: 3),
                //           const Text(
                //             'Add Dish',
                //           ),
                //           const SizedBox(width: 4),
                //         ],
                //       ),
                //       onPressed: _controller.addDish,
                //     ),
                //   ),
                // ),
                SliverToBoxAdapter(
                  child: Center(
                    child: RaisedButton(
                      elevation: 0,
                      color: Theme.of(context).cardColor,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.add),
                          const SizedBox(width: 3),
                          const Text(
                            'Add Dish',
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                      onPressed: _controller.addDish,
                    ),
                  ),
                ),
                // Cancel & Save Footer
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: DishEditFooter(),
                  ),
                ),
                // SliverToBoxAdapter(
                //   child: DishEditFooter(),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DishEditFooter extends StatelessWidget {
  const DishEditFooter({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = Provider.of<EdgeInsets>(context).bottom;
    return Container(
      height: 80 + bottomPadding,
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
      child: Row(
        children: <Widget>[
          Expanded(
            child: RaisedButton(
              elevation: 0,
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.clear),
                  const SizedBox(width: 6),
                  const Text(
                    'Cancel',
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(
            width: 24,
          ),
          Expanded(
            child: RaisedButton(
              color: Colors.green,
              colorBrightness: Brightness.dark,
              elevation: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.check),
                  const SizedBox(width: 6),
                  const Text(
                    'Save',
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              onPressed: () {
                final controller =
                    Provider.of<DishEditingController>(context, listen: false);
                Provider.of<CartModel>(context, listen: false).replaceDish(
                  context: context,
                  dish: controller.dish,
                  newDishes: controller.dishes,
                );
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DishEditRow extends StatefulWidget {
  final int index;
  final OrderedDishWithQuantity dishWithQuantity;
  const DishEditRow({
    Key key,
    @required this.index,
    @required this.dishWithQuantity,
  }) : super(key: key);

  @override
  _DishEditRowState createState() => _DishEditRowState();
}

class _DishEditRowState extends State<DishEditRow> {
  TextEditingController _textController;
  final _focusNode = FocusNode();
  List<Widget> dishOptions(List<DishOption> options) {
    return options.map((option) {
      return Material(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(69),
          bottomLeft: Radius.circular(69),
          bottomRight: Radius.circular(69),
        ),
        color: Colors.primaries[option.colourCode],
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            FocusScope.of(context).unfocus();
            chooseOptions();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: Text(
              option.name,
              style: Theme.of(context).textTheme.subtitle.copyWith(
                    color:
                        Colors.primaries[option.colourCode].computeLuminance() <
                                .6
                            ? Colors.white
                            : Colors.black87,
                  ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void chooseOptions() async {
    showCustomDialog(
      context: context,
      dialog: DishOptionDialog(
        controller: Provider.of<DishEditingController>(context),
        index: widget.index,
        dishWithQuantity: widget.dishWithQuantity,
      ),
    );
  }

  void focusListener() {
    if (!_focusNode.hasFocus) {
      _textController.text = widget.dishWithQuantity.quantity.toString();
    }
  }

  void onTextEdit() {
    final quantity = int.tryParse(_textController.text);
    if (quantity != null && quantity != 0) {
      widget.dishWithQuantity.quantity = quantity;
    }
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.dishWithQuantity.quantity.toString(),
    )..addListener(onTextEdit);
    _focusNode.addListener(focusListener);
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.removeListener(focusListener);
    _focusNode.dispose();
    _textController.removeListener(onTextEdit);
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    final controller = Provider.of<DishEditingController>(context);
    final isLast = widget.index == controller.dishes.length - 1;
    return Material(
      type: MaterialType.transparency,
      child: AnimatedContainer(
        duration: 200.milliseconds,
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide(
                    color: Colors.transparent,
                    width: 1,
                  )
                : BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Material(
                  type: MaterialType.circle,
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.add),
                    ),
                    onTap: () {
                      _textController.text =
                          (widget.dishWithQuantity.quantity + 1).toString();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                Container(
                  width: 32,
                  padding: const EdgeInsets.only(left: 2, top: 2),
                  child: EditableText(
                    controller: _textController,
                    focusNode: _focusNode,
                    enableSuggestions: false,
                    cursorColor: Theme.of(context).accentColor,
                    backgroundCursorColor: Theme.of(context).cardColor,
                    cursorOpacityAnimates: true,
                    textAlign: TextAlign.center,
                    scrollPadding: EdgeInsets.zero,
                    style: Theme.of(context)
                        .textTheme
                        .subhead
                        .copyWith(height: 1.3),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      WhitelistingTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
                Material(
                  type: MaterialType.circle,
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.remove),
                    ),
                    onTap: () {
                      if (widget.dishWithQuantity.quantity > 1)
                        _textController.text =
                            (widget.dishWithQuantity.quantity - 1).toString();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 24,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(widget.dishWithQuantity.orderedDish.dish.name),
                  const SizedBox(
                    height: 1,
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, child) {
                      final price = _getPrice(
                        quantity: widget.dishWithQuantity.quantity,
                        unitCost: widget
                            .dishWithQuantity.orderedDish.dish.unitPrice
                            .toDouble(),
                        options:
                            widget.dishWithQuantity.orderedDish.enabledOptions,
                      );
                      return CustomAnimatedSwitcher(
                        child: Text(
                          '\$' + price.toStringAsFixed(2),
                          key: ValueKey(price),
                          style: Theme.of(context).textTheme.subtitle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  CustomAnimatedSwitcher(
                    child: Wrap(
                      key: ValueKey(widget
                          .dishWithQuantity.orderedDish.enabledOptions
                          .join()),
                      spacing: 5,
                      runSpacing: 3,
                      children: [
                        ...dishOptions(
                          widget.dishWithQuantity.orderedDish.enabledOptions,
                        ),
                        if (widget.dishWithQuantity.orderedDish.enabledOptions
                            .isEmpty)
                          Material(
                            shape: ContinuousRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Theme.of(context).cardColor,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(Icons.add, size: 16),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Add Options',
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                    const SizedBox(width: 2),
                                  ],
                                ),
                              ),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                chooseOptions();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 24,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Material(
                type: MaterialType.circle,
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.delete,
                      size: 22,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    controller.removeDish(
                      index: widget.index,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DishOptionDialog extends StatefulWidget {
  final DishEditingController controller;
  final int index;
  final OrderedDishWithQuantity dishWithQuantity;
  const DishOptionDialog({
    Key key,
    @required this.controller,
    @required this.index,
    @required this.dishWithQuantity,
  }) : super(key: key);

  @override
  _DishOptionDialogState createState() => _DishOptionDialogState();
}

class _DishOptionDialogState extends State<DishOptionDialog> {
  @override
  Widget build(BuildContext context) {
    final options = widget.dishWithQuantity.orderedDish.dish.options;
    options.sort((a, b) => a.name.compareTo(b.name));
    final price = _getPrice(
      quantity: widget.dishWithQuantity.quantity,
      unitCost: widget.dishWithQuantity.orderedDish.dish.unitPrice.toDouble(),
      options: widget.dishWithQuantity.orderedDish.enabledOptions,
    );
    return AlertDialog(
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      title: Row(
        children: <Widget>[
          ClipPath(
            clipper: ShapeBorderClipper(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: SizedBox(
              height: 48,
              child: CustomImage(
                widget.dishWithQuantity.orderedDish.dish.image,
                fadeInDuration: null,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.dishWithQuantity.quantity.toString() +
                    '× ' +
                    widget.dishWithQuantity.orderedDish.dish.name,
                style: Theme.of(context).textTheme.subhead,
              ),
              const SizedBox(
                height: 1,
              ),
              CustomAnimatedSwitcher(
                child: Text(
                  '\$${price.toStringAsFixed(2)}',
                  key: ValueKey(price),
                  style: Theme.of(context).textTheme.subtitle,
                ),
              ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var option in options)
            OptionRow(
              option: option,
              selected: widget.dishWithQuantity.orderedDish.enabledOptions
                  .contains(option),
              onTap: () {
                final newOptions = List<DishOption>.from(
                  widget.dishWithQuantity.orderedDish.enabledOptions,
                );
                if (widget.dishWithQuantity.orderedDish.enabledOptions
                    .contains(option)) {
                  newOptions.remove(option);
                } else {
                  newOptions.add(option);
                }
                widget.controller
                    .changeOptions(index: widget.index, options: newOptions);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}

class OptionRow extends StatefulWidget {
  final DishOption option;
  final bool selected;
  final VoidCallback onTap;
  const OptionRow({
    Key key,
    @required this.option,
    @required this.selected,
    @required this.onTap,
  }) : super(key: key);

  @override
  _OptionRowState createState() => _OptionRowState();
}

class _OptionRowState extends State<OptionRow> {
  Color get _textColor {
    if (widget.selected) {
      return Colors.primaries[widget.option.colourCode].computeLuminance() < .6
          ? Colors.white
          : Colors.black87;
    }
    return Colors.primaries[widget.option.colourCode];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedContainer(
              duration: 200.milliseconds,
              decoration: BoxDecoration(
                color: Colors.accents[widget.option.colourCode]
                    .withOpacity(widget.selected ? 1 : 0),
                border: Border.all(
                  color: Colors.primaries[widget.option.colourCode],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(69),
                  bottomLeft: Radius.circular(69),
                  bottomRight: Radius.circular(69),
                ),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(69),
              bottomLeft: Radius.circular(69),
              bottomRight: Radius.circular(69),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      widget.option.name,
                      style: Theme.of(context).textTheme.subtitle.copyWith(
                            color: _textColor,
                          ),
                    ),
                    Text(
                      '\$' + widget.option.addCost.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.subtitle.copyWith(
                            color: _textColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
