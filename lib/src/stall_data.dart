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
        '' // TODO: Create a sample order
      },
    ],
  },
};

class StallNameAndImage {
  String name;
  String image;
  StallNameAndImage({this.name,this.image});
  factory StallNameAndImage.fromStallData(StallData stallData) {
    return StallNameAndImage(
      name: stallData.name,
      image: stallData.image,
    );
  }
}

class StallData {
  String name;
  bool isOpen;
  int queue;
  List<MenuItem> menu;
  String image;
  StallData({
    this.name,
    this.isOpen,
    this.menu,
    this.queue,
    this.image,
  });
  factory StallData.fromJson(String name, dynamic value) {
    if (value is String) return StallData();
    return StallData(
      name: name,
      isOpen: value['isOpen'],
      image: value['image'],
      menu: Map<String, dynamic>.from(value['menu'])
          .map((String name, dynamic value) {
            return MapEntry(MenuItem.fromJson(name, value), 0);
          })
          .keys
          .toList(),
      queue: value['queue'],
    );
  }
  @override
  String toString() {
    return {
      'name': name,
      'isOpen': isOpen,
      'menu': menu,
      'queue': queue,
      'image': image,
    }.toString();
  }
}

class MenuItem {
  bool available;
  String name;
  num price;
  String image;
  MenuItem({
    this.available,
    this.name,
    this.price,
    this.image,
  });
  factory MenuItem.fromJson(String name, dynamic value) {
    return MenuItem(
      name: name,
      available: value['available'] ?? false,
      price: value['price'],
      image: value['image'],
    );
  }
  @override
  String toString() {
    return {
      'available': available,
      'name': name,
      'price': price,
      'image': image,
    }.toString();
  }
}

class MenuOption {
  String name;
  double addPrice;
  MenuOption({this.name, this.addPrice});
}
