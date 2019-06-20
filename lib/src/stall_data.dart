// Example Data:
const exampleData = {
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
  final String name;
  final bool isOpen;
  final int queue;
  final List<MenuItem> menu;
  final String image;
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
  final bool available;
  final String name;
  final num price;
  final String image;
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
  final String name;
  final double addPrice;
  MenuOption({this.name, this.addPrice});
}
