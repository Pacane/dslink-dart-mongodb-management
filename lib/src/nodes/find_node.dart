import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/utils.dart';

class FindNodeParams {
  static const String code = 'code';
  static const String limit = 'limit';
  static const String skip = 'skip';

  static const String invalidCodeErrorMsg = 'Invalid code.';
  static const String invalidLimitErrorMsg = 'Invalid limit.';
  static const String invalidSkipErrorMsg = 'Invalid skip.';

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
  }
}

class FindNode extends SimpleNode {
  static const String pathName = 'query';

  final MongoClient client;
  final String collectionName;

  FindNode(String path, this.client, this.collectionName) : super(path);

  static const String isType = 'queryNode';

  @override
  dynamic onInvoke(Map<String, dynamic> params) async {
    FindNodeParams.validateParams(params);

    final code = params[FindNodeParams.code];
    final limit = params[FindNodeParams.limit];
    final skip = params[FindNodeParams.skip];

    await client.find(collectionName, code, limit, skip);
  }

  static Map<String, dynamic> definition() => {
        r"$name": "Evaluate Raw Query",
        r"$is": isType,
        r"$invokable": "read",
        r"$params": [
          {
            "name": FindNodeParams.code,
            "type": "string",
            "editor": 'textarea',
            "description": "Raw query code",
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
          {"name": "json", "type": "string"}
        ],
      };
}
