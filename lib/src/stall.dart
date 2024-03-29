import '../library.dart';

class Stall extends StatelessWidget {
  final StallId stallId;
  final ValueListenable<double> animation;
  final ScrollController scrollController;
  const Stall({
    Key key,
    @required this.stallId,
    @required this.animation,
    @required this.scrollController,
  }) : super(key: key);

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: <Widget>[
          // This is for the padding animation when user scrolls up to account for the top padding due to status bar or notch
          ValueListenableBuilder(
            valueListenable: animation,
            builder: (context, value, child) {
              return SizedBox(
                height: value.clamp(0.0, 1.0) * context.windowPadding.top,
              );
            },
          ),
          const SizedBox(
            height: 64,
          ),
          Selector<StallMenuMap, StallMenu>(
            selector: (context, stallMenuMap) {
              return stallMenuMap.value[stallId];
            },
            builder: (context, stallMenu, child) {
              // TODO: Update each dish within the stall menu individually
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    8, 8, 8, 16 + context.windowPadding.bottom),
                child: Wrap(
                  children: <Widget>[
                    for (var dish in stallMenu.menu)
                      MenuGridItem(
                        dish: dish,
                      ),
                  ],
                ),
              );
            },
          ),
          // Padding for the order sheet
          ValueListenableBuilder(
            valueListenable:
                context.get<OrderSheetController>(listen: false).altAnimation,
            builder: (context, value, child) {
              return SizedBox(
                height: value < 0 ? 0 : 66.0 + 12,
              );
            },
          ),
        ],
      ),
    );
  }
}

class StallImage extends StatefulWidget {
  final StallId stallId;
  final int index;
  final Animation<double> defaultAnimation; // From CustomButtomSheet
  final ValueListenable<double> animation;
  final PageController pageController;
  final bool last;
  const StallImage({
    Key key,
    @required this.stallId,
    @required this.index,
    @required this.defaultAnimation,
    @required this.animation,
    @required this.pageController,
    this.last: false,
  }) : super(key: key);

  @override
  _StallImageState createState() => _StallImageState();
}

class _StallImageState extends State<StallImage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.animation,
      builder: (context, value, child) {
        double height;
        double y = 0;
        if (value < 0)
          height =
              widget.defaultAnimation.value * context.windowSize.height + 32;
        else {
          final double width = context.windowSize.width;
          height = width / 2560 * 1600 + 32;
          y = value * -(width / 2560 * 1600 + 32) / 2;
        }
        return Transform.translate(
          offset: Offset(0, y),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: height,
              child: child,
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: widget.pageController,
        builder: (context, child) {
          final offset = widget.pageController.offset;
          final width = context.windowSize.width;
          final imageOffset =
              (offset / width - widget.index).clamp(-1.0, 1.0) / 2;
          bool clipping = true;
          double scale = 1;
          Alignment alignment = Alignment.centerLeft;
          if (widget.index == 0 && imageOffset < 0) {
            clipping = false;
            scale -= imageOffset;
          } else if (widget.last && imageOffset > 0) {
            clipping = false;
            alignment = Alignment.centerRight;
            scale += imageOffset;
          }
          return Material(
            clipBehavior: clipping ? Clip.hardEdge : Clip.none,
            child: Transform.translate(
              offset: Offset(imageOffset * width * (clipping ? 1 : 2), 0),
              child: Transform.scale(
                scale: scale,
                alignment: alignment,
                child: child,
              ),
            ),
          );
        },
        child: OverflowBox(
          minWidth: context.windowSize.width,
          maxWidth: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.theme.dividerColor,
            ),
            child: Selector<StallDetailsMap, String>(
              selector: (context, stallDetailsMap) {
                return stallDetailsMap.value[widget.stallId].image;
              },
              builder: (context, image, child) {
                return CustomImage(
                  image,
                  fallbackMemoryImage: kErrorLandscapeImage,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class DishImage extends StatefulWidget {
  final Dish dish;

  /// For hero animation
  final Animation<double> animation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DishImage({
    Key key,
    @required this.dish,
    this.onTap,
    this.onLongPress,
    this.animation,
  }) : super(key: key);

  @override
  _DishImageState createState() => _DishImageState();
}

class _DishImageState extends State<DishImage> {
  final _gradientColors = [
    Colors.black.withOpacity(1),
    Colors.black.withOpacity(.917),
    Colors.black.withOpacity(.834),
    Colors.black.withOpacity(.753),
    Colors.black.withOpacity(.672),
    Colors.black.withOpacity(.591),
    Colors.black.withOpacity(.511),
    Colors.black.withOpacity(.433),
    Colors.black.withOpacity(.357),
    Colors.black.withOpacity(.283),
    Colors.black.withOpacity(.213),
    Colors.black.withOpacity(.147),
    Colors.black.withOpacity(.089),
    Colors.black.withOpacity(.042),
    Colors.black.withOpacity(.011),
    Colors.transparent,
  ];

  final _gradientStops = [
    0.0,
    0.053,
    0.106,
    0.159,
    0.213,
    0.268,
    0.325,
    0.384,
    0.445,
    0.509,
    0.577,
    0.65,
    0.729,
    0.814,
    0.906,
    1.0,
  ];

  /// Whether the main button is pressed, to correctly apply a shadow onto the button
  final _isPressed = ValueNotifier(false);

  /// Whether the remove button is pressed
  final _removeIsPressed = ValueNotifier(false);

  @override
  void dispose() {
    _isPressed.dispose();
    _removeIsPressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.get<CartModel>(listen: false);
    final anim = widget.animation?.drive(
          Tween(begin: 1.0, end: 0.0),
        ) ??
        AlwaysStoppedAnimation(1);
    return Stack(
      overflow: Overflow.visible,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: ValueListenableBuilder<bool>(
            valueListenable: _isPressed,
            builder: (context, value, child) {
              return Material(
                color: context.theme.dividerColor,
                elevation: value ? 8 : 0,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              );
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomImage(
                widget.dish.image,
                fallbackMemoryImage: kErrorImage,
                fadeInDuration: 300.milliseconds,
              ),
            ),
          ),
        ),
        Positioned.fill(
          top: 8,
          right: 8,
          left: 8,
          child: FadeTransition(
            opacity: anim,
            child: IgnorePointer(
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Selector<CartModel, int>(
                  selector: (context, cart) {
                    final relevantDishes =
                        cart.getOrderedDishesFrom(widget.dish);
                    if (relevantDishes.isEmpty) return null;
                    return relevantDishes.map((dishOrder) {
                      return cart.orders[widget.dish.stallId][dishOrder];
                    }).reduce((a, b) => a + b);
                  },
                  builder: (context, quantity, child) {
                    return Stack(
                      children: <Widget>[
                        AnimatedContainer(
                          duration: 200.milliseconds,
                          decoration: BoxDecoration(
                            gradient: quantity != null
                                ? LinearGradient(
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                    colors: _gradientColors,
                                    stops: _gradientStops
                                        .map((i) => i / 3)
                                        .toList(),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: CustomAnimatedSwitcher(
                            child: quantity != null
                                ? Text(
                                    '$quantity',
                                    key: ValueKey(quantity),
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  )
                                : SizedBox.shrink(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (widget.onTap != null || widget.onLongPress != null)
          Positioned.fill(
            top: 8,
            right: 8,
            left: 8,
            child: Material(
              type: MaterialType.transparency,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (widget.onTap != null) widget.onTap();
                  _isPressed.value = false;
                },
                onTapDown: (_) {
                  _isPressed.value = true;
                },
                onTapCancel: () {
                  _isPressed.value = false;
                },
                onLongPress: () {
                  if (widget.onLongPress != null) widget.onLongPress();
                  _isPressed.value = false;
                },
              ),
            ),
          ),
        ScaleTransition(
          scale: anim,
          child: Selector<CartModel, DishOrder>(
            selector: (context, cart) {
              // TODO: optimise this
              final relevantDishes = cart.getOrderedDishesFrom(widget.dish);
              if (relevantDishes.isEmpty) return null;
              return relevantDishes.first;
            },
            builder: (context, dishOrder, child) {
              return AnimatedScale(
                scale: dishOrder != null ? 1 : 0,
                opacity: dishOrder != null ? 1 : .5,
                child: GestureDetector(
                  onTap: () {
                    cart.removeDish(
                      context: context,
                      dishOrder: dishOrder,
                    );
                    _removeIsPressed.value = false;
                  },
                  onTapDown: (_) => _removeIsPressed.value = true,
                  onTapCancel: () => _removeIsPressed.value = false,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _removeIsPressed,
                  builder: (context, value, child) {
                    return AnimatedContainer(
                      duration: value ? 100.milliseconds : 300.milliseconds,
                      decoration: BoxDecoration(
                        color: value
                            ? Color.lerp(
                                context.theme.scaffoldBackgroundColor,
                                context.theme.accentColor,
                                .4,
                              )
                            : context.theme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.remove, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MenuGridItem extends StatelessWidget {
  final Dish dish;
  const MenuGridItem({
    Key key,
    @required this.dish,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final secondaryAnimation = ModalRoute.of(context).secondaryAnimation;
    final _defaultOrderedDish = DishOrder(
      dish: dish,
      enabledOptions: [],
    );
    final cart = context.get<CartModel>(listen: false);
    final cardWidth = (context.windowSize.width - 16.0) / 2;
    return Column(
      children: <Widget>[
        SizedBox(
          width: cardWidth,
          child: Hero(
            tag: dish.toString(),
            createRectTween: (a, b) {
              return MaterialRectCenterArcTween(begin: a, end: b);
            },
            child: Material(
              type: MaterialType.transparency,
              child: DishImage(
                dish: dish,
                animation: secondaryAnimation,
                onTap: () {
                  cart.addDish(
                    context: context,
                    dishOrder: _defaultOrderedDish,
                  );
                },
                onLongPress: () {
                  Navigator.pushNamed(
                    context,
                    '/dishEdit',
                    arguments: DishEditScreenArguments(
                      tag: dish.toString(),
                      dish: dish,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(dish.name),
        Text(
          '\$${dish.unitPrice.toStringAsFixed(2)}',
          style: context.theme.textTheme.subtitle,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
