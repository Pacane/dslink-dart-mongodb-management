import 'dart:io';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:test/test.dart';

void main() {
  group('test connection', () {
    final uri = Uri.parse(Platform.environment['DB_URI']);
    final username = Platform.environment['DB_USERNAME'];
    final password = Platform.environment['DB_PASSWORD'];

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
}
