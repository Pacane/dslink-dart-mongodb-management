import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

class MockLink extends Mock implements LinkProvider {}

class MockMongoClient extends Mock implements MongoClient {}

main() {
  var link = new MockLink();
  var client = new MockMongoClient();
  SimpleNode node;

  var validParams = {
    AddConnectionParams.name: 'connection name',
    AddConnectionParams.addr: 'mongo://something/db',
    AddConnectionParams.user: 'user',
    AddConnectionParams.pass: 'password'
  };

  setUp(() {
    node = new AddConnection('path', link);
  });

  test("throws error when name is empty", () async {
    expect(() => node.onInvoke(validParams..remove(AddConnectionParams.name)),
        throwsA('A connection name must be specified.'));
  });
}
