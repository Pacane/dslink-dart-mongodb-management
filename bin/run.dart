import 'dart:async';
import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';

Future<Null> main(List<String> args) async {
  LinkProvider link;

  link = new LinkProvider(args, "MongoDB-", autoInitialize: false, profiles: {
    AddConnectionNode.isType: (path) => new AddConnectionNode(path, link),
  }, defaultNodes: {
    AddConnectionNode.pathName: AddConnectionNode.definition()
  });

  link.init();
  await link.connect();
}
