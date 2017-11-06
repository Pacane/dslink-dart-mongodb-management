import 'dart:async';
import 'dart:convert';

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
      FindStreamNodeParams.selector: selector,
      FindStreamNodeParams.skip: skip,
      FindStreamNodeParams.limit: limit
    };
  });

  // TODO: See if we can use the FindNodeParams
  group('Null parameters validation', () {
    final testCases = <Tuple>[
      const Tuple(FindStreamNodeParams.selector,
          FindStreamNodeParams.invalidSelectorErrorMsg),
      const Tuple(FindStreamNodeParams.limit,
          FindStreamNodeParams.invalidLimitErrorMsg),
      const Tuple(
          FindStreamNodeParams.skip, FindStreamNodeParams.invalidSkipErrorMsg),
    ];

    for (var testCase in testCases) {
      test('throws when ${testCase.first} is null', () {
        expect(
            () => FindStreamNodeParams
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
      await node.onInvoke(validParams).toList();

      verify(client.findStreaming(
          collectionName, JSON.decode(selector), limit, skip));
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
      when(client.findStreaming(
              collectionName, JSON.decode(selector), limit, skip))
          .thenReturn(findResult);

      final actual = await node.onInvoke(validParams).toList();

      expect(actual, expected);
    });
  });
}
