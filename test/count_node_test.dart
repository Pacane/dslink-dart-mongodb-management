import 'dart:convert';

import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
import 'package:dslink_mongodb_controller/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  Map<String, dynamic> validParams;

  final selector = '{}';

  setUp(() {
    validParams = {
      CountNodeParams.selector: selector,
    };
  });

  group('Null parameters validation', () {
    final testCases = <Tuple>[
      const Tuple(CountNodeParams.selector, CountNodeParams.invalidSelector),
    ];

    for (var testCase in testCases) {
      test('throws when ${testCase.first} is null', () {
        expect(
            () => CountNodeParams
                .validateParams(validParams..remove(testCase.first)),
            throwsA(testCase.second));
      });
    }
  });

  test('query code must be valid JSON', () {
    validParams[CountNodeParams.selector] = '{missing: quotes}';

    expect(() => CountNodeParams.validateParams(validParams),
        throwsA(CountNodeParams.invalidSelector));
  });

  group('onInvoke', () {
    final path = '/somePath';
    final collectionName = 'some name';
    MongoClient client;
    CountNode node;

    setUp(() {
      client = new MongoClientMock();
      node = new CountNode(path, client, collectionName);
    });

    test('delegates to MongoClient', () async {
      await node.onInvoke(validParams);

      verify(client.count(collectionName, JSON.decode(selector)));
    });

    test("returns the count result from the mongo client", () async {
      final selector = {'some': 'selector'};
      final count = 12;
      final expected = {CountNode.result: count};
      validParams[CountNodeParams.selector] = JSON.encode(selector);
      when(client.count(collectionName, selector)).thenReturn(count);

      final actual = await node.onInvoke(validParams);

      expect(actual, expected);
    });
  });
}
