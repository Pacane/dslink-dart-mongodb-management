// Copyright (c) 2017, Joel Trottier-Hebert. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';

main(List<String> arguments) async {
  Db db = new Db(
      "mongodb://joel:password@ds127983.mlab.com:27983/test_permissions");
  await db.open();

  var col = db.collection('somecollection');
  await findByAge26(col, db);
  await findByNameRegex(col, db);
  await findByNameRegexWithJSONDecode(col, db);

  var colls = await db.getCollectionNames();

  print('aa');

//  await col.insert({'Name': 'Ilya', 'Age': 30});
}

Future findByAge26(DbCollection col, Db db) async {
  print('*** find with equals matcher (default)');
  SelectorBuilder sb = new SelectorBuilder();
  sb.raw({
    'Age': {'\$eq': 26}
  });
  var c = new Cursor(db, col, sb);
  var res = await c.stream.toList();
  print(res);
}

Future findByNameRegex(DbCollection col, Db db) async {
  print('*** find by regex');
  SelectorBuilder sb = new SelectorBuilder();
  sb.raw({
    'Name': {'\$regex': 'mar*', '\$options': 'i'}
  });
  var c = new Cursor(db, col, sb);
  var res = await c.stream.toList();
  print(res);
}

Future findByNameRegexWithJSONDecode(DbCollection col, Db db) async {
  print('*** find by regex and JSON decode');
  SelectorBuilder sb = new SelectorBuilder();
  var queryString = r'{"Name": {"$regex": "mar*", "$options": "i"}}';

  sb.raw(JSON.decode(queryString));
  var c = new Cursor(db, col, sb);
  var res = await c.stream.toList();
  print(res);
}
