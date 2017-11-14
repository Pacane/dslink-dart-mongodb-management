import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink/nodes.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';
import 'utils.dart';

void main() {
  final link = new LinkMock();
  SimpleNodeProvider provider;
  MongoClient mongoClient;
  MongoClientFactory mongoClientFactory;

  final connectionName = 'connection name';
  final address = 'mongo://something/db';
  final username = 'user';
  final password = 'password';

  AddConnectionNode node;
  Map<String, String> validParams;

  setUp(() {
    provider = new ProviderMock();
    mongoClient = new MongoClientMock();
    mongoClientFactory = new MongoClientFactoryMock();

    node = new AddConnectionNode.withCustomProvider(
        'path', link, mongoClientFactory, provider);

    when(mongoClientFactory.create(Uri.parse(address), username, password))
        .thenReturn(mongoClient);

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
          throwsA(AddConnectionParams.emptyNameErrorMsg));
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
    final expectedDbNodePath = '/${NodeNamer.createName(connectionName)}';
    final someNode = new SimpleNode('somePath');

    test('adds database node', () async {
      when(mongoClient.testConnection())
          .thenReturn(new Future.value(AuthResult.ok));

      await node.onInvoke(validParams);

      verify(provider.setNode(
          expectedDbNodePath, argThat(const isInstanceOf<DatabaseNode>())));
    });

    test('throws an error when a connection with that name already exists',
        () async {
      when(provider.getNode(expectedDbNodePath)).thenReturn(someNode);

      await expectThrowsAsync(() => node.onInvoke(validParams),
          AddConnectionNode.connectionAlreadyExistErrorMsg);
    });

    test('throws an error when credentials are wrong', () async {
      when(mongoClient.testConnection())
          .thenReturn(new Future.value(AuthResult.authError));

      await expectThrowsAsync(() => node.onInvoke(validParams),
          AddConnectionNode.wrongCredentialsErrorMsg);
    });

    test('throws an error when database is unreachable', () async {
      when(mongoClient.testConnection())
          .thenReturn(new Future.value(AuthResult.notFound));

      await expectThrowsAsync(() => node.onInvoke(validParams),
          AddConnectionNode.notFoundErrorMsg);
    });
  });
}
