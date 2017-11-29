import 'dart:async';
import 'dart:convert';

import 'package:dslink/dslink.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/utils.dart';

class AggregateNodeParams {
  static const String aggregatePipeline = 'aggregatePipeline';
  static const String dateFields = 'dateFields';
  static const String invalidPipelineErrorMsg =
      'Cannot parse aggregation pipeline. It should be a valid JSON List.';
  static const String invalidDateFieldsErrorMsg =
      'Cannot parse date fields. It should be a valid JSON list of strings.';

  static void validateParams(Map<String, String> params) {
    if (params[aggregatePipeline] is! String ||
        isNullOrEmpty(params[aggregatePipeline])) {
      throw invalidPipelineErrorMsg;
    }

    try {
      final decodedSelector = JSON.decode(params[aggregatePipeline]);
      if (decodedSelector is! List) {
        throw new FormatException('Selector is not a List.');
      }
    } on FormatException catch (_) {
      throw invalidPipelineErrorMsg;
    }

    checkIsListOfString(params[dateFields], invalidDateFieldsErrorMsg);
  }
}

class AggregateNode extends SimpleNode {
  static const String pathName = 'aggregate';
  static const String isType = 'aggregateNode';
  static const String _result = 'result';

  final MongoClient client;
  final String collectionName;

  AggregateNode(String path, this.client, this.collectionName) : super(path) {
    load(definition());
  }

  @override
  bool get serializable => false;

  @override
  Future<Map<String, String>> onInvoke(Map<String, dynamic> params) async {
    AggregateNodeParams.validateParams(params);

    final dateKeys =
        JSON.decode(params[AggregateNodeParams.dateFields]) as List<String>;

    final selector = JSON.decode(params[AggregateNodeParams.aggregatePipeline],
            reviver: (key, value) => reviveDates(dateKeys, key, value))
        as List<Map>;

    final result = await client.aggregate(collectionName, selector);

    final resultAsJsonString =
        JSON.encode(result, toEncodable: jsonifyMongoObjects);

    return {'result': resultAsJsonString};
  }

  static Map<String, dynamic> definition() => {
        r"$name": "Aggregate",
        r"$is": isType,
        r"$invokable": "read",
        r"$params": [
          {
            "name": AggregateNodeParams.aggregatePipeline,
            "type": "string",
            "editor": 'textarea',
            "description": "Aggregation Pipeline (JSON List)",
            "default": "[]"
          },
          {
            "name": AggregateNodeParams.dateFields,
            "type": "string",
            "editor": 'textarea',
            "description": "Date fields (JSON List of Strings)",
            "default": "[]"
          },
        ],
        r'$columns': [
          {"name": _result, "type": "string"}
        ],
      };
}
