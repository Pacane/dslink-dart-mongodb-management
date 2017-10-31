import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'query_node.dart';

class CollectionNode extends SimpleNode {
  static const String isType = 'collectionNode';

  final MongoClient client;

  CollectionNode(String path, this.client) : super(path);

  static Map<String, dynamic> definition(String collectionName) => {
    r'$is': isType,
    r'$name': NodeNamer.createName(collectionName),
    r'$collectionName': collectionName,
  };

  @override
  void onCreated() {
    final queryNode = new QueryNode('$path/${QueryNode.pathName}', client);
    queryNode.load(QueryNode.definition());
    provider.setNode(queryNode.path, queryNode);
  }
}

