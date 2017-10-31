import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart' show NodeNamer;
import 'mongo_client.dart';

class AddConnectionParams {
  static const String name = 'connectionName';
  static const String addr = 'address';
  static const String user = 'username';
  static const String pass = 'password';

  static void validateParams(Map<String, String> params) {
    if (params[AddConnectionParams.name] == null ||
        params[AddConnectionParams.name].isEmpty) {
      throw 'A connection name must be specified.';
    }

    if (params[AddConnectionParams.user] == null ||
        params[AddConnectionParams.user].isEmpty) {
      throw 'A username must be specified.';
    }

    if (params[AddConnectionParams.pass] == null ||
        params[AddConnectionParams.pass].isEmpty) {
      throw 'A password must be specified.';
    }

    if (params[AddConnectionParams.addr] == null ||
        params[AddConnectionParams.addr].isEmpty) {
      throw 'An address must be specified.';
    }

    try {
      Uri.parse(params[AddConnectionParams.addr]);
    } catch (e) {
      throw 'Error parsing Address: $e';
    }
  }
}

class AddConnectionNode extends SimpleNode {
  AddConnectionNode(String path, this._link) : super(path);

  static const String isType = 'addConnectionAction';
  static const String pathName = 'Add_Connection';

  static Map<String, dynamic> definition() => {
        r'$is': isType,
        r'$name': 'Add Device',
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

  LinkProvider _link;

  @override
  Future<Null> onInvoke(Map<String, dynamic> params) async {
    AddConnectionParams.validateParams(params);

    final name = NodeNamer.createName(params[AddConnectionParams.name].trim());

    final nd = provider.getNode('/$name');
    if (nd != null) {
      throw "There's already a connection with that name that exists.";
    }

    final username = params[AddConnectionParams.user];
    final password = params[AddConnectionParams.pass];
    final address = params[AddConnectionParams.addr];
    final parsedAddress = Uri.parse(address);

    final cl = new MongoClient(parsedAddress, username, password);
    final res = await cl.testConnection();

    switch (res) {
      case AuthResult.ok:
        final dbNode = new DatabaseNode('/$name', cl);
        dbNode.load(DatabaseNode.definition(address, username, password, name));
        provider.setNode('/$name', dbNode);
        _link.save();
        return;
      case AuthResult.notFound:
        throw 'Unable to locate device parameters page. Possible invalid firmware version';
        break;
      case AuthResult.authError:
        throw 'Unable to authenticate with provided credentials';
        break;
      case AuthResult.other:
      default:
        throw 'Unknown error occured. Check log file for errors';
        break;
    }
  }
}

class DatabaseNode extends SimpleNode {
  DatabaseNode(String path, this.client) : super(path);

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
  Future<Null> onCreated() => client.listCollections().then((collections) {
        for (final collectionName in collections) {
          final collectionNode =
              new CollectionNode('$path/$collectionName', client);
          collectionNode.load(CollectionNode.definition(collectionName));
          provider.setNode(collectionNode.path, collectionNode);
        }
      });
}

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
