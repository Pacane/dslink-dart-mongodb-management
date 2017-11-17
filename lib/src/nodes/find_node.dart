import 'dart:async';
import 'dart:convert';

import 'package:dslink/dslink.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/utils.dart';

class FindNodeParams {
  static const String selector = 'selector';
  static const String fields = 'fields';
  static const String dateFields = 'dateFields';
  static const String limit = 'limit';
  static const String skip = 'skip';

  static const String invalidLimitErrorMsg = 'Invalid limit.';
  static const String invalidSkipErrorMsg = 'Invalid skip.';
  static const String invalidSelectorErrorMsg =
      'Cannot parse selector properly. It should be a valid JSON map.';
  static const String invalidFieldsErrorMsg =
      'Cannot parse fields projection. It should be a valid JSON list of strings.';
  static const String invalidDateFieldsErrorMsg =
      'Cannot parse date fields. It should be a valid JSON list of strings.';

  static void validateParams(Map<String, String> params) {
    if (params[selector] is! String || isNullOrEmpty(params[selector])) {
      throw invalidSelectorErrorMsg;
    }

    if (isNullOrEmpty(params[fields])) {
      throw invalidFieldsErrorMsg;
    }

    if (params[limit] is! int || params[limit] == null) {
      throw invalidLimitErrorMsg;
    }

    if (params[limit] is! int || params[skip] == null) {
      throw invalidSkipErrorMsg;
    }

    try {
      final decodedSelector = JSON.decode(params[selector]);
      if (decodedSelector is! Map) {
        throw new FormatException('Selector is not a Map.');
      }
    } on FormatException catch (_) {
      throw invalidSelectorErrorMsg;
    }

    checkIsListOfString(params[fields], invalidFieldsErrorMsg);
    checkIsListOfString(params[dateFields], invalidDateFieldsErrorMsg);
  }

  static checkIsListOfString(String parameter, String errorMsg) {
    try {
      final decodedParam = JSON.decode(parameter);
      if (!(decodedParam is List && decodedParam.every((i) => i is String))) {
        throw errorMsg;
      }
    } catch (e) {
      throw errorMsg;
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

    final dateKeys =
        JSON.decode(params[FindNodeParams.dateFields]) as List<String>;

    final selector = JSON.decode(params[FindNodeParams.selector],
        reviver: (key, value) => reviveDates(dateKeys, key, value)) as Map;

    final fields = JSON.decode(params[FindNodeParams.fields]) as List<String>;
    final limit = params[FindNodeParams.limit];
    final skip = params[FindNodeParams.skip];

    final result =
        await client.find(collectionName, selector, fields, limit, skip);

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
          {"name": _result, "type": "string"}
        ],
      };
}
