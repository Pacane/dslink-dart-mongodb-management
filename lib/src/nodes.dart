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

class AddConnection extends SimpleNode {
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

  AddConnection(String path, this._link) : super(path);

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
        nd = provider.addNode('/$name',
            DatabaseNode.definition(address, username, password, name));
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

  String username;
  String password;
  String address;

  DatabaseNode(String path) : super(path);

  @override
  void onCreated() {
    username = configs[r'$$username'];
    password = configs[r'$$password'];
    address = configs[r'$$uri'];

    var client = new MongoClient(Uri.parse(address), username, password);

    client.listCollections().then((collections) {
      for (var collectionName in collections) {
        provider.addNode('${path}/$collectionName',
            CollectionNode.definition(collectionName));
      }
    });
  }
}

class CollectionNode extends SimpleNode {
  static String isType = 'collectionNode';

  CollectionNode(String path) : super(path);

  static Map<String, dynamic> definition(String collectionName) => {
        r'$is': isType,
        r'$name': NodeNamer.createName(collectionName),
        r'$collectionName': collectionName,
        QueryNode.pathName: QueryNode.definition(collectionName),
      };
}

class QueryNode extends SimpleNode {
  static const String pathName = 'query';

  QueryNode(String path) : super(path);

  static const String isType = 'queryNode';

  static Map<String, dynamic> definition(String collectionName) => {
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
