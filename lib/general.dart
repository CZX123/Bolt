import 'dart:collection';
import 'library.dart';

/// A better implementation of [Map] that uses [mapEquals] for its [==] comparisons.
///
/// To use this when creating a new map, instead of calling `Map<K, V> map = {}`, use `Map<K, V> map = BetterMap()`.
class BetterMap<K, V> extends MapView<K, V> {
  BetterMap([Map<K, V> map]) : super(map ?? {});

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) return false;
    final BetterMap typedOther = other;
    return mapEquals(this, typedOther);
  }

  @override
  int get hashCode {
    return hashList(entries.map((entry) {
      return hashValues(entry.key, entry.value);
    }));
  }
}

/// One can use `10.30.pm`, `4.30.am` or `1300.h` to return a [TimeOfDay]
extension TimeOfDayFromNumExtension<T extends num> on T {
  /// Returns a [TimeOfDay] from a number in 12h AM format. E.g. `10.30.am`
  TimeOfDay get am {
    assert(0 <= this && this < 12.60);
    int hour = this.toInt();
    final int minute = ((this - hour) * 100).toInt();
    assert(minute < 60);
    // 12am == 0000h
    if (hour == 12) hour = 0;
    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  /// Returns a [TimeOfDay] from a number in 12h PM format. E.g. `10.30.pm`
  TimeOfDay get pm {
    final amTime = am;
    return amTime.replacing(hour: amTime.hour + 12);
  }

  /// Returns a [TimeOfDay] from a number in 24h format. E.g. `1330.h`
  TimeOfDay get h {
    assert(0 <= this && this < 23.60);
    final int hour = this ~/ 100;
    final int minute = (this - hour * 100).toInt();
    assert(minute < 60);
    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }
}

extension TypeConversionExtension on String {
  int toInt() {
    return int.parse(this);
  }

  double toDouble() {
    return double.parse(this);
  }

  num toNum() {
    return num.parse(this);
  }

  /// Returns a [TimeOfDay] from a string in 24h format, with hours and minutes separated by a colon. E.g. `10:30`, `15:45`
  TimeOfDay toTime() {
    final hoursAndMinutes = this.split(':');
    assert(hoursAndMinutes.length == 2, 'Invalid time string: $this');
    return TimeOfDay(
      hour: int.parse(hoursAndMinutes.first),
      minute: int.parse(hoursAndMinutes.last),
    );
  }
}

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get windowSize => MediaQuery.of(this).size;
  EdgeInsets get windowPadding => Provider.of(this);
  /// Wrapper for `Provider.of<T>(context, listen: ...)`
  T get<T>({bool listen = true}) {
    return Provider.of<T>(this, listen: listen);
  }
  T inherit<T>({bool listen = true}) {
    return get<T>(listen: listen);
  }
}
