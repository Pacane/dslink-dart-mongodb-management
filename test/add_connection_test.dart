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
  Map<String, String> validParams;

  setUp(() {
    node = new AddConnectionNode('path', link);

    validParams = {
      AddConnectionParams.name: 'connection name',
      AddConnectionParams.addr: 'mongo://something/db',
      AddConnectionParams.user: 'user',
      AddConnectionParams.pass: 'password'
    };
  });

  test("throws error when name is empty", () async {
    expect(() => node.onInvoke(validParams..remove(AddConnectionParams.name)),
        throwsA('A connection name must be specified.'));
  });

  test("throws error when user is empty", () async {
    expect(() => node.onInvoke(validParams..remove(AddConnectionParams.user)),
        throwsA('A username must be specified.'));
  });

  test("throws error when password is empty", () async {
    expect(() => node.onInvoke(validParams..remove(AddConnectionParams.pass)),
        throwsA('A password must be specified.'));
  });

  test("throws error when address is empty", () async {
    expect(() => node.onInvoke(validParams..remove(AddConnectionParams.addr)),
        throwsA('An address must be specified.'));
  });
}
