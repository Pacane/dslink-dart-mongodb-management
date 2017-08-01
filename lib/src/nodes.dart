import 'dart:async';

import 'package:dslink/dslink.dart';
import 'client.dart';
import 'package:dslink/nodes.dart' show NodeNamer;

class AddConnection extends SimpleNode {
  static const String isType = 'addConnectionAction';
  static const String pathName = 'Add_Connection';

  static const String _name = 'databaseName';
  static const String _addr = 'address';
  static const String _user = 'username';
  static const String _pass = 'password';
  static const String _success = 'success';
  static const String _message = 'message';

  static Map<String, dynamic> definition() => {
    r'$is': isType,
    r'$name': 'Add Device',
    r'$invokable': 'write',
    r'$params': [
      {'name': _name, 'type': 'string', 'placeholder': 'Database Name'},
      {
        'name': _addr,
        'type': 'string',
        'placeholder': 'mongodb://<ipaddress>'
      },
      {'name': _user, 'type': 'string', 'placeholder': 'Username'},
      {'name': _pass, 'type': 'string', 'editor': 'password'},
    ],
    r'$columns': [
      {'name': _success, 'type': 'bool', 'default': false},
      {'name': _message, 'type': 'string', 'default': ''}
    ]
  };

  LinkProvider _link;

  AddConnection(String path, this._link) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    final ret = {_success: false, _message: ''};

    var rawName = params[_name];
    if (rawName == null || rawName.isEmpty) {
      return ret..[_message] = 'A name must be specified.';
    }
    var connectionNodeName = NodeNamer.createName(rawName.trim());

    var nd = provider.getNode('/$connectionNodeName');
    if (nd != null) {
      return ret..[_message] = 'A connection to a database by that name already exists.';
    }

    var address = params[_addr];
    if (address == null || address.isEmpty) {
      return ret..[_message] = 'The database address is invalid.';
    }

    var u = params[_user];
    var p = params[_pass];
    var cl = new MongoClient(address, u, p, rawName);
    var res = await cl.authenticate();

    switch (res) {
      case AuthResult.ok:
        ret
          ..[_success] = true
          ..[_message] = 'Success!';
//        nd = provider.addNode('/$connectionNodeName', ConnectionNode.definition(uri, u, p, s));
        _link.save();
        break;
      case AuthResult.notFound:
        ret[_message] = 'Unable to locate device parameters page. '
            'Possible invalid firmware version';
        break;
      case AuthResult.auth:
        ret[_message] = 'Unable to authenticate with provided credentials';
        break;
      default:
        ret[_message] = 'Unknown error occured. Check log file for errors';
        break;
    }

    return ret;
  }
}
