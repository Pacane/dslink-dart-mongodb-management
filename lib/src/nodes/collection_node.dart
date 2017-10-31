import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'find_node.dart';

class CollectionNode extends SimpleNode {
  static const String isType = 'collectionNode';

  final MongoClient client;
  final String collectionName;

  CollectionNode(String path, this.client, this.collectionName) : super(path);

  /// For testing purpose only
  CollectionNode.withCustomProvider(
      String path, this.client, this.collectionName, SimpleNodeProvider provider)
      : super(path, provider);

  static Map<String, dynamic> definition(String collectionName) => {
        r'$is': isType,
        r'$name': NodeNamer.createName(collectionName),
        r'$collectionName': collectionName,
      };

  @override
  void onCreated() {
    final queryNode =
        new FindNode('$path/${FindNode.pathName}', client, collectionName);
    queryNode.load(FindNode.definition());
    provider.setNode(queryNode.path, queryNode);
  }
}
