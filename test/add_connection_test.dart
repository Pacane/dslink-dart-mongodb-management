import 'dart:async';
import 'package:dslink/nodes.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'mocks.dart';

void main() {
  final link = new LinkMock();
  final provider = new ProviderMock();
  final mongoClient = new MongoClientMock();
  final mongoClientFactory = new MongoClientFactoryMock();

  final connectionName = 'connection name';
  final address = 'mongo://something/db';
  final username = 'user';
  final password = 'password';

  AddConnectionNode node;
  Map<String, String> validParams;

  setUp(() {
    node = new AddConnectionNode.withCustomProvider(
        'path', link, mongoClientFactory, provider);

    when(mongoClientFactory.create(any, any, any)).thenReturn(mongoClient);

    validParams = {
      AddConnectionParams.name: connectionName,
      AddConnectionParams.addr: address,
      AddConnectionParams.user: username,
      AddConnectionParams.pass: password
    };
  });

  group('parameters validation', () {
    test("throws error when name is empty", () async {
      expect(
          () => AddConnectionParams
              .validateParams(validParams..remove(AddConnectionParams.name)),
          throwsA('A connection name must be specified.'));
    });

    test("throws error when user is empty", () async {
      expect(
          () => AddConnectionParams
              .validateParams(validParams..remove(AddConnectionParams.user)),
          throwsA('A username must be specified.'));
    });

    test("throws error when password is empty", () async {
      expect(
          () => AddConnectionParams
              .validateParams(validParams..remove(AddConnectionParams.pass)),
          throwsA('A password must be specified.'));
    });

    test("throws error when address is empty", () async {
      expect(
          () => AddConnectionParams
              .validateParams(validParams..remove(AddConnectionParams.addr)),
          throwsA('An address must be specified.'));
    });
  });

  group('onInvoke', () {
    test('adds database node', () async {
      when(mongoClient.testConnection())
          .thenReturn(new Future.value(AuthResult.ok));
      final expectedDbNodePath = '/${NodeNamer.createName(connectionName)}';

      await node.onInvoke(validParams);

      final childQueryNode =
          verify(provider.setNode(expectedDbNodePath, captureAny))
              .captured
              .first;
      expect(childQueryNode, const isInstanceOf<DatabaseNode>());
    });
  });
}
