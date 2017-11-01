import 'dart:async';
import 'dart:math';

import 'package:dslink/dslink.dart';

Future main(List<String> args) async {
  final link = new LinkProvider(args, "Example-",
      profiles: {TesterNode.isType: (String path) => new TesterNode(path)});

  final numGen = new Random();
  var myNum = numGen.nextInt(50);

  final myNode = link.addNode('/MyNum', {
    r'$name': 'My Number',
    r'$type': 'num',
    r'?value': myNum,
  });

  link.addNode('/Test_node', TesterNode.def());

  new Timer.periodic(const Duration(seconds: 10), (_) {
    if (myNode.hasSubscriber) {
      myNum = numGen.nextInt(50);
      myNode.updateValue(myNum);
    }
  });

  link.init();

  await link.connect();
}

class TesterNode extends SimpleNode {
  TesterNode(String path) : super(path);

  static const String isType = 'testerNode';
  static const String pathName = 'Test_Node';

  static Map<String, dynamic> def() => {
        r'$is': isType,
        r'$name': 'Test Node',
        r'$invokable': 'write',
        r'$params': [
          {"name": "test", "type": "bool"}
        ],
        r'$columns': []
      };

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    throw new Exception("That's broken");
  }
}
