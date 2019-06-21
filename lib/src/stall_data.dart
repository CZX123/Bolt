// Example Data to better visualise the mapping of this data to their respective data classes: StallData and MenuItem.
const exampleData = {
  'japanese': {
    'isOpen': true,
    'image': 'stalls/japanese/image.png', // follow the firebase folder layout. Ensure the file extension is correct
    'menu': {
      'item1': {
        'available': true,
        'price': 3,
        'image': 'stalls/japanese/menu/item1/image.png', // Same as above
      }
    },
    'queue': 20,
    'orders': [
      {
        '' // TODO: Create a sample order
      },
    ],
  },
};

// This is a custom class the only stores the image and name for the ProxyProvider in main.dart. This separate provider and class is needed since the provider for List<StallData> constantly updates on any change in the database, like the queue number. This separate class will check these updates, and this separate provider for stall names and images when only update when the names and images change, not when the queue changes. Stall name and image changes should be very rare, so this class here should rarely update.
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

  // For debugging
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
