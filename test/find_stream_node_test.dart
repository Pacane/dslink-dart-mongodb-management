import 'dart:async';
import 'dart:convert';

import 'package:bson/bson.dart';
import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
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
      FindNodeParams.skip: skip,
      FindNodeParams.limit: limit,
      FindNodeParams.batchSize: batchSize,
      FindNodeParams.fields: fields,
      FindNodeParams.dateFields: dateFields
    };
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
              JSON.decode(fields), limit, skip, batchSize))
          .thenReturn(new Stream.empty());
      await node.onInvoke(validParams).toList();

      verify(client.findStreaming(collectionName, JSON.decode(selector),
          JSON.decode(fields), limit, skip, batchSize));
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
              JSON.decode(fields), limit, skip, batchSize))
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
              JSON.decode(fields), limit, skip, batchSize))
          .thenReturn(streamResult);

      expect(() => node.onInvoke(validParams).toList(), returnsNormally);
    });

    test("doesn't crash with objectId items", () {
      final findResult = [
        {'_id': new ObjectId()}
      ];
      final streamResult = new Stream.fromIterable(findResult);
      when(client.findStreaming(collectionName, JSON.decode(selector),
              JSON.decode(fields), limit, skip, batchSize))
          .thenReturn(streamResult);

      expect(() => node.onInvoke(validParams).toList(), returnsNormally);
    });

    group('ISO dates are revived correctly as DateTime in selector', () {
      setUp(() {
        final dateFields = '["date"]';
        validParams[FindNodeParams.dateFields] = dateFields;
        when(client.findStreaming(any, any, any, any, any, any))
            .thenReturn(new Stream.empty());
      });

      test('exact value as string is revived', () async {
        final selector = '{"date": "2017-11-16T00:00:00.000Z"}';
        validParams[FindNodeParams.selector] = selector;

        await node.onInvoke(validParams).toList();

        var actualSelector =
            verify(client.findStreaming(any, captureAny, any, any, any, any))
                .captured
                .first;
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

        await node.onInvoke(validParams).toList();

        var actualSelector =
            verify(client.findStreaming(any, captureAny, any, any, any, any))
                .captured
                .first;
        expect(actualSelector['date']['\$lt'], new isInstanceOf<DateTime>());
        expect(actualSelector['date']['\$gt'], new isInstanceOf<DateTime>());
      });
    });
  });
}
