import '../library.dart';

// TODO: Better error handling of stall data should there be missing information

// bool mapEquals<A, B>(Map<A, B> a, Map<A, B> b) {
//   return a?.length == b?.length &&
//       (a?.keys?.every((key) {
//             if (B is Map) return mapEquals(a[key] as Map, b[key] as Map);
//             return a[key] == b[key];
//           }) ??
//           true);
// }

/// A [ChangeNotifier] with a list of stall IDs as its value
class StallIdList extends ChangeNotifier implements ValueListenable<List<StallId>> {

  @override
  List<StallId> get value => _value;
  List<StallId> _value;
  set value(List<StallId> newValue) {
    newValue.sort();
    if (listEquals(_value, newValue)) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '$runtimeType($value)';

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        other is StallIdList && listEquals(value, other.value);
  }

  @override
  int get hashCode => hashList(value);
}

/// A class that contains the stall id, which is an [int]
class StallId implements Comparable {
  final int value;
  const StallId(this.value);

  @override
  operator ==(Object other) {
    return identical(this, other) || other is StallId && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(other) {
    if (other is StallId) {
      return value.compareTo(other.value);
    }
    throw Exception('Cannot compare $runtimeType with ${other.runtimeType}');
  }

  @override
  String toString() {
    return value.toString();
  }
}

class StallDetailsMap {
  final Map<StallId, StallDetails> value;
  const StallDetailsMap(this.value);

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        other is StallDetailsMap && mapEquals(value, other.value);
  }

  @override
  int get hashCode => hashList(value.values);
}

class StallDetails {
  final StallId id;
  final String name;
  final String image;
  const StallDetails({this.id, this.name, this.image});

  factory StallDetails.fromJson(StallId id, dynamic parsedJson) {
    return StallDetails(
      id: id,
      name: parsedJson['name'],
      image: parsedJson['image'],
    );
  }

  /// Returns whether all fields are non-null
  bool get isValid {
    return id != null && name != null && image != null;
  }

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        other is StallDetails &&
            id == other.id &&
            name == other.name &&
            image == other.image;
  }

  @override
  int get hashCode => hashValues(id, name, image);
}

class StallMenuMap {
  final Map<StallId, StallMenu> value;
  const StallMenuMap(this.value);

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        other is StallMenuMap && mapEquals(value, other.value);
  }

  @override
  int get hashCode => hashList(value.values);
}

class StallMenu {
  final StallId id;
  final bool isOpen;
  final bool splitIntoCategories;
  final List<Dish> menu;
  const StallMenu({this.id, this.isOpen, this.splitIntoCategories, this.menu});

  factory StallMenu.fromJson(StallId stallId, dynamic parsedJson) {
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
          _menu.add(Dish.fromJson(stallId, cat, dishId.toString(), value));
      });
    });
    _menu.sort((a, b) => a.id.compareTo(b.id));
    return StallMenu(
      id: stallId,
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
  final int id;
  final StallId stallId;
  final String category;
  final String name;
  final bool available;
  final num unitPrice;
  final String image;
  final List<DishOption> options;
  const Dish({
    this.id,
    this.stallId,
    this.category,
    this.name,
    this.available,
    this.unitPrice,
    this.image,
    this.options,
  });

  factory Dish.fromJson(StallId stallId, String category, String dishId, dynamic parsedJson) {
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
    options.sort();
    return Dish(
      id: int.parse(dishId),
      stallId: stallId,
      category: category,
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
            id == other.id &&
            stallId == other.stallId &&
            category == other.category &&
            name == other.name &&
            available == other.available &&
            unitPrice == other.unitPrice &&
            image == other.image &&
            listEquals(options, other.options);
  }

  @override
  int get hashCode {
    return hashValues(
      id,
      stallId,
      category,
      name,
      available,
      unitPrice,
      image,
      hashList(options),
    );
  }

  /// Used for hero transitions
  @override
  String toString() {
    return 'Dish($stallId, $id)';
  }
}

class DishOption implements Comparable {
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

  /// Used for hero transitions
  @override
  String toString() {
    return 'DishOption($id)';
  }

  /// Sorting used in [DishEditScreen] to sort [DishOption] by alphabetical order
  @override
  int compareTo(Object other) {
    if (runtimeType != other.runtimeType) {
      throw Exception('Cannot compare $runtimeType with ${other.runtimeType}!');
    }
    final DishOption typedOther = other;
    return name.compareTo(typedOther.name);
  }
}
