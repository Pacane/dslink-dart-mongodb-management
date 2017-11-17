import 'dart:async';
import 'dart:convert';

import 'package:dslink/dslink.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
import 'package:dslink_mongodb_controller/utils.dart';

class FindStreamNode extends SimpleNode {
  static const String pathName = 'findStream';
  static const String isType = 'findStreamNode';

  final MongoClient client;
  final String collectionName;

  FindStreamNode(String path, this.client, this.collectionName) : super(path) {
    load(definition());
  }

  @override
  bool get serializable => false;

  @override
  Stream<List> onInvoke(Map<String, dynamic> params) async* {
    FindNodeParams.validateParams(params);

    final dateKeys =
        JSON.decode(params[FindNodeParams.dateFields]) as List<String>;

    final selector = JSON.decode(params[FindNodeParams.selector],
        reviver: (key, value) => reviveDates(dateKeys, key, value)) as Map;
    final fields = JSON.decode(params[FindNodeParams.fields]) as List<String>;
    final limit = params[FindNodeParams.limit];
    final skip = params[FindNodeParams.skip];

    final rows =
        client.findStreaming(collectionName, selector, fields, limit, skip);
    await for (var row in rows) {
      final encodedRow = JSON.encode(row, toEncodable: jsonifyMongoObjects);

      yield [
        [encodedRow]
      ];
    }
  }

  static Map<String, dynamic> definition() => {
        r"$name": "Streaming Find",
        r"$is": isType,
        r"$result": "stream",
        r"$invokable": "read",
        r"$params": [
          {
            "name": FindNodeParams.selector,
            "type": "string",
            "editor": 'textarea',
            "description": "Selector (JSON Map)",
            "default": "{}"
          },
          {
            "name": FindNodeParams.fields,
            "type": "string",
            "editor": 'textarea',
            "description": "Fields projection (JSON List of Strings)",
            "default": "[]"
          },
          {
            "name": FindNodeParams.dateFields,
            "type": "string",
            "editor": 'textarea',
            "description": "Date fields (JSON List of Strings)",
            "default": "[]"
          },
          {
            "name": FindNodeParams.limit,
            "type": "number",
            "default": 0,
            "description":
                "max number of items in the query (0 equals no limit)",
          },
          {
            "name": FindNodeParams.skip,
            "type": "number",
            "default": 0,
            "description": "Amount of results to skip for the query",
          },
        ],
        r'$columns': [
          {"name": "result", "type": "string"}
        ],
      };
}
