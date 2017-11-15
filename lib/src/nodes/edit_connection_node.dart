import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';

class EditConnectionNode extends AddConnectionNode {
  static const String isType = 'editConnectionAction';
  static const String pathName = 'edit';

  EditConnectionNode(
      String path, LinkProvider link, MongoClientFactory mongoClientFactory)
      : super(path, link, mongoClientFactory) {
    load(definition());
  }

  /// Used for testing only
  EditConnectionNode.withCustomProvider(String path, LinkProvider link,
      MongoClientFactory mongoClientFactory, SimpleNodeProvider provider)
      : super.withCustomProvider(path, link, mongoClientFactory, provider) {
    load(definition());
  }

  bool get serializable => false;

  static Map<String, dynamic> definition() => {
        r'$is': isType,
        r'$name': 'Edit Connection',
        r'$invokable': 'write',
        r'$params': [
          {
            'name': AddConnectionParams.name,
            'type': 'string',
            'placeholder': 'Database Name'
          },
          {
            'name': AddConnectionParams.addr,
            'type': 'string',
            'placeholder': 'mongodb://<ipaddress>'
          },
          {
            'name': AddConnectionParams.user,
            'type': 'string',
            'placeholder': 'Username'
          },
          {
            'name': AddConnectionParams.pass,
            'type': 'string',
            'editor': 'password'
          },
        ],
      };

  @override
  Future<Null> onInvoke(Map<String, dynamic> params) async {
    parent.remove();
    return super.onInvoke(params);
  }
}
