import 'dart:async';
import 'dart:convert';

import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/utils.dart';

class CountNodeParams {
  static const String selector = 'selector';

  static const String invalidSelector =
      'Cannot parse selector properly. It should be valid JSON.';

  static void validateParams(Map<String, String> params) {
    if (isNullOrEmpty(params[selector])) {
      throw invalidSelector;
    }

    try {
      JSON.decode(params[selector]);
    } on FormatException catch (_) {
      throw invalidSelector;
    }
  }
}

class CountNode extends SimpleNode {
  static const String pathName = 'count';
  static const String isType = 'countNode';
  static const String result = 'result';

  final MongoClient client;
  final String collectionName;

  CountNode(String path, this.client, this.collectionName) : super(path) {
    load(definition());
  }

  @override
  bool get serializable => false;

  @override
  Future<Map<String, int>> onInvoke(Map<String, dynamic> params) async {
    CountNodeParams.validateParams(params);

    final code = JSON.decode(params[CountNodeParams.selector]);

    final result = await client.count(collectionName, code);

    return {CountNode.result: result};
  }

  static Map<String, dynamic> definition() => {
        r"$name": "Count",
        r"$is": isType,
        r"$invokable": "read",
        r"$params": [
          {
            "name": CountNodeParams.selector,
            "type": "string",
            "editor": 'textarea',
            "description": "Raw selector",
            "placeholder": "{}"
          },
        ],
        r'$columns': [
          {"name": result, "type": "int"}
        ],
      };
}
