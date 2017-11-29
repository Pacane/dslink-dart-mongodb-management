import 'dart:convert';

import 'package:dslink_mongodb_controller/mongo_dslink.dart';
import 'package:dslink_mongodb_controller/nodes.dart';
import 'package:dslink_mongodb_controller/utils.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  Map<String, dynamic> validParams;

  final pipeline = '[]';
  final dateFields = '[]';

  setUp(() {
    validParams = {
      AggregateNodeParams.aggregatePipeline: pipeline,
      AggregateNodeParams.dateFields: dateFields,
    };
  });

  group('Null parameters validation', () {
    final testCases = <Tuple>[
      const Tuple(AggregateNodeParams.dateFields,
          AggregateNodeParams.invalidDateFieldsErrorMsg),
      const Tuple(AggregateNodeParams.aggregatePipeline,
          AggregateNodeParams.invalidPipelineErrorMsg),
    ];

    for (var testCase in testCases) {
      test('throws when ${testCase.first} is null', () {
        expect(
            () => AggregateNodeParams
                .validateParams(validParams..remove(testCase.first)),
            throwsA(testCase.second));
      });
    }
  });

  group('pipeline must be valid JSON List of maps', () {
    test('throws when invalid JSON', () {
      validParams[AggregateNodeParams.aggregatePipeline] = '[';

      expect(() => AggregateNodeParams.validateParams(validParams),
          throwsA(AggregateNodeParams.invalidPipelineErrorMsg));
    });

    test('throws when a not a list', () {
      validParams[AggregateNodeParams.aggregatePipeline] = '{}';

      expect(() => AggregateNodeParams.validateParams(validParams),
          throwsA(AggregateNodeParams.invalidPipelineErrorMsg));
    });

    test("doesn't throw when empty list", () {
      validParams[AggregateNodeParams.aggregatePipeline] = '[]';

      expect(() => AggregateNodeParams.validateParams(validParams),
          returnsNormally);
    });

    test("doesn't throw when JSON list of maps", () {
      validParams[AggregateNodeParams.aggregatePipeline] =
          '[{"something": {}}, {"something else": 12}]';

      expect(() => AggregateNodeParams.validateParams(validParams),
          returnsNormally);
    });

    test("throws when not a JSON list of maps", () {
      validParams[AggregateNodeParams.aggregatePipeline] = '[12, 13]';

      expect(() => AggregateNodeParams.validateParams(validParams),
          returnsNormally);
    });
  });

  group('onInvoke', () {
    final path = '/somePath';
    final collectionName = 'some name';
    MongoClient client;
    AggregateNode node;

    setUp(() {
      client = new MongoClientMock();
      node = new AggregateNode(path, client, collectionName);
    });

    test('delegates to MongoClient', () async {
      await node.onInvoke(validParams);

      verify(client.aggregate(collectionName, JSON.decode(pipeline)));
    });

    test("returns a JSON encoded version of the client's result", () async {
      final aggregateResult = {'hello': 'you'};
      final expected = {'result': JSON.encode(aggregateResult)};
      when(client.aggregate(any, any)).thenReturn(aggregateResult);

      final actual = await node.onInvoke(validParams);

      expect(actual, expected);
    });
  });
}
