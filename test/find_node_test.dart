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
  final dateFields = '[]';
  final limit = 0;
  final skip = 0;
  final batchSize = 20;

  setUp(() {
    validParams = {
      FindNodeParams.selector: selector,
      FindNodeParams.fields: fields,
      FindNodeParams.dateFields: dateFields,
      FindNodeParams.skip: skip,
      FindNodeParams.limit: limit,
      FindNodeParams.batchSize: batchSize
    };
  });

  group('Null parameters validation', () {
    final testCases = <Tuple>[
      const Tuple(FindNodeParams.fields, FindNodeParams.invalidFieldsErrorMsg),
      const Tuple(
          FindNodeParams.dateFields, FindNodeParams.invalidDateFieldsErrorMsg),
      const Tuple(
          FindNodeParams.selector, FindNodeParams.invalidSelectorErrorMsg),
      const Tuple(FindNodeParams.limit, FindNodeParams.invalidLimitErrorMsg),
      const Tuple(FindNodeParams.skip, FindNodeParams.invalidSkipErrorMsg),
      const Tuple(
          FindNodeParams.batchSize, FindNodeParams.invalidBatchSizeErrorMsg),
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

  group('selector must be valid JSON map', () {
    test('throws when invalid JSON', () {
      validParams[FindNodeParams.selector] = '{missing: quotes}';

      expect(() => FindNodeParams.validateParams(validParams),
          throwsA(FindNodeParams.invalidSelectorErrorMsg));
    });

    test('throws when a list', () {
      validParams[FindNodeParams.selector] = '[]';

      expect(() => FindNodeParams.validateParams(validParams),
          throwsA(FindNodeParams.invalidSelectorErrorMsg));
    });

    test("doesn't throw when valid", () {
      test('throws when a number', () {
        validParams[FindNodeParams.selector] = '{}';

        expect(
            () => FindNodeParams.validateParams(validParams), returnsNormally);
      });
    });
  });

  group('fields must be a valid JSON list of strings', () {
    final testCases = <Tuple>[
      const Tuple(FindNodeParams.fields, FindNodeParams.invalidFieldsErrorMsg),
      const Tuple(
          FindNodeParams.dateFields, FindNodeParams.invalidDateFieldsErrorMsg),
    ];

    for (var c in testCases) {
      test('throws when invalid JSON', () {
        validParams[c.first] = '{]';

        expect(() => FindNodeParams.validateParams(validParams),
            throwsA(c.second));
      });

      test('throws when not a list of strings', () {
        validParams[c.first] = '[1,2,3]';

        expect(() => FindNodeParams.validateParams(validParams),
            throwsA(c.second));
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

      verify(client.find(collectionName, JSON.decode(selector),
          JSON.decode(fields), limit, skip, batchSize));
    });

    group('ISO dates are revived correctly as DateTime in selector', () {
      setUp(() {
        final dateFields = '["date"]';
        validParams[FindNodeParams.dateFields] = dateFields;
      });

      test('exact value as string is revived', () async {
        final selector = '{"date": "2017-11-16T00:00:00.000Z"}';
        validParams[FindNodeParams.selector] = selector;

        await node.onInvoke(validParams);

        var actualSelector =
            verify(client.find(any, captureAny, any, any, any, any)).captured[
                0];
        expect(actualSelector['date'], new isInstanceOf<DateTime>());
      });

      test('date range values are revived', () async {
        final selector = r'''
            {
              "date": {
                        "$lt": "2017-11-16T00:00:00.000Z", 
                        "$gt": "2016-11-16T00:00:00.000Z"
              }
            }
            ''';
        validParams[FindNodeParams.selector] = selector;

        await node.onInvoke(validParams);

        var actualSelector =
            verify(client.find(any, captureAny, any, any, any, any)).captured[
                0];
        expect(actualSelector['date']['\$lt'], new isInstanceOf<DateTime>());
        expect(actualSelector['date']['\$gt'], new isInstanceOf<DateTime>());
      });
    });

    test("returns a JSON encoded version of find's result", () async {
      final findResult = [
        {'result': true}
      ];
      final expected = {'result': JSON.encode(findResult)};
      when(client.find(any, any, any, any, any, any)).thenReturn(findResult);

      final actual = await node.onInvoke(validParams);

      expect(actual, expected);
    });

    test("doesn't crash with DateTime items", () {
      final findResult = [
        {'date': new DateTime.now()}
      ];
      when(client.find(collectionName, JSON.decode(selector),
              JSON.decode(fields), limit, skip, batchSize))
          .thenReturn(findResult);

      expect(() => node.onInvoke(validParams), returnsNormally);
    });

    test("doesn't crash with objectId items", () {
      final findResult = [
        {'_id': new ObjectId.fromHexString('5a037dcf275c5fe584428f72')}
      ];
      when(client.find(collectionName, JSON.decode(selector),
              JSON.decode(fields), limit, skip, batchSize))
          .thenReturn(findResult);

      expect(() => node.onInvoke(validParams), returnsNormally);
    });
  });
}
