import 'package:bson/bson.dart';

bool isNullOrEmpty(String s) => s == null || s.isEmpty;

class Tuple<T1, T2> {
  final T1 first;
  final T2 second;

  const Tuple(this.first, this.second);
}

jsonifyMongoObjects(dynamic item) {
  if (item is DateTime) {
    return item.toIso8601String();
  }

  if (item is ObjectId) {
    return item.toString();
  }

  return item;
}
