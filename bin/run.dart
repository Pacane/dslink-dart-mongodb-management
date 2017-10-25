import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';

main(List<String> args) async {
  LinkProvider link;

  link = new LinkProvider(args, "MongoDB-", autoInitialize: false, profiles: {
    AddConnection.isType: (String path) => new AddConnection(path, link),
    DatabaseNode.isType: (String path) => new DatabaseNode(path),
  }, defaultNodes: {
    AddConnection.pathName: AddConnection.definition()
  });

  link.init();
  await link.connect();
}
