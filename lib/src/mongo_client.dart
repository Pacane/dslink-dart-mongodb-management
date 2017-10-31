import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

class MongoClientFactory {
  MongoClient create(Uri uri, String username, String password) =>
      new MongoClient(uri, username, password);
}

class MongoClient {
  final Uri uri;
  final String username;
  final String password;
  final ConnectionPool connectionPool;

  static const int maxConnections = 3;

  MongoClient(this.uri, this.username, this.password)
      : connectionPool = new ConnectionPool(
            maxConnections,
            () => new Db(
                makeAuthenticatedUri(uri, username, password).toString()));

  Future<AuthResult> testConnection() async {
    final uriWithAuth = makeAuthenticatedUri(uri, username, password);

    final db = new Db(uriWithAuth.toString());
    try {
      await db.open();
      await db.close();
      return AuthResult.ok;
    } on SocketException catch (_) {
      return AuthResult.notFound;
    } on MongoDartError catch (_) {
      rethrow;
    } catch (e) {
      if (e['code'] == 18) {
        return AuthResult.authError;
      } else {
        return AuthResult.other;
      }
    }
  }

  /// List collection names for a given database
  Future<List<String>> listCollections() async {
    final db = await connectionPool.connect();
    return db.getCollectionNames();
  }
}

enum AuthResult { ok, authError, notFound, other }

Uri makeAuthenticatedUri(Uri source, String username, String password) =>
    source.replace(userInfo: '$username:$password');
