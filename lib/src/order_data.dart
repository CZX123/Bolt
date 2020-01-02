import '../library.dart';

/// The [CartModel] is equivalent to a shopping cart, and stores all the user orders.
///
/// It contains 2 getters:
/// - [orders] (the main one used)
/// - [orderThumbnails] (used for the [OrderPreview])
///
/// It also exposes a few methods:
/// - [orderThumbnails], used in [OrderPreview]
/// - [addDish], which takes in the [StallId] and [DishOrder], and usually adds one [DishOrder]
/// - [removeDish], which also takes in the [StallId] and [DishOrder], and only removes one unit of the [DishOrder] specified
/// - [replaceDish], used in the [DishEditScreen], to replace all instances of a specific [Dish] present with a new list of [OrderedDishWithQuantity].
class CartModel extends ChangeNotifier {
  CartModel();

  final _orders = OrderMap();
  OrderMap get orders => _orders;

  /// Used in [OrderPreview] to get a list of thumbnails to display
  List<String> get orderThumbnails {
    List<String> thumbnails = [];
    for (Map<DishOrder, int> dishMap in _orders.values) {
      thumbnails.addAll(dishMap.keys.map((dishOrder) {
        return dishOrder.dish.image;
      }));
    }
    return thumbnails;
  }

  /// Adds one (by default) [DishOrder] to [_orders]
  void addDish({
    BuildContext context,
    DishOrder dishOrder,
    int quantity = 1,
  }) {
    final stallId = dishOrder.dish.stallId;
    if (_orders.isEmpty) {
      final orderSheetController = Provider.of<OrderSheetController>(context);
      // Animate order sheet if it is hidden
      if (orderSheetController.altAnimation.value < 0) {
        orderSheetController.animateTo(BottomSheetPosition.end);
      }
    }

    /// If the [StallId] is not in the [_orders] or is null, set it to an empty map first
    _orders[stallId] ??= DishOrderMap();

    /// Update quantity of the specified [DishOrder] in [_orders]
    if (_orders[stallId].containsKey(dishOrder)) {
      _orders[stallId][dishOrder] += quantity;
    } else {
      _orders[stallId][dishOrder] = quantity;
    }
    notifyListeners();
  }

  /// Removes only one unit of a specific dish
  void removeDish({
    BuildContext context,
    DishOrder dishOrder,
  }) {
    final stallId = dishOrder.dish.stallId;
    // Return if dish already does not exist
    if (!_orders.containsKey(stallId) ||
        !_orders[stallId].containsKey(dishOrder)) {
      return;
    }
    _orders[stallId][dishOrder] -= 1;
    // If new quantity is zero, remove the dish entirely
    if (_orders[stallId][dishOrder] <= 0) {
      _orders[stallId].remove(dishOrder);

      /// Remove stall id as well if the list of [DishOrder] in the stall is empty
      if (_orders[stallId].isEmpty) _orders.remove(stallId);

      // Hide order sheet if there are completely no orders
      if (_orders.isEmpty) {
        final orderSheetController =
            Provider.of<OrderSheetController>(context, listen: false);
        orderSheetController.animateTo(BottomSheetPosition.hidden);
      }
    }
    notifyListeners();
  }

  /// Removes all [DishOrder] that comes from the stall with the given [stallId]
  void removeStall({
    BuildContext context,
    StallId stallId,
  }) {
    // Return if the stall already does not exist
    if (!_orders.containsKey(stallId)) {
      return;
    }
    _orders.remove(stallId);
    if (_orders.isEmpty) {
      // Hide order sheet
      final orderSheetController =
          Provider.of<OrderSheetController>(context, listen: false);
      orderSheetController.animateTo(BottomSheetPosition.hidden);
    }
    notifyListeners();
  }

  /// Replaces all [DishOrder] that contains the specified `dish` with a new list of [OrderedDishWithQuantity]
  void replaceDish({
    BuildContext context,
    Dish dish,
    List<DishEditDetails> newDishes,
  }) {
    final clonedDishes = List<DishEditDetails>.from(newDishes);
    // Remove and combine duplicates
    int i = 0;
    while (i < clonedDishes.length - 1) {
      int j = i + 1;
      while (j < clonedDishes.length) {
        if (clonedDishes[i].hasSameOptionsAs(clonedDishes[j])) {
          clonedDishes[i].merge(clonedDishes[j]);
          clonedDishes.removeAt(j);
        } else {
          j++;
        }
      }
      i++;
    }
    // Remove existing [DishOrder]s whose dish is equal to new dish
    if (_orders.containsKey(dish.stallId)) {
      _orders[dish.stallId].removeWhere((dishOrder, quantity) {
        return dishOrder.dish == dish;
      });
      if (_orders[dish.stallId].isEmpty) {
        _orders.remove(dish.stallId);
      }
    }
    // Add new dishes
    for (DishEditDetails dishEditDetails in clonedDishes) {
      addDish(
        context: context,
        dishOrder: DishOrder(
          dish: dish,
          enabledOptions: dishEditDetails.enabledOptions,
        ),
        quantity: dishEditDetails.quantity,
      );
    }
    if (_orders.isEmpty) {
      // Hide order sheet
      final orderSheetController =
          Provider.of<OrderSheetController>(context, listen: false);
      orderSheetController.animateTo(BottomSheetPosition.hidden);
    }
  }

  /// Gets all [DishOrder] that contains the specified `dish`
  List<DishOrder> getOrderedDishesFrom(Dish dish) {
    final stallId = dish.stallId;
    if (!_orders.containsKey(stallId)) return [];
    return _orders[stallId].keys.where((dishOrder) {
      return dishOrder.dish == dish;
    }).toList();
  }
}

// An [Order] is a receipt, a collection of dishes ordered from one specific stall. Each order will also have one specific time.
// class Order {
//   final bool ordered; // Whether order is confirmed
//   final int id;
//   final DateTime dateTime;
//   final int studentId;
//   final int stallId;
//   Map<DishOrder, int> dishQuantities;
//   Order({
//     this.ordered = false,
//     this.id,
//     this.dateTime,
//     this.studentId,
//     this.stallId,
//     this.dishQuantities,
//   });
// }

/// A wrapper class that contains all the orders in the shopping cart. It is a wrapper for a [Map<StallId, Map<DishOrder, int>>]
class OrderMap extends BetterMap<StallId, DishOrderMap> {
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
}

class DishOrderMap extends BetterMap<DishOrder, int> {}

/// An [DishOrder] contains the relevant [Dish] the user ordered, as well as the [DishOption]s that they have chosen
class DishOrder {
  final Dish dish;
  final List<DishOption> enabledOptions;
  DishOrder({this.dish, this.enabledOptions});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DishOrder &&
            this.dish == other.dish &&
            listEquals(this.enabledOptions, other.enabledOptions);
  }

  @override
  int get hashCode => hashValues(dish, hashList(enabledOptions));

  /// Required for hero transition
  @override
  String toString() {
    return 'DishOrder($dish, $enabledOptions)';
  }
}

class OrderApi {
  static final _addOrderCallable = CloudFunctions.instance.getHttpsCallable(
    functionName: 'addOrder',
  );

  static String _formatTime(TimeOfDay time) {
    String _addLeadingZeroIfNeeded(int value) {
      if (value < 10) return '0$value';
      return value.toString();
    }

    final String hourLabel = _addLeadingZeroIfNeeded(time.hour);
    final String minuteLabel = _addLeadingZeroIfNeeded(time.minute);
    return '$hourLabel:$minuteLabel';
  }

  // TODO: Define a clear structure and API within Cloud Functions and link it to here
  static Future<void> addOrder({
    @required StallId stallId,
    @required TimeOfDay time,
    @required DishOrderMap dishes,
  }) async {
    final result = await _addOrderCallable.call(<String, dynamic>{
      'stallId': stallId.value,
      'time': _formatTime(time),
      'dishes': dishes.entries.map((dishEntry) {
        return <String, dynamic>{
          'dishId': dishEntry.key.dish.id,
          'options': dishEntry.key.enabledOptions.map((option) {
            return option.id;
          }).toList(),
          'quantity': dishEntry.value,
        };
      }).toList(),
    });
    print(result.data);
  }
}
