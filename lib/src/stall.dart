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
    EdgeInsets windowPadding = Provider.of<EdgeInsets>(context);
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
                height: value.clamp(0.0, 1.0) * windowPadding.top,
              );
            },
          ),
          const SizedBox(
            height: 80,
          ),
          Selector<StallMenuMap, StallMenu>(
            selector: (context, stallMenuMap) {
              return stallMenuMap.value[stallId];
            },
            builder: (context, stallMenu, child) {
              // TODO: Update each dish within the stall menu individually
              return Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 128),
                child: Wrap(
                  spacing: 8.0,
                  children: <Widget>[
                    for (var dish in stallMenu.menu)
                      MenuGridItem(
                        stallId: stallId,
                        dish: dish,
                      ),
                  ],
                ),
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
          height = widget.defaultAnimation.value *
                  MediaQuery.of(context).size.height +
              32;
        else {
          final double width = MediaQuery.of(context).size.width;
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
          final width = MediaQuery.of(context).size.width;
          final imageOffset = (offset / width - widget.index).clamp(-1.0, 1.0) / 2;
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
          minWidth: MediaQuery.of(context).size.width,
          maxWidth: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
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

class MenuGridItem extends StatelessWidget {
  final StallId stallId;
  final Dish dish;
  const MenuGridItem({
    Key key,
    @required this.stallId,
    @required this.dish,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 8.0 * 3) / 2;
    final shadowNotifier = ValueNotifier(0.0);
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 6.0,
      ),
      child: Column(
        children: <Widget>[
          Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              ValueListenableBuilder(
                valueListenable: shadowNotifier,
                builder: (context, value, child) {
                  return Material(
                    color: Theme.of(context).dividerColor,
                    elevation: value,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: child,
                  );
                },
                child: Hero(
                  tag: '$stallId ${dish.id}',
                  createRectTween: (a, b) => MaterialRectCenterArcTween(begin: a, end: b),
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: SizedBox(
                      height: cardWidth,
                      width: cardWidth,
                      child: CustomImage(
                        dish.image,
                        fallbackMemoryImage: kErrorImage,
                        fadeInDuration: const Duration(milliseconds: 300),
                      ),
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    final orderSheetController = Provider.of<BottomSheetController>(context);
                    // Animate order sheet if it is hidden
                    if (orderSheetController.altAnimation.value < 0) {
                      orderSheetController.animateTo(BottomSheetPosition.end);
                    }
                    // Add the dish to cart
                    Provider.of<CartModel>(context, listen: false)
                        .addDish(
                      stallId,
                      DishWithOptions(
                        dish: dish,
                        enabledOptions: [
                          ...dish.options,
                        ],
                      ),
                    );
                    shadowNotifier.value = 0;
                  },
                  onTapDown: (_) {
                    shadowNotifier.value = 8;
                  },
                  onTapCancel: () {
                    shadowNotifier.value = 0;
                  },
                  onLongPress: () {
                    // Provider.of<CartModel>(context, listen: false)
                    //     .removeDish(
                    //   stallId,
                    //   DishWithOptions(
                    //     dish: dish,
                    //     enabledOptions: [
                    //       ...dish.options,
                    //     ],
                    //   ),
                    // );
                    final windowPadding =
                        Provider.of<EdgeInsets>(context, listen: false);
                    Navigator.push(
                      context,
                      CrossFadePageRoute(
                        builder: (context) {
                          return Provider.value(
                            value: windowPadding,
                            child: DishEditScreen(
                              tag: '$stallId ${dish.id}',
                              dish: dish,
                              stallId: stallId,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: SizedBox(
                    width: cardWidth,
                    height: cardWidth,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 6.0,
          ),
          Text(dish.name),
          Text(
            '\$${dish.unitPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.subtitle,
          ),
        ],
      ),
    );
  }
}
