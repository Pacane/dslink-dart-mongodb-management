import 'dart:async';
import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'mocks.dart';

void main() {
  final path = '/pathName';
  SimpleNodeProvider provider;
  MongoClient mongoClient;
  LinkProvider link;

  DatabaseNode dbNode;

  setUp(() {
    mongoClient = new MongoClientMock();
    provider = new ProviderMock();
    link = new LinkProviderMock();
    dbNode =
        new DatabaseNode.withCustomProvider(path, mongoClient, link, provider);
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
    final collections = ['collection1', 'collection2'];
    when(mongoClient.listCollections())
        .thenReturn(new Future.value(collections));

    await dbNode.onCreated();

    verifyInOrder(collections
        .map((collectionName) => provider.setNode(any, any))
        .toList());
    verify(link.save());
  });
}
