import 'dart:async';

import 'package:dslink/dslink.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  final path = '/pathName';
  final address = 'address';
  final username = 'username';
  final password = 'password';
  final connectionName = 'name';
  SimpleNodeProvider provider;
  MongoClient mongoClient;
  LinkProvider link;

  DatabaseNode dbNode;

  setUp(() {
    mongoClient = new MongoClientMock();
    provider = new ProviderMock();
    link = new LinkProviderMock();
    dbNode = new DatabaseNode.withCustomProvider(path, address, username,
        password, connectionName, mongoClient, link, provider);
  });

  group('onCreated', () {
    final collections = ['collection1', 'collection2'];

    setUp(() {
      when(mongoClient.listCollections())
          .thenReturn(new Future.value(collections));
    });

    test('create collections nodes', () async {
      final collections = ['collection1', 'collection2'];
      when(mongoClient.listCollections())
          .thenReturn(new Future.value(collections));

      await dbNode.onCreated();

      for (final collection in collections) {
        final collectionNodePath = '$path/$collection';
        verify(provider.setNode(
            collectionNodePath, argThat(const isInstanceOf<CollectionNode>())));
      }
    });

    test('link saves after adding the collections', () async {
      await dbNode.onCreated();

      verifyInOrder(collections
          .map((collectionName) => provider.setNode(
              any, argThat(const isInstanceOf<CollectionNode>())))
          .toList());
      verify(link.save());
    });

    test('adds refresh collections action', () async {
      await dbNode.onCreated();

      verify(provider.setNode('$path/${RefreshCollectionsNode.pathName}',
          argThat(const isInstanceOf<RefreshCollectionsNode>())));
    });

    test('link saves after adding refresh collections action', () async {
      await dbNode.onCreated();

      verify(provider.setNode(
          any, argThat(const isInstanceOf<RefreshCollectionsNode>())));
      verify(link.save());
    });

    test('adds edit connection action', () async {
      await dbNode.onCreated();

      verify(provider.setNode('$path/${EditConnectionNode.pathName}',
          argThat(const isInstanceOf<EditConnectionNode>())));
    });

    test('adds remove connection action', () async {
      await dbNode.onCreated();

      verify(provider.addNode('$path/${RemoveConnectionAction.pathName}',
          RemoveConnectionAction.definition()));
    });
  });
}
