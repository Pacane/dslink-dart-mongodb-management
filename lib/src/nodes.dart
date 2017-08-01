import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart' show NodeNamer;

class AddDevice extends SimpleNode {
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

  AddDevice(String path, this._link) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    final ret = {_success: false, _message: ''};

    if (params[_name] == null || params[_name].isEmpty) {
      return ret..[_message] = 'A name must be specified.';
    }
    var name = NodeNamer.createName(params[_name].trim());

    var nd = provider.getNode('/$name');
    if (nd != null) {
      return ret..[_message] = 'A device by that name already exists.';
    }

    Uri uri;
    try {
      uri = Uri.parse(params[_addr]);
    } catch (e) {
      return ret..[_message] = 'Error parsing Address: $e';
    }

    var u = params[_user];
    var p = params[_pass];
    var s = params[_sec] as bool;
    var cl = new VClient(uri, u, p, s);
    var res = await cl.authenticate();

    switch (res) {
      case AuthError.ok:
        ret
          ..[_success] = true
          ..[_message] = 'Success!';
        nd = provider.addNode('/$name', DeviceNode.definition(uri, u, p, s));
        _link.save();
        break;
      case AuthError.notFound:
        ret[_message] = 'Unable to locate device parameters page. '
            'Possible invalid firmware version';
        break;
      case AuthError.auth:
        ret[_message] = 'Unable to authenticate with provided credentials';
        break;
      default:
        ret[_message] = 'Unknown error occured. Check log file for errors';
        break;
    }

    return ret;
  }
}
