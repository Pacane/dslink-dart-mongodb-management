import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';

class RefreshCollectionsNode extends SimpleNode {
  static const String pathName = 'refreshCollections';
  static const String isType = 'refreshCollectionsNode';

  final MongoClient client;

  RefreshCollectionsNode(String path, this.client) : super(path) {
    load(definition());
  }

  @override
  bool get serializable => false;

  @override
  Future<Null> onInvoke(Map<String, dynamic> params) async {
    await (parent as DatabaseNode).refreshCollections();
  }

  static Map<String, dynamic> definition() => {
        r"$name": "Refresh collections",
        r"$is": isType,
        r"$invokable": "read",
      };
}
