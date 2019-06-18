import 'package:flutter/material.dart';

// Example Data:
dynamic _exampleData = {
  'japanese': {
    'isOpen': 'ISOPEN',
    'image': 'IMAGESTRING',
    'menu': {
      'item1': {
        'available': 'AVAILABLE',
        'price': 'PRICE',
        'image': 'IMAGESTRING',
      }
    },
    'orders': [
      {
        '' //TODO
      },
    ],
  },
};

class StallData {
  String name;
  bool isOpen;
  int queue;
  List<MenuItem> menu;
  String imageString;
  ImageProvider image;
  StallData({
    this.name,
    this.isOpen,
    this.menu,
    this.queue,
    this.imageString,
    this.image,
  });
  factory StallData.fromJson(dynamic parsedJson) {
    final String stallName = parsedJson.keys.toList()[0];
    return StallData(
        name: stallName,
        isOpen: parsedJson[stallName]['isOpen'],
    );
  }
}

class MenuItem {
  bool available;
  double price;
  String imageString;
  ImageProvider image;
  MenuItem({this.available, this.price, this.imageString, this.image});
}

class MenuOption {
  String name;
  double addPrice;
  MenuOption({this.name, this.addPrice});
}
