import 'dart:async';
import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// ignore: strong_mode_invalid_method_override_from_base
class ProviderMock extends Mock implements SimpleNodeProvider {}

class MongoClientMock extends Mock implements MongoClient {}

void main() {
  var path = '/pathName';
  SimpleNodeProvider provider;
  MongoClient mongoClient;

  SimpleNode dbNode;

  setUp(() {
    mongoClient = new MongoClientMock();
    provider = new ProviderMock();
    dbNode = new DatabaseNode.withCustomProvider(path, mongoClient, provider);
  });

  test('create collections nodes', () async {
    var collections = ['collection1', 'collection2'];
    when(mongoClient.listCollections())
        .thenReturn(new Future.value(collections));

    await dbNode.onCreated();

    for (var collection in collections) {
      var collectionNodePath = '$path/$collection';
      var child = verify(provider.setNode(collectionNodePath, captureAny))
          .captured
          .first;
      expect(child, new isInstanceOf<CollectionNode>());
    }
  });
}
