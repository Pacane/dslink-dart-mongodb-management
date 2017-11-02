import 'dart:async';
import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

Future<Null> main(List<String> arguments) async {
  final db = new Db(
      "mongodb://joel:password@ds127983.mlab.com:27983/test_permissions");
  await db.open();

  final col = db.collection('somecollection');
  await findByAge26(col, db);
  await findByNameRegex(col, db);
  await findByNameRegexWithJSONDecode(col, db);

  final colls = await db.getCollectionNames();

  print('aa');

//  await col.insert({'Name': 'Ilya', 'Age': 30});
}

Future findByAge26(DbCollection col, Db db) async {
  print('*** find with equals matcher (default)');
  final sb = new SelectorBuilder()
    ..raw({
      'Age': {'\$eq': 26}
    });
  final c = new Cursor(db, col, sb);
  final res = await c.stream.toList();
  print(res);
}

Future findByNameRegex(DbCollection col, Db db) async {
  print('*** find by regex');
  final sb = new SelectorBuilder()
    ..raw({
      'Name': {'\$regex': 'mar*', '\$options': 'i'}
    });
  final c = new Cursor(db, col, sb);
  final res = await c.stream.toList();
  print(res);
}

Future findByNameRegexWithJSONDecode(DbCollection col, Db db) async {
  print('*** find by regex and JSON decode');
  final sb = new SelectorBuilder();
  final queryString = r'{"Name": {"$regex": "mar*", "$options": "i"}}';

  sb.raw(JSON.decode(queryString));
  final c = new Cursor(db, col, sb);
  final res = await c.stream.toList();
  print(res);
}
