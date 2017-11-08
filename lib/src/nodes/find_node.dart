import 'dart:async';
import 'dart:convert';

import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/utils.dart';

class FindNodeParams {
  static const String selector = 'selector';
  static const String limit = 'limit';
  static const String skip = 'skip';

  static const String invalidLimitErrorMsg = 'Invalid limit.';
  static const String invalidSkipErrorMsg = 'Invalid skip.';
  static const String invalidSelectorErrorMsg =
      'Cannot parse selector properly. It should be valid JSON.';

  static void validateParams(Map<String, String> params) {
    if (isNullOrEmpty(params[selector])) {
      throw invalidSelectorErrorMsg;
    }

    if (params[limit] == null) {
      throw invalidLimitErrorMsg;
    }

    if (params[skip] == null) {
      throw invalidSkipErrorMsg;
    }

    try {
      JSON.decode(params[selector]);
    } on FormatException catch (_) {
      throw invalidSelectorErrorMsg;
    }
  }
}

class FindNode extends SimpleNode {
  static const String pathName = 'find';
  static const String isType = 'findNode';
  static const String _result = 'result';

  final MongoClient client;
  final String collectionName;

  FindNode(String path, this.client, this.collectionName) : super(path) {
    load(definition());
  }

  @override
  bool get serializable => false;

  @override
  Future<Map<String, String>> onInvoke(Map<String, dynamic> params) async {
    FindNodeParams.validateParams(params);

    final selector = JSON.decode(params[FindNodeParams.selector]);
    final limit = params[FindNodeParams.limit];
    final skip = params[FindNodeParams.skip];

    final result = await client.find(collectionName, selector, limit, skip);

    final resultAsJsonString =
        JSON.encode(result, toEncodable: jsonifyMongoObjects);

    return {'result': resultAsJsonString};
  }

  static Map<String, dynamic> definition() => {
        r"$name": "Find",
        r"$is": isType,
        r"$invokable": "read",
        r"$params": [
          {
            "name": FindNodeParams.selector,
            "type": "string",
            "editor": 'textarea',
            "description": "Selector",
            "placeholder": "{}"
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
          {"name": _result, "type": "string"}
        ],
      };
}
