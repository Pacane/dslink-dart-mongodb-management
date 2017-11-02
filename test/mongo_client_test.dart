import 'dart:io';

import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:test/test.dart';

void main() {
  final uriString = Platform.environment['DB_URI'];
  final username = Platform.environment['DB_USERNAME'];
  final password = Platform.environment['DB_PASSWORD'];

  assert(uriString != null);
  assert(username != null);
  assert(password != null);

  final uri = Uri.parse(uriString);

  group('test connection', () {
    test('returns OK when success', () async {
      final client = new MongoClient(uri, username, password);

      final result = await client.testConnection();

      expect(result, AuthResult.ok);
    });

    test('returns authError when wrong username', () async {
      final client = new MongoClient(uri, 'wrong username', password);

      final result = await client.testConnection();

      expect(result, AuthResult.authError);
    });

    test('returns authError when wrong password', () async {
      final client = new MongoClient(uri, username, 'wrong password');

      final result = await client.testConnection();

      expect(result, AuthResult.authError);
    });

    test('returns notFound when wrong server', () async {
      final newUri = uri.replace(host: 'wrongserver');
      final client = new MongoClient(newUri, username, password);

      final result = await client.testConnection();

      expect(result, AuthResult.notFound);
    });
  });

  group('find', () {
    final client = new MongoClient(uri, username, password);
    final limit = 0, skip = 0;

    group('simple data', () {
      final collectionName = 'simple_data';

      test('all', () async {
        final code = {};
        final result = await client.find(collectionName, code, limit, skip);

        validateAllSimpleData(result);
      });

      test('regex', () async {
        final code = {
          "name": {"\$regex": "mat.*", "\$options": "i"}
        };
        final result = await client.find(collectionName, code, limit, skip);

        expect(result, hasLength(1));
        expect(result[0]['name'], 'matt');
      });

      test("limit is respected", () async {
        final limit = 2;
        final code = {};

        var result = await client.find(collectionName, code, limit, skip);

        expect(result, hasLength(limit));
      });

      test("skip is respected", () async {
        final skip = 2;
        final code = {};

        var result = await client.find(collectionName, code, limit, skip);

        expect(result[0]['name'], 'martine');
      });

      test("orderby is supported", () async {
        final code = {
          r'$query': {},
          r'$orderby': {'name': 1}
        };

        var result = await client.find(collectionName, code, limit, skip);

        var expected = copyAndSortResultsBy(result, 'name');
        expect(result, containsAllInOrder(expected));
      });
    });
  });

  group('findStream', () {
    final client = new MongoClient(uri, username, password);
    final limit = 0, skip = 0;

    group('simple data', () {
      final collectionName = 'simple_data';
      test('all', () async {
        final code = {};

        final result = await client
            .findStreaming(collectionName, code, limit, skip)
            .toList();

        validateAllSimpleData(result);
      });

      test("limit is respected", () async {
        final limit = 2;
        final code = {};

        var result = await client
            .findStreaming(collectionName, code, limit, skip)
            .toList();

        expect(result, hasLength(limit));
      });

      test("skip is respected", () async {
        final skip = 2;
        final code = {};

        var result = await client
            .findStreaming(collectionName, code, limit, skip)
            .toList();

        expect(result[0]['name'], 'martine');
      });
    });
  });
}

copyAndSortResultsBy(List<Map<String, dynamic>> result, dynamic valueToSortBy) {
  final expected = new List.from(result)
    ..sort((Map<String, dynamic> first, Map<String, dynamic> second) =>
        first[valueToSortBy].compareTo(second[valueToSortBy]));
  return expected;
}

void validateAllSimpleData(List<Map<String, dynamic>> result) {
  expect(result, hasLength(9));
  expect(result[0]['name'], 'joel');
  expect(result[1]['name'], 'matt');
  expect(result[2]['name'], 'martine');
  // more data
}
