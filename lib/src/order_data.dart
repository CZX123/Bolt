import '../library.dart';

/// A wrapper class that contains all the orders in the shopping cart. It is a wrapper for a [Map<StallId, Map<DishWithOptions, int>>]
class Orders {
  Map<StallId, Map<DishWithOptions, int>> value = {};
}

class CartModel extends ChangeNotifier {
  CartModel();

  Orders _orders = Orders();
  Orders get orders => _orders;

  List<String> _orderThumbnails = [];
  List<String> get orderThumbnails => _orderThumbnails;

  void addDish(
    StallId stallId,
    DishWithOptions dishWithOptions, [
    int count = 1,
  ]) {
    if (_orders.value.containsKey(stallId)) {
      if (_orders.value[stallId].containsKey(dishWithOptions)) {
        _orders.value[stallId][dishWithOptions] += count;
      } else {
        _orders.value[stallId][dishWithOptions] = count;
        int index = 0;
        for (var id in _orders.value.keys) {
          if (id == stallId) break;
          index += _orders.value[id].length;
        }
        index += _orders.value[stallId].keys.toList().indexOf(dishWithOptions);
        _orderThumbnails.insert(index, dishWithOptions.dish.image);
      }
    } else {
      _orders.value[stallId] = {};
      _orders.value[stallId][dishWithOptions] = 1;
      int index = 0;
      for (var id in _orders.value.keys) {
        if (id == stallId) break;
        index += _orders.value[id].length;
      }
      index += _orders.value[stallId].keys.toList().indexOf(dishWithOptions);
      _orderThumbnails.insert(index, dishWithOptions.dish.image);
    }
    notifyListeners();
  }

  void editDish(
    StallId stallId,
    DishWithOptions dishWithOptions,
    int newQuantity,
  ) {
    if (!_orders.value.containsKey(stallId) ||
        !_orders.value[stallId].containsKey(dishWithOptions)) {
      addDish(stallId, dishWithOptions, newQuantity);
    } else if (newQuantity != null &&
        newQuantity != _orders.value[stallId][dishWithOptions]) {
      _orders.value[stallId][dishWithOptions] = newQuantity;
      notifyListeners();
    }
  }

  // By default only subtract one dish
  void removeDish(
    StallId stallId,
    DishWithOptions dishWithOptions, [
    bool removeEntirely = false,
  ]) {
    if (!_orders.value.containsKey(stallId)) return;
    final dishIndex = _orders.value[stallId].keys.toList().indexOf(dishWithOptions);
    if (dishIndex == -1) return;
    if (removeEntirely || _orders.value[stallId][dishWithOptions] <= 1) {
      int index = dishIndex;
      for (var id in _orders.value.keys) {
        if (id == stallId) break;
        index += _orders.value[id].length;
      }
      _orders.value[stallId].remove(dishWithOptions);
      if (_orders.value[stallId].isEmpty) _orders.value.remove(stallId);
      _orderThumbnails.removeAt(index);
    } else {
      _orders.value[stallId][dishWithOptions] -= 1;
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
