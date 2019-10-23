import '../library.dart';

class DishEditNotifier extends ChangeNotifier {
  Dish dish;
  List<QuantityDishOptions> _dishes = [];
  List<QuantityDishOptions> get dishes => _dishes;
  set dishes(List<QuantityDishOptions> dishes) {
    _dishes = dishes;
    notifyListeners();
  }

  void addDish() {
    _dishes.add(QuantityDishOptions(
      dish: dish,
      quantity: 1,
      enabledOptions: [],
    ));
    notifyListeners();
  }

  void removeDish(QuantityDishOptions dish) {
    _dishes.remove(dish);
    notifyListeners();
  }
}

class QuantityDishOptions {
  int quantity;
  final Dish dish;
  List<DishOption> enabledOptions;
  QuantityDishOptions({this.quantity, this.dish, this.enabledOptions});
}

class DishEditScreen extends StatefulWidget {
  final int stallId;
  final Dish dish;
  const DishEditScreen({
    Key key,
    @required this.stallId,
    @required this.dish,
  }) : super(key: key);

  @override
  _DishEditScreenState createState() => _DishEditScreenState();
}

class _DishEditScreenState extends State<DishEditScreen> {
  final _animatedListKey = GlobalKey<AnimatedListState>();
  final dishEditNotifier = DishEditNotifier();
  // Treat the map here as a tuple
  List<QuantityDishOptions> dishes = [];
  bool loaded = false;

  void addDish() {
    _animatedListKey.currentState.insertItem(dishes.length);
    dishes.add(QuantityDishOptions(
      dish: widget.dish,
      quantity: 1,
      enabledOptions: [],
    ));
  }

  void removeDish(int index) {
    final dish = dishes[index];
    final isLast = index == dishes.length - 1;
    _animatedListKey.currentState.removeItem(
      index,
      (context, animation) {
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
            child: DishEditRow(
              isLast: isLast,
              dish: dish,
              removeDish: () {},
            ),
          ),
        );
      },
    );
    dishes.removeAt(index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      loaded = true;
      final orders =
          Provider.of<ShoppingCartNotifier>(context, listen: false).orders;
      orders[widget.stallId]?.forEach((dish, quantity) {
        if (dish.dish == widget.dish) {
          dishes.add(QuantityDishOptions(
            quantity: quantity,
            dish: dish.dish,
            enabledOptions: dish.enabledOptions,
          ));
        }
      });
      dishEditNotifier.dish = widget.dish;
      dishEditNotifier.dishes = dishes;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final topPadding = Provider.of<EdgeInsets>(context).top;
    final stallList = Provider.of<List<StallDetails>>(context, listen: false);
    final stallName = stallList.firstWhere((stall) {
      return stall.id == widget.stallId;
    }).name;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: topPadding,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipPath(
                  clipper: ShapeBorderClipper(
                      shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: SizedBox(
                    height: 80,
                    child: FirebaseImage(
                      widget.dish.image,
                      fadeInDuration: null,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  stallName,
                  style: Theme.of(context).textTheme.display1.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  widget.dish.name,
                  style: Theme.of(context).textTheme.display2,
                ),
              ],
            ),
            Container(
              constraints: BoxConstraints(
                minHeight: height - topPadding - 96 - 104 - 35 * 1.2 - 80,
                maxHeight: double.infinity,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedList(
                    key: _animatedListKey,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    initialItemCount: dishes.length,
                    itemBuilder: (context, index, animation) {
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
                          child: DishEditRow(
                            isLast: index == dishes.length - 1,
                            dish: dishes[index],
                            removeDish: () {
                              removeDish(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  RaisedButton(
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
                    onPressed: addDish,
                  ),
                ],
              ),
            ),
            Container(
              height: 96,
              padding: const EdgeInsets.only(top: 32),
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
                    width: 32,
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
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DishEditRow extends StatefulWidget {
  final bool isLast;
  final QuantityDishOptions dish;
  final VoidCallback removeDish;
  const DishEditRow({
    Key key,
    @required this.dish,
    @required this.removeDish,
    this.isLast,
  }) : super(key: key);

  @override
  _DishEditRowState createState() => _DishEditRowState();
}

class _DishEditRowState extends State<DishEditRow> {
  TextEditingController _textController;
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

  void chooseOption() async {
    // TODO:
    List<DishOption> options = await showCustomDialog(
      context: context,
      dialog: DishOptionDialog(
        dish: widget.dish,
      ),
    );
  }

  void addRemoveQuantity(bool add) {
    if (add)
      widget.dish.quantity += 1;
    else if (widget.dish.quantity > 1) widget.dish.quantity -= 1;
    _textController.text = widget.dish.quantity.toString();
  }

  void onTextEdit() {
    final quantity = int.tryParse(_textController.text);
    if (quantity != null) {
      widget.dish.quantity = quantity;
    }
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.dish.quantity.toString(),
    )..addListener(onTextEdit);
  }

  @override
  void dispose() {
    super.dispose();
    _textController.removeListener(onTextEdit);
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    num price = widget.dish.dish.unitPrice;
    widget.dish.enabledOptions.forEach((option) {
      price += option.addCost;
    });
    price *= widget.dish.quantity;
    return Material(
      type: MaterialType.transparency,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border(
            bottom: widget.isLast != null && widget.isLast
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
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
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
                      addRemoveQuantity(true);
                    },
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Material(
                    type: MaterialType.transparency,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        fillColor: Theme.of(context).cardColor,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                      ),
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.bottom,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        WhitelistingTextInputFormatter.digitsOnly
                      ],
                      enableInteractiveSelection: false,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 4,
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
                      addRemoveQuantity(false);
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
                  Text(widget.dish.dish.name),
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
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      ...dishOptions(context, widget.dish.enabledOptions),
                      if (widget.dish.enabledOptions.isEmpty)
                        Material(
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Theme.of(context).cardColor,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.add, size: 20),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Add Options',
                                    style: Theme.of(context).textTheme.subtitle.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                              ),
                            ),
                            onTap: () {
                              // Option selection
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 2,
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
                    child: const Icon(Icons.delete),
                  ),
                  onTap: widget.removeDish,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DishOptionDialog extends StatelessWidget {
  final QuantityDishOptions dish;
  const DishOptionDialog({Key key, @required this.dish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    num price = dish.dish.unitPrice;
    dish.enabledOptions.forEach((option) {
      price += option.addCost;
    });
    price *= dish.quantity;
    final priceNotifier = ValueNotifier(price);
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(dish.quantity.toString() + '× ' + dish.dish.name),
              const SizedBox(
                height: 1,
              ),
              ValueListenableBuilder(
                valueListenable: priceNotifier,
                builder: (context, value, child) {
                  return CustomAnimatedSwitcher(
                    crossShrink: false,
                    child: Text(
                      '\$${value.toStringAsFixed(2)}',
                      key: value,
                      style: Theme.of(context).textTheme.subtitle,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
