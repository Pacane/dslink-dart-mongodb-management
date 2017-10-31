import 'dart:async';
import 'package:mockito/mockito.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';
import 'package:dslink_dslink_mongodb_management/utils.dart';
import 'package:test/test.dart';
import 'mocks.dart';

Future main() {
  Map<String, dynamic> validParams;

  final code = '{}';
  final limit = 0;
  final skip = 0;

  setUp(() {
    validParams = {
      FindNodeParams.code: code,
      FindNodeParams.skip: skip,
      FindNodeParams.limit: limit
    };
  });

  group('Null parameters validation', () {
    final testCases = [
      const Tuple(FindNodeParams.code, FindNodeParams.invalidCodeErrorMsg),
      const Tuple(FindNodeParams.limit, FindNodeParams.invalidLimitErrorMsg),
      const Tuple(FindNodeParams.skip, FindNodeParams.invalidSkipErrorMsg),
    ];

    for (var testCase in testCases) {
      test('Throws when $testCase is null', () {
        expect(
            () => FindNodeParams
                .validateParams(validParams..remove(testCase.first)),
            throwsA(testCase.second));
      });
    }
  });

  group('onInvoke', () {
    final path = '/somePath';
    final collectionName = 'some name';
    MongoClient client;
    FindNode node;

    setUp(() {
      client = new MongoClientMock();
      node = new FindNode(path, client, collectionName);
    });

    test('delegates to MongoClient', () async {
      await node.onInvoke(validParams);

      verify(client.find(collectionName, code, limit, skip));
    });
  });
}