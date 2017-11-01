import 'dart:async';
import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'collection_node.dart';

class DatabaseNode extends SimpleNode {
  DatabaseNode(String path, this.client) : super(path);

  /// Used for testing only
  DatabaseNode.withCustomProvider(
      String path, this.client, SimpleNodeProvider provider)
      : super(path, provider);

  static String isType = 'databaseNode';

  static Map<String, dynamic> definition(String address, String username,
          String password, String connectionName) =>
      {
        r'$is': isType,
        r'$name': connectionName,
        _address: address,
        _user: username,
        _pass: password,
      };

  static const String _user = r'$$username';
  static const String _pass = r'$$password';
  static const String _address = r'$$uri';

  final MongoClient client;

  @override
  Future<Null> onCreated() async {
    final collections = await client.listCollections();
    for (final collectionName in collections) {
      final collectionNode =
          new CollectionNode('$path/$collectionName', client, collectionName);
      collectionNode.load(CollectionNode.definition(collectionName));
      provider.setNode(collectionNode.path, collectionNode);
    }
  }
}
