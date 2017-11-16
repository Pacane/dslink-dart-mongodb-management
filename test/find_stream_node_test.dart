import 'dart:async';
import 'dart:convert';

import 'package:bson/bson.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
import 'package:dslink_mongodb_controller/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  Map<String, dynamic> validParams;

  final selector = '{}';
  final fields = '[]';
  final limit = 0;
  final skip = 0;

  setUp(() {
    validParams = {
      FindNodeParams.selector: selector,
      FindNodeParams.skip: skip,
      FindNodeParams.limit: limit,
      FindNodeParams.fields: fields
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

  test('query code must be valid JSON', () {
    validParams[FindNodeParams.selector] = '{missing: quotes}';

    expect(() => FindNodeParams.validateParams(validParams),
        throwsA(FindNodeParams.invalidSelectorErrorMsg));
  });

  group('onInvoke', () {
    final path = '/somePath';
    final collectionName = 'some name';
    MongoClient client;
    FindStreamNode node;

    setUp(() {
      client = new MongoClientMock();
      node = new FindStreamNode(path, client, collectionName);
    });

    test('delegates to MongoClient', () async {
      when(client.findStreaming(collectionName, JSON.decode(selector),
              JSON.decode(fields), limit, skip))
          .thenReturn(new Stream.empty());
      await node.onInvoke(validParams).toList();

      verify(client.findStreaming(collectionName, JSON.decode(selector),
          JSON.decode(fields), limit, skip));
    });

    // This is because it is the way DSA manages streaming tables.
    test("returns each record JSON encoded in a double list", () async {
      var data = [
        {'result': 1},
        {'result': 2},
        {'result': 3},
        {'result': 4}
      ];
      final findResult = new Stream<Map<String, int>>.fromIterable(data);
      final expected = data
          .map((d) => [
                [JSON.encode(d)]
              ])
          .toList();
      when(client.findStreaming(collectionName, JSON.decode(selector),
              JSON.decode(fields), limit, skip))
          .thenReturn(findResult);

      final actual = await node.onInvoke(validParams).toList();

      expect(actual, expected);
    });

    test("doesn't crash with DateTime items", () async {
      final findResult = [
        {'date': new DateTime.now()}
      ];
      final streamResult = new Stream.fromIterable(findResult);
      when(client.findStreaming(collectionName, JSON.decode(selector),
              JSON.decode(fields), limit, skip))
          .thenReturn(streamResult);

      expect(() => node.onInvoke(validParams).toList(), returnsNormally);
    });

    test("doesn't crash with objectId items", () {
      final findResult = [
        {'_id': new ObjectId()}
      ];
      final streamResult = new Stream.fromIterable(findResult);
      when(client.findStreaming(collectionName, JSON.decode(selector),
              JSON.decode(fields), limit, skip))
          .thenReturn(streamResult);

      expect(() => node.onInvoke(validParams).toList(), returnsNormally);
    });
  });
}
