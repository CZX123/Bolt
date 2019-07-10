import 'package:flutter/material.dart';
import 'stall_data.dart';

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

// TODO: Add more necessary stuff to this Order class, e.g. person who ordered, quantity, additional options
class Order {
  final String stallName;
  final MenuItem menuItem;
  Order({this.stallName, this.menuItem});
  @override
  String toString() {
    return 'Order(stallName: $stallName, menuItem: $menuItem)';
  }
}
