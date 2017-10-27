import 'dart:io';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:test/test.dart';

main() {
  group('test connection', () {
    var uri = Uri.parse(Platform.environment['DB_URI']);
    var username = Platform.environment['DB_USERNAME'];
    var password = Platform.environment['DB_PASSWORD'];

    test('returns OK when success', () async {
      var client = new MongoClient(uri, username, password);

      var result = await client.testConnection();

      expect(result, AuthResult.ok);
    });

    test('returns authError when wrong username', () async {
      var client = new MongoClient(uri, 'wrong username', password);

      var result = await client.testConnection();

      expect(result, AuthResult.authError);
    });

    test('returns authError when wrong password', () async {
      var client = new MongoClient(uri, username, 'wrong password');

      var result = await client.testConnection();

      expect(result, AuthResult.authError);
    });

    test('returns notFound when wrong server', () async {
      var client =
          new MongoClient(uri.replace(host: 'wrongserver'), username, password);

      var result = await client.testConnection();

      expect(result, AuthResult.notFound);
    });
  });
}
