import 'package:bson/bson.dart';
import 'package:collection/collection.dart';

bool isNullOrEmpty(String s) => s == null || s.isEmpty;

class Tuple<T1, T2> {
  final T1 first;
  final T2 second;

  const Tuple(this.first, this.second);
}

dynamic jsonifyMongoObjects(dynamic item) {
  if (item is DateTime) {
    return item.toIso8601String();
  }

  if (item is ObjectId) {
    return item.toString();
  }

  return item;
}

bool isA(dynamic obj, Type t1, Type t2) {
  return obj.runtimeType == t1 && obj.every((i) => i.runtimeType == t2);
}

dynamic reviveDates(List<String> dateKeys, dynamic key, dynamic value) {
  if (dateKeys.contains(key)) {
    if (value is String) {
      return DateTime.parse(value);
    } else if (value is Map) {
      try {
        value = mapMap(value, value: (key, value) => DateTime.parse(value));
        return value;
      } catch (e) {
        throw "Couldn't parse date in $key:$value";
      }
    } else {
      throw "Cannot decode $key. It's supposed to be a date, "
          "but $value (${value.runtimeType}) cannot be converted to a date.";
    }
  } else {
    return value;
  }
}
