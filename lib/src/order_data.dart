import '../library.dart';

class OrderNotifier extends ChangeNotifier {
  OrderNotifier();

  List<Order> _orders = [];
  List<Order> get orders => _orders;
  List<List> _orderHistory = [];
  List<List> get orderHistory => _orderHistory;

  void clearOrderHistory() {
    _orderHistory = [];
  }

  void addOrder(Order order) {
    _orderHistory.add([true, _orders.length, order]);
    _orders.add(order);
    notifyListeners();
  }

  void removeOrder(Order order) {
    _orderHistory.add([false, _orders.indexOf(order), order]);
    _orders.remove(order);
    notifyListeners();
  }

  void clearOrders() {
    _orders = [];
    notifyListeners();
  }
}

class ShoppingCartNotifier extends ChangeNotifier {
  ShoppingCartNotifier();

  GlobalKey<AnimatedListState> animatedListKey;

  // List<Order> _orders = [];
  // List<Order> get orders => _orders;

  Map<int, Map<DishWithOptions, int>> _orders = {};
  Map<int, Map<DishWithOptions, int>> get orders => _orders;

  List<String> _orderThumbnails = [];
  List<String> get orderThumbnails => _orderThumbnails;

  Widget Function(BuildContext, Animation<double>) _builder(
      String image) {
    return (context, animation) {
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

  // void addDish(int stallId, OrderedDish orderedDish) {
  //   var i = _orders.indexWhere((order) => order.stallId == stallId);
  //   if (i == -1) {
  //     _orders.add(Order(
  //       studentId: 1,
  //       stallId: stallId,
  //       dishList: [orderedDish],
  //     ));
  //   } else {
  //     var j = _orders[i].dishList.indexWhere((_orderedDish) {
  //       return _orderedDish.dish == orderedDish.dish &&
  //           listEquals(_orderedDish.enabledOptions, orderedDish.enabledOptions);
  //     });
  //     if (j == -1) {
  //       _orders[i].dishList.add(orderedDish);
  //     } else {
  //       _orders[i].dishList[j].quantity += orderedDish.quantity;
  //     }
  //   }
  // }

  // var stuff = {
  //   0: {
  //     'dishWithOptions': 1,
  //   },
  // };

  void addDish(int stallId, DishWithOptions dishWithOptions, [int count = 1]) {
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
            animatedListKey.currentState.insertItem(index);
          else if (index < 4) {
            animatedListKey.currentState.insertItem(index);
            animatedListKey.currentState
                .removeItem(4, _builder(_orderThumbnails[4]));
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
          animatedListKey.currentState.insertItem(index);
        else if (index < 4) {
          animatedListKey.currentState.insertItem(index);
          animatedListKey.currentState
              .removeItem(4, _builder(_orderThumbnails[4]));
        }
      }
    }
    notifyListeners();
  }

  void editDish(
    int stallId,
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
    int stallId,
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
        animatedListKey.currentState
            .removeItem(index, _builder(dishWithOptions.dish.image));
        if (_orderThumbnails.length > 5) {
          animatedListKey.currentState.insertItem(3);
        } else if (_orderThumbnails.length == 5) {
          animatedListKey.currentState.insertItem(4);
        }
      }
    } else {
      _orders[stallId][dishWithOptions] -= 1;
    }
    notifyListeners();
  }

  // void editDish(int stallId, int j, int newQuantity, List<int> newOptions) {
  //   var i = _orders.indexWhere((order) => order.stallId == stallId);
  //   _orders[i].dishList[j].quantity = newQuantity;
  //   _orders[i].dishList[j].enabledOptions = newOptions;
  // }

  // void removeDish(int stallId, int j) {
  //   var i = _orders.indexWhere((order) => order.stallId == stallId);
  //   _orders[i].dishList.removeAt(j);
  // }

  // void removeDishWhere(int stallId, Dish dish) {
  //   var i = _orders.indexWhere((order) => order.stallId == stallId);
  //   _orders[i].dishList.removeWhere((_orderedDish) {
  //     return _orderedDish.dish == dish;
  //   });
  // }

  // void collapse(List<OrderedDish> orderedDishes) {
  //   for (var i = 0; i < orderedDishes.length; i++) {
  //     if (orderedDishes[i] == null) continue;
  //     for (var j = 1; j < orderedDishes.length - i; j++) {
  //       if (orderedDishes[i + j] == null) continue;
  //       if (orderedDishes[i].dish == orderedDishes[i + j].dish &&
  //           listEquals(orderedDishes[i].enabledOptions,
  //               orderedDishes[i + j].enabledOptions)) {
  //         orderedDishes[i].quantity += orderedDishes[i + j].quantity;
  //         orderedDishes[i + j] = null;
  //       }
  //     }
  //   }
  //   orderedDishes.removeWhere((orderedDish) => orderedDish == null);
  // }
}

// TODO: Add more necessary stuff to this Order class, e.g. person who ordered, quantity, additional options
// class Order {
//   final String stallName;
//   final MenuItem menuItem;
//   Order({this.stallName, this.menuItem});
//   @override
//   String toString() {
//     return 'Order(stallName: $stallName, menuItem: $menuItem)';
//   }
// }
// An [Order] is a receipt, a collection of dishes ordered from one specific stall. Each order will also have one specific time.
class Order {
  final bool ordered; // Whether order is confirmed
  final int id;
  final DateTime dateTime;
  final int studentId;
  final int stallId;
  Map<DishWithOptions, int> dishQuantities;
  Order({
    this.ordered = false,
    this.id,
    this.dateTime,
    this.studentId,
    this.stallId,
    this.dishQuantities,
  });
}

// // An [OrderedDish] contains a dish, with chosen options
// class OrderedDish {
//   int quantity;
//   final Dish dish;
//   List<int> enabledOptions;
//   OrderedDish({this.quantity, this.dish, this.enabledOptions});
//   bool operator ==(Object other) {
//     return identical(this, other) ||
//         other is OrderedDish &&
//             this.quantity == other.quantity &&
//             this.dish == other.dish &&
//             listEquals(this.enabledOptions, other.enabledOptions);
//   }

//   @override
//   int get hashCode => hashValues(quantity, dish, hashList(enabledOptions));
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
