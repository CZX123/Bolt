import '../library.dart';

/// The [CartModel] is equivalent to a shopping cart, and stores all the user orders.
///
/// It contains 2 getters:
/// - [orders] (the main one used)
/// - [orderThumbnails] (used for the [OrderPreview])
///
/// It also exposes 3 methods:
/// - [setOrders], which replaces the _orders variable with a new set of orders. Used after editing a dish in the [DishEditScreen], or clearing all orders
/// - [addDish], which takes in the [StallId] and [OrderedDish], and only adds one [OrderedDish]
/// - [removeDish], which also takes in the [StallId] and [OrderedDish], and only removes one unit of the [OrderedDish] specified
class CartModel extends ChangeNotifier {
  CartModel();

  final _orders = Orders();
  Orders get orders => _orders;
  void setOrders({BuildContext context, Orders orders}) {
    if (_orders == orders) return;
    if (orders == null) {
      if (_orders.value.isNotEmpty) _orders.value = {};
      return;
    }
    // Handle order sheet
    if (_orders.value.isEmpty && orders.value.isNotEmpty) {
      final orderSheetController =
          Provider.of<BottomSheetController>(context, listen: false);
      // Animate order sheet if it is hidden
      if (orderSheetController.altAnimation.value < 0) {
        orderSheetController.animateTo(BottomSheetPosition.end);
      }
    } else if (orders.value.isEmpty) {
      // Hide order sheet
      final orderSheetController =
          Provider.of<BottomSheetController>(context, listen: false);
      orderSheetController.animateTo(BottomSheetPosition.hidden);
    }
    _orders.value = orders.value;
    // Also replace orderThumbnails by iterating through [orders]
    _orderThumbnails = [];
    orders.value.forEach((stallId, dishMap) {
      dishMap.forEach((orderedDish, quantity) {
        _orderThumbnails.add(orderedDish.dish.image);
      });
    });
    notifyListeners();
  }

  List<String> _orderThumbnails = [];
  List<String> get orderThumbnails => _orderThumbnails;

  /// Gets position of a [OrderedDish] in [_orders] to correctly add or remove a thumbnail from [_orderThumbnails]
  int _getIndex(StallId stallId, OrderedDish orderedDish) {
    assert(_orders.value.containsKey(stallId));
    assert(_orders.value[stallId].containsKey(orderedDish));
    int index = 0;
    for (var id in _orders.value.keys) {
      if (id == stallId) break;
      index += _orders.value[id].length;
    }
    index += _orders.value[stallId].keys.toList().indexOf(orderedDish);
    return index;
  }

  void _addThumbnail(StallId stallId, OrderedDish orderedDish) {
    _orderThumbnails.insert(
      _getIndex(stallId, orderedDish),
      orderedDish.dish.image,
    );
  }

  /// Note: Need to call this before removing the actual [OrderedDish], else it will not be able to find the index because it does not exist
  void _removeThumbnail(StallId stallId, OrderedDish orderedDish) {
    _orderThumbnails.removeAt(_getIndex(stallId, orderedDish));
  }

  /// Adds one [OrderedDish] to [_orders]
  void addDish({
    BuildContext context,
    StallId stallId,
    OrderedDish orderedDish,
  }) {
    if (_orders.value.isEmpty) {
      final orderSheetController = Provider.of<BottomSheetController>(context);
      // Animate order sheet if it is hidden
      if (orderSheetController.altAnimation.value < 0) {
        orderSheetController.animateTo(BottomSheetPosition.end);
      }
    }

    /// Checks if the [StallId] is already in the [_orders]
    if (_orders.value.containsKey(stallId)) {
      /// If the [OrderedDish] is already inside [_orders], then there is no need to update [_orderThumbnails], and only need to increase quantity by 1
      if (_orders.value[stallId].containsKey(orderedDish)) {
        _orders.value[stallId][orderedDish] += 1;
      }

      /// Else need to add the image of the dish to [_orderThumbnails]
      else {
        _orders.value[stallId][orderedDish] = 1;
        _addThumbnail(stallId, orderedDish);
      }
    } else {
      _orders.value[stallId] = {};
      _orders.value[stallId][orderedDish] = 1;
      _addThumbnail(stallId, orderedDish);
    }
    notifyListeners();
  }

  /// Removes only one unit of a specific dish
  void removeDish({
    BuildContext context,
    StallId stallId,
    OrderedDish orderedDish,
  }) {
    // Return if dish already does not exist
    if (!_orders.value.containsKey(stallId) ||
        !_orders.value[stallId].containsKey(orderedDish)) {
      return;
    }
    _orders.value[stallId][orderedDish] -= 1;
    // If new quantity is zero, remove the dish entirely
    if (_orders.value[stallId][orderedDish] <= 0) {
      _removeThumbnail(stallId, orderedDish);
      _orders.value[stallId].remove(orderedDish);

      /// Remove stall id as well if the list of [OrderedDish] in the stall is empty
      if (_orders.value[stallId].isEmpty) _orders.value.remove(stallId);
      if (orders.value.isEmpty) {
        // Hide order sheet
        final orderSheetController =
            Provider.of<BottomSheetController>(context, listen: false);
        orderSheetController.animateTo(BottomSheetPosition.hidden);
      }
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
//   Map<OrderedDish, int> dishQuantities;
//   Order({
//     this.ordered = false,
//     this.id,
//     this.dateTime,
//     this.studentId,
//     this.stallId,
//     this.dishQuantities,
//   });
// }

/// A wrapper class that contains all the orders in the shopping cart. It is a wrapper for a [Map<StallId, Map<OrderedDish, int>>]
class Orders {
  // Structure:
  // {
  //   stallid1: {
  //     dish1: quantity,
  //     dish2: quantity,
  //   },
  //   stallid2: {
  //     dish3: quantity,
  //   },
  // }
  // ^ This structure is preferred, because it groups orders according to the different stalls for easy presentation, as well as when sending the orders to the respective stalls
  Map<StallId, Map<OrderedDish, int>> value = {};

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Orders && mapEquals(value, other.value);
  }

  @override
  int get hashCode => value.hashCode;
}

/// An [OrderedDish] contains the relevant [Dish] the user ordered, as well as the [DishOption]s that they have chosen
class OrderedDish {
  final Dish dish;
  final List<DishOption> enabledOptions;
  const OrderedDish({this.dish, this.enabledOptions});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrderedDish &&
            this.dish == other.dish &&
            listEquals(this.enabledOptions, other.enabledOptions);
  }

  @override
  int get hashCode => hashValues(dish, hashList(enabledOptions));
}
