import 'package:dslink/dslink.dart';

class RemoveConnectionAction extends SimpleNode {
  static const String isType = 'removeConnectionAction';
  static const String pathName = 'remove';

  RemoveConnectionAction(String path) : super(path);

  static Map<String, dynamic> definition() => {
        r'$is': isType,
        r'$name': 'Remove connection',
        r'$invokable': 'write',
      };

  bool get serializable => false;

  @override
  void onInvoke(Map<String, dynamic> params) {
    parent.remove();
  }
}
