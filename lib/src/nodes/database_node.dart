import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';

class DatabaseNode extends SimpleNode {
  static String isType = 'databaseNode';

  final LinkProvider link;
  MongoClientFactory mongoClientFactory;
  MongoClient client;

  DatabaseNode(String path, String address, String username, String password,
      String connectionName, this.client, this.link)
      : super(path) {
    load(definition(address, username, password, connectionName));
  }

  DatabaseNode.restore(String path, this.link, this.mongoClientFactory)
      : super(path);

  /// Used for testing only
  DatabaseNode.withCustomProvider(
      String path,
      String address,
      String username,
      String password,
      String connectionName,
      this.client,
      this.link,
      SimpleNodeProvider provider)
      : super(path, provider) {
    load(definition(address, username, password, connectionName));
  }

  static Map<String, dynamic> definition(String address, String username,
          String password, String connectionName) =>
      {
        r'$is': isType,
        r'$name': connectionName,
        _address: address,
        _user: username,
        _pass: password
      };

  static const String _user = r'$$username';
  static const String _pass = r'$$password';
  static const String _address = r'$$uri';

  @override
  Future<Null> onCreated() async {
    if (client == null) {
      client = restoreClientFromConfigs();
    }

    await refreshCollections();

    final refreshCollectionsNodePath =
        '$path/${RefreshCollectionsNode.pathName}';
    provider.setNode(refreshCollectionsNodePath,
        new RefreshCollectionsNode(refreshCollectionsNodePath, client));

    link.save();
  }

  Future refreshCollections() async {
    final collections = await client.listCollections();
    for (final collectionName in collections) {
      final collectionNode =
          new CollectionNode('$path/$collectionName', client, collectionName);
      provider.setNode(collectionNode.path, collectionNode);
    }
  }

  MongoClient restoreClientFromConfigs() {
    var address = configs[_address];
    var username = configs[_user];
    var password = configs[_pass];

    return mongoClientFactory.create(Uri.parse(address), username, password);
  }
}
