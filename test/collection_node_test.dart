import 'package:dslink/dslink.dart';
import 'package:mockito/mockito.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';
import 'package:test/test.dart';
import 'mocks.dart';

void main() {
  CollectionNode node;
  MongoClient mongoClient;
  SimpleNodeProvider provider;

  final path = '/somePath';
  final collectionName = 'some name';

  setUp(() {
    mongoClient = new MongoClientMock();
    provider = new ProviderMock();
    node = new CollectionNode.withCustomProvider(
        path, mongoClient, collectionName, provider);
  });

  group('adding actions onCreated', () {
    test('query node', () {
      node.onCreated();

      verify(provider.setNode('$path/${FindNode.pathName}',
          argThat(const isInstanceOf<FindNode>())));
    });
  });
}
