import 'dart:convert';

import 'package:bson/bson.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:dslink_dslink_mongodb_management/nodes.dart';
import 'package:dslink_dslink_mongodb_management/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  Map<String, dynamic> validParams;

  final selector = '{}';
  final limit = 0;
  final skip = 0;

  setUp(() {
    validParams = {
      FindNodeParams.selector: selector,
      FindNodeParams.skip: skip,
      FindNodeParams.limit: limit
    };
  });

  group('Null parameters validation', () {
    final testCases = <Tuple>[
      const Tuple(
          FindNodeParams.selector, FindNodeParams.invalidSelectorErrorMsg),
      const Tuple(FindNodeParams.limit, FindNodeParams.invalidLimitErrorMsg),
      const Tuple(FindNodeParams.skip, FindNodeParams.invalidSkipErrorMsg),
    ];

    for (var testCase in testCases) {
      test('throws when ${testCase.first} is null', () {
        expect(
            () => FindNodeParams
                .validateParams(validParams..remove(testCase.first)),
            throwsA(testCase.second));
      });
    }
  });

  test('selector must be valid JSON', () {
    validParams[FindNodeParams.selector] = '{missing: quotes}';

    expect(() => FindNodeParams.validateParams(validParams),
        throwsA(FindNodeParams.invalidSelectorErrorMsg));
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

      verify(client.find(collectionName, JSON.decode(selector), limit, skip));
    });

    test("returns a JSON encoded version of find's result", () async {
      final findResult = [
        {'result': true}
      ];
      final expected = {'result': JSON.encode(findResult)};
      when(client.find(collectionName, JSON.decode(selector), limit, skip))
          .thenReturn(findResult);

      final actual = await node.onInvoke(validParams);

      expect(actual, expected);
    });

    test("doesn't crash with DateTime items", () {
      final findResult = [
        {'date': new DateTime.now()}
      ];
      when(client.find(collectionName, JSON.decode(selector), limit, skip))
          .thenReturn(findResult);

      expect(() => node.onInvoke(validParams), returnsNormally);
    });

    test("doesn't crash with objectId items", () {
      final findResult = [
        {'_id': new ObjectId.fromHexString('5a037dcf275c5fe584428f72')}
      ];
      when(client.find(collectionName, JSON.decode(selector), limit, skip))
          .thenReturn(findResult);

      expect(() => node.onInvoke(validParams), returnsNormally);
    });
  });
}
