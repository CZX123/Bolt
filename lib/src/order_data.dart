import 'package:flutter/material.dart';
import 'stall_data.dart';

class OrderNotifier extends ChangeNotifier {
  OrderNotifier();

  List<Order> _orders = [];
  List<Order> get orders => _orders;
  int _index = 0; // For easy updates to the animated list in the OrderScreen
  int get index => _index;

  void addOrder(Order order) {
    _index = _orders.length;
    _orders.add(order);
    notifyListeners();
  }

  void removeOrder(Order order) {
    _index = _orders.indexOf(order);
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
