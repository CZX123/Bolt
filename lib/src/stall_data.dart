import '../library.dart';

// TODO: Better error handling of stall data should there be missing information

class StallDetails {
  final int id;
  final String name;
  final String image;
  const StallDetails({this.id, this.name, this.image});
  factory StallDetails.fromJson(String stallId, dynamic parsedJson) {
    return StallDetails(
      id: int.parse(stallId),
      name: parsedJson['name'],
      image: parsedJson['image'],
    );
  }
}

class StallMenu {
  final int id;
  final bool isOpen;
  final bool splitIntoCategories;
  final List<Dish> menu;
  const StallMenu({this.id, this.isOpen, this.splitIntoCategories, this.menu});

  factory StallMenu.fromJson(String stallId, dynamic parsedJson) {
    List<Dish> _menu = [];
    Map<String, dynamic>.from(parsedJson['menu']).forEach((cat, value) {
      Map map;
      try {
        map = Map<String, dynamic>.from(value);
      } catch (e) {
        map = List.from(value).asMap();
      }
      map.forEach((dishId, value) {
        if (value != null)
          _menu.add(Dish.fromJson(cat, dishId.toString(), value));
      });
    });
    _menu.sort((a, b) => a.id.compareTo(b.id));
    return StallMenu(
      id: int.parse(stallId),
      isOpen: parsedJson['isOpen'],
      splitIntoCategories: parsedJson['splitIntoCategories'],
      menu: _menu,
    );
  }

  operator ==(Object other) {
    return identical(this, other) ||
        other is StallMenu &&
            id == other.id &&
            isOpen == other.isOpen &&
            splitIntoCategories == other.splitIntoCategories &&
            listEquals(menu, other.menu);
  }

  @override
  int get hashCode {
    return hashValues(
      id,
      isOpen,
      splitIntoCategories,
      hashList(menu),
    );
  }
}

class Dish {
  final String category;
  final int id;
  final String name;
  final bool available;
  final num unitPrice;
  final String image;
  final List<DishOption> options;
  const Dish({
    this.category,
    this.id,
    this.name,
    this.available,
    this.unitPrice,
    this.image,
    this.options,
  });

  factory Dish.fromJson(String cat, String dishId, dynamic parsedJson) {
    List<DishOption> options = [];
    Map map;
    if (parsedJson['options'] != null) {
      try {
        map = Map<String, dynamic>.from(parsedJson['options']);
      } catch (e) {
        map = List.from(parsedJson['options']).asMap();
      }
    }
    map?.forEach((key, value) {
      if (value != null)
        options.add(DishOption.fromJson(key.toString(), value));
    });
    return Dish(
      category: cat,
      id: int.parse(dishId),
      name: parsedJson['name'],
      available: parsedJson['available'],
      unitPrice: parsedJson['unitPrice'],
      image: parsedJson['image'],
      options: options,
    );
  }

  operator ==(Object other) {
    return identical(this, other) ||
        other is Dish &&
            category == other.category &&
            id == other.id &&
            name == other.name &&
            available == other.available &&
            unitPrice == other.unitPrice &&
            image == other.image &&
            listEquals(options, other.options);
  }

  @override
  int get hashCode {
    return hashValues(
      category,
      id,
      name,
      available,
      unitPrice,
      image,
      hashList(options),
    );
  }
}

class DishOption {
  final int id;
  final String name;
  final num addCost;
  final int colourCode;
  DishOption({this.id, this.name, this.addCost, this.colourCode});

  factory DishOption.fromJson(String optionId, dynamic parsedJson) {
    return DishOption(
      id: int.parse(optionId),
      name: parsedJson['name'],
      addCost: parsedJson['addCost'],
      colourCode: parsedJson['colourCode'],
    );
  }

  operator ==(Object other) {
    return identical(this, other) ||
        other is DishOption &&
            id == other.id &&
            name == other.name &&
            addCost == other.addCost &&
            colourCode == other.colourCode;
  }

  @override
  int get hashCode {
    return hashValues(id, name, addCost, colourCode);
  }
}

// // This is a custom class the only stores the image and name for the ProxyProvider in main.dart. This separate provider and class is needed since the provider for List<StallData> constantly updates on any change in the database, like the queue number. This separate class will check these updates, and this separate provider for stall names and images when only update when the names and images change, not when the queue changes. Stall name and image changes should be very rare, so this class here should rarely update.
// class StallNameAndImage {
//   String name;
//   String image;
//   StallNameAndImage({this.name, this.image});
//   factory StallNameAndImage.fromStallData(StallData stallData) {
//     return StallNameAndImage(
//       name: stallData.name,
//       image: stallData.image,
//     );
//   }
// }

// class StallData {
//   final String name;
//   final bool isOpen;
//   final int queue;
//   final List<MenuItem> menu;
//   final String image;
//   StallData({
//     this.name,
//     this.isOpen,
//     this.menu,
//     this.queue,
//     this.image,
//   });
//   factory StallData.fromJson(String name, dynamic value) {
//     if (value is String) return StallData();
//     return StallData(
//       name: name,
//       isOpen: value['isOpen'],
//       image: value['image'],
//       menu: Map<String, dynamic>.from(value['menu'])
//           .map((String name, dynamic value) {
//             return MapEntry(MenuItem.fromJson(name, value), 0);
//           })
//           .keys
//           .toList(),
//       queue: value['queue'],
//     );
//   }

//   // For debugging
//   @override
//   String toString() {
//     return {
//       'name': name,
//       'isOpen': isOpen,
//       'menu': menu,
//       'queue': queue,
//       'image': image,
//     }.toString();
//   }
// }

// class MenuItem {
//   final bool available;
//   final String name;
//   final num price;
//   final String image;
//   MenuItem({
//     this.available,
//     this.name,
//     this.price,
//     this.image,
//   });
//   factory MenuItem.fromJson(String name, dynamic value) {
//     return MenuItem(
//       name: name,
//       available: value['available'] ?? false,
//       price: value['price'],
//       image: value['image'],
//     );
//   }
//   @override
//   String toString() {
//     return {
//       'available': available,
//       'name': name,
//       'price': price,
//       'image': image,
//     }.toString();
//   }
// }

// // TODO: implement this
// class MenuOption {
//   final String name;
//   final double addPrice;
//   MenuOption({this.name, this.addPrice});
// }
