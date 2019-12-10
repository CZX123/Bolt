import '../library.dart';

class ShoppingCartNotifier extends ChangeNotifier {
  ShoppingCartNotifier();

  GlobalKey<AnimatedListState> animatedListKey;

  // List<Order> _orders = [];
  // List<Order> get orders => _orders;

  Map<StallId, Map<DishWithOptions, int>> _orders = {};
  Map<StallId, Map<DishWithOptions, int>> get orders => _orders;

  List<String> _orderThumbnails = [];
  List<String> get orderThumbnails => _orderThumbnails;

  Widget Function(BuildContext, Animation<double>) _builder(String image) {
    return (context, animation) {
      return SizeTransition(
        axis: Axis.horizontal,
        sizeFactor: CurvedAnimation(
          curve: Curves.fastOutSlowIn.flipped,
          parent: animation,
        ),
        child: ScaleTransition(
          scale: CurvedAnimation(
            curve: Curves.fastOutSlowIn.flipped,
            parent: animation,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: SizedBox(
                height: 48,
                child: CustomImage(
                  image,
                  fadeInDuration: null,
                  fallbackMemoryImage: kErrorImage,
                ),
              ),
            ),
          ),
        ),
      );
    };
  }

  void addDish(
    StallId stallId,
    DishWithOptions dishWithOptions, [
    int count = 1,
  ]) {
    if (_orders.containsKey(stallId)) {
      if (_orders[stallId].containsKey(dishWithOptions)) {
        _orders[stallId][dishWithOptions] += count;
      } else {
        _orders[stallId][dishWithOptions] = count;
        int index = 0;
        for (var id in _orders.keys) {
          if (id == stallId) break;
          index += _orders[id].length;
        }
        index += _orders[stallId].keys.toList().indexOf(dishWithOptions);
        _orderThumbnails.insert(index, dishWithOptions.dish.image);
        if (animatedListKey != null && animatedListKey.currentState.mounted) {
          if (_orderThumbnails.length <= 5)
            animatedListKey.currentState.insertItem(
              index,
              duration: const Duration(milliseconds: 200),
            );
          else if (index < 4) {
            animatedListKey.currentState.insertItem(
              index,
              duration: const Duration(milliseconds: 200),
            );
            animatedListKey.currentState.removeItem(
              4,
              _builder(_orderThumbnails[4]),
              duration: const Duration(milliseconds: 200),
            );
          }
        }
      }
    } else {
      _orders[stallId] = {};
      _orders[stallId][dishWithOptions] = 1;
      int index = 0;
      for (var id in _orders.keys) {
        if (id == stallId) break;
        index += _orders[id].length;
      }
      index += _orders[stallId].keys.toList().indexOf(dishWithOptions);
      _orderThumbnails.insert(index, dishWithOptions.dish.image);
      if (animatedListKey != null && animatedListKey.currentState.mounted) {
        if (_orderThumbnails.length <= 5)
          animatedListKey.currentState.insertItem(
            index,
            duration: const Duration(milliseconds: 200),
          );
        else if (index < 4) {
          animatedListKey.currentState.insertItem(
            index,
            duration: const Duration(milliseconds: 200),
          );
          animatedListKey.currentState.removeItem(
            4,
            _builder(_orderThumbnails[4]),
            duration: const Duration(milliseconds: 200),
          );
        }
      }
    }
    notifyListeners();
  }

  void editDish(
    StallId stallId,
    DishWithOptions dishWithOptions,
    int newQuantity,
  ) {
    if (!_orders.containsKey(stallId) ||
        !_orders[stallId].containsKey(dishWithOptions)) {
      addDish(stallId, dishWithOptions, newQuantity);
    } else if (newQuantity != null &&
        newQuantity != _orders[stallId][dishWithOptions]) {
      _orders[stallId][dishWithOptions] = newQuantity;
      notifyListeners();
    }
  }

  // By default only subtract one dish
  void removeDish(
    StallId stallId,
    DishWithOptions dishWithOptions, [
    bool removeEntirely = false,
  ]) {
    if (!_orders.containsKey(stallId)) return;
    final dishIndex = _orders[stallId].keys.toList().indexOf(dishWithOptions);
    if (dishIndex == -1) return;
    if (removeEntirely || _orders[stallId][dishWithOptions] <= 1) {
      int index = dishIndex;
      for (var id in _orders.keys) {
        if (id == stallId) break;
        index += _orders[id].length;
      }
      _orders[stallId].remove(dishWithOptions);
      if (_orders[stallId].isEmpty) _orders.remove(stallId);
      _orderThumbnails.removeAt(index);
      if (animatedListKey != null &&
          animatedListKey.currentState.mounted &&
          (_orderThumbnails.length < 5 || index < 4)) {
        animatedListKey.currentState.removeItem(
          index,
          _builder(dishWithOptions.dish.image),
          duration: const Duration(milliseconds: 200),
        );
        if (_orderThumbnails.length > 5) {
          animatedListKey.currentState.insertItem(
            3,
            duration: const Duration(milliseconds: 200),
          );
        } else if (_orderThumbnails.length == 5) {
          animatedListKey.currentState.insertItem(
            4,
            duration: const Duration(milliseconds: 200),
          );
        }
      }
    } else {
      _orders[stallId][dishWithOptions] -= 1;
    }
    notifyListeners();
  }
}
// An [Order] is a receipt, a collection of dishes ordered from one specific stall. Each order will also have one specific time.
// class Order {
//   final bool ordered; // Whether order is confirmed
//   final int id;
//   final DateTime dateTime;
//   final int studentId;
//   final int stallId;
//   Map<DishWithOptions, int> dishQuantities;
//   Order({
//     this.ordered = false,
//     this.id,
//     this.dateTime,
//     this.studentId,
//     this.stallId,
//     this.dishQuantities,
//   });
// }

class DishWithOptions {
  final Dish dish;
  final List<DishOption> enabledOptions;
  DishWithOptions({this.dish, this.enabledOptions});
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DishWithOptions &&
            this.dish == other.dish &&
            listEquals(this.enabledOptions, other.enabledOptions);
  }

  @override
  int get hashCode => hashValues(dish, hashList(enabledOptions));
}
