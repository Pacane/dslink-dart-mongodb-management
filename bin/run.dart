import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';

Future<Null> main(List<String> args) async {
  LinkProvider link;
  final mongoClientFactory = new MongoClientFactory();

  link = new LinkProvider(args, "MongoDB-", autoInitialize: false, profiles: {
    AddConnectionNode.isType: (path) =>
        new AddConnectionNode(path, link, mongoClientFactory),
    DatabaseNode.isType: (path) =>
        new DatabaseNode.restore(path, link, mongoClientFactory),
    RemoveConnectionAction.isType: (path) => new RemoveConnectionAction(path)
  }, defaultNodes: {
    AddConnectionNode.pathName: AddConnectionNode.definition()
  });

  link.init();
  await link.connect();
}
