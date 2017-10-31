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

  AddConnectionNode(String path, this._link) : super(path);

  @override
  Future<Null> onInvoke(Map<String, dynamic> params) async {
    AddConnectionParams.validateParams(params);

    var name = NodeNamer.createName(params[AddConnectionParams.name].trim());

    var nd = provider.getNode('/$name');
    if (nd != null) {
      throw "There's already a connection with that name that exists.";
    }

    var username = params[AddConnectionParams.user];
    var password = params[AddConnectionParams.pass];
    var address = params[AddConnectionParams.addr];
    var parsedAddress = Uri.parse(address);

    var cl = new MongoClient(parsedAddress, username, password);
    var res = await cl.testConnection();

    switch (res) {
      case AuthResult.ok:
        var dbNode = new DatabaseNode('/$name', cl);
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

  DatabaseNode(String path, this.client) : super(path);

  DatabaseNode.withCustomProvider(
      String path, this.client, SimpleNodeProvider provider)
      : super(path, provider);

  @override
  Future<Null> onCreated() {
    return client.listCollections().then((collections) {
      for (var collectionName in collections) {
        var collectionNode =
            new CollectionNode('$path/$collectionName', client);
        collectionNode.load(CollectionNode.definition(collectionName));
        provider.setNode(collectionNode.path, collectionNode);
      }
    });
  }
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
    var queryNode = new QueryNode('$path/${QueryNode.pathName}', client);
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
