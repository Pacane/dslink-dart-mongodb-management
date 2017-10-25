import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart' show NodeNamer;
import 'mongo_client.dart';

class AddConnectionParams {
  static const String name = 'connectionName';
  static const String addr = 'address';
  static const String user = 'username';
  static const String pass = 'password';
}

class AddConnection extends SimpleNode {
  static const String isType = 'addConnectionAction';
  static const String pathName = 'Add_Connection';


  static Map<String, dynamic> definition() => {
        r'$is': isType,
        r'$name': 'Add Device',
        r'$invokable': 'write',
        r'$params': [
          {'name': AddConnectionParams.name, 'type': 'string', 'placeholder': 'Database Name'},
          {
            'name': AddConnectionParams.addr,
            'type': 'string',
            'placeholder': 'mongodb://<ipaddress>'
          },
          {'name': AddConnectionParams.user, 'type': 'string', 'placeholder': 'Username'},
          {'name': AddConnectionParams.pass, 'type': 'string', 'editor': 'password'},
        ],
      };

  LinkProvider _link;

  AddConnection(String path, this._link) : super(path);

  @override
  Future<Null> onInvoke(Map<String, dynamic> params) async {
    if (params[AddConnectionParams.name] == null || params[AddConnectionParams.name].isEmpty) {
      throw 'A connection name must be specified.';
    }
    var name = NodeNamer.createName(params[AddConnectionParams.name].trim());

    var nd = provider.getNode('/$name');
    if (nd != null) {
      throw "There's already a connection with that name that exists.";
    }

    Uri uri;
    try {
      uri = Uri.parse(params[AddConnectionParams.addr]);
    } catch (e) {
      throw 'Error parsing Address: $e';
    }

    var u = params[AddConnectionParams.user];
    var p = params[AddConnectionParams.pass];

    var cl = new MongoClient(uri, u, p);
    var res = await cl.testConnection();

    switch (res) {
      case AuthResult.ok:
        nd = provider.addNode('/$name', DatabaseNode.definition(uri, u, p));
        _link.save();
        return;
      case AuthResult.notFound:
        throw 'Unable to locate device parameters page. Possible invalid firmware version';
        break;
      case AuthResult.authError:
        throw 'Unable to authenticate with provided credentials';
        break;
      default:
        throw 'Unknown error occured. Check log file for errors';
        break;
    }
  }
}

class DatabaseNode extends SimpleNode {
  static String isType = 'databaseNode';
  static Map<String, dynamic> definition(
          Uri uri, String username, String password) =>
      {
        r'$is': isType,
        r'$name': 'Add Device',
        _uri: uri.toString(),
        _user: username,
        _pass: password,
      };

  static const String _user = r'$$username';
  static const String _pass = r'$$password';
  static const String _uri = r'$$uri';

  DatabaseNode(String path) : super(path);
}

