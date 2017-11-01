import 'dart:async';
import 'dart:convert';
import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/utils.dart';

class FindStreamNodeParams {
  static const String code = 'code';
  static const String limit = 'limit';
  static const String skip = 'skip';

  static const String invalidLimitErrorMsg = 'Invalid limit.';
  static const String invalidSkipErrorMsg = 'Invalid skip.';
  static const String invalidCodeErrorMsg =
      'Cannot parse query code properly. It should be valid JSON.';

  static void validateParams(Map<String, String> params) {
    if (isNullOrEmpty(params[code])) {
      throw invalidCodeErrorMsg;
    }

    if (params[limit] == null) {
      throw invalidLimitErrorMsg;
    }

    if (params[skip] == null) {
      throw invalidSkipErrorMsg;
    }

    try {
      JSON.decode(params[code]);
    } on FormatException catch (_) {
      throw invalidCodeErrorMsg;
    }
  }
}

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
    FindStreamNodeParams.validateParams(params);

    final code = JSON.decode(params[FindStreamNodeParams.code]);
    final limit = params[FindStreamNodeParams.limit];
    final skip = params[FindStreamNodeParams.skip];

    final rows = client.findStreaming(collectionName, code, limit, skip);
    await for (var row in rows) {
      final encodedRow = JSON.encode(row);
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
            "name": FindStreamNodeParams.code,
            "type": "string",
            "editor": 'textarea',
            "description": "Raw query code",
            "placeholder": "{}"
          },
          {
            "name": FindStreamNodeParams.limit,
            "type": "number",
            "default": 0,
            "description":
                "max number of items in the query (0 equals no limit)",
          },
          {
            "name": FindStreamNodeParams.skip,
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
