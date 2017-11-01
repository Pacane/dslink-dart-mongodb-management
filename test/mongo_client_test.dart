import 'dart:convert';
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
    group('simple data', () {
      final collectionName = 'simple_data';
      final client = new MongoClient(uri, username, password);

      test('all', () async {
        final code = '{}';
        final limit = 0, skip = 0;
        final result = await client.find(collectionName, code, limit, skip);

        expect(result, hasLength(3));
        expect(result[0]['name'], 'joel');
        expect(result[1]['name'], 'matt');
        expect(result[2]['name'], 'martine');
      });

      test('regex', () async {
        final code = r'{"name": {"$regex": "mat.*", "$options": "i"}}';
        final limit = 0, skip = 0;
        final result = await client.find(collectionName, code, limit, skip);

        expect(result, hasLength(1));
        expect(result[0]['name'], 'matt');
      });
    });
  });
}
