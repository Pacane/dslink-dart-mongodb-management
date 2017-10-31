import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';

class QueryNode extends SimpleNode {
  static const String pathName = 'query';

  final MongoClient client;

  QueryNode(String path, this.client) : super(path);

  static const String isType = 'queryNode';

  static Map<String, dynamic> definition() => {
    r"$name": "Evaluate Raw Query",
    r"$is": isType,
    r"$invokable": "read",
    r"$params": [
      {
        "name": "code",
        "type": "string",
        "editor": 'textarea',
        "description": "Raw query code",
        "placeholder": "{}"
      },
      {
        "name": "limit",
        "type": "number",
        "default": 0,
        "description":
        "max number of items in the query (0 equals no limit)",
      },
      {
        "name": "skip",
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
