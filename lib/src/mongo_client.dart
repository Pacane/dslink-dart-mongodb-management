import 'dart:async';
import 'dart:io';

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

  Future<List<Map<String, dynamic>>> find(String collectionName,
      Map<String, dynamic> code, int limit, int skip) async {
    final db = await connectionPool.connect();
    final collection = db.collection(collectionName);

    final sb = new SelectorBuilder();
    sb.raw(code);

    final c = new Cursor(db, collection, sb);

    c.limit = limit;
    c.skip = skip;
    final result = await c.stream.toList();

    return result;
  }

  Stream<Map<String, dynamic>> findStreaming(String collectionName,
      Map<String, dynamic> code, int limit, int skip) async* {
    final db = await connectionPool.connect();
    final collection = db.collection(collectionName);

    final sb = new SelectorBuilder();
    sb.raw(code);

    final c = new Cursor(db, collection, sb);

    c.limit = limit;
    c.skip = skip;
    await for (var row in c.stream) {
      yield row;
    }
  }

  Future<int> count(
      String collectionName, Map<String, dynamic> selector) async {
    final db = await connectionPool.connect();
    final collection = db.collection(collectionName);

    final count = await collection.count(selector);

    return count;
  }
}

enum AuthResult { ok, authError, notFound, other }

Uri makeAuthenticatedUri(Uri source, String username, String password) =>
    source.replace(userInfo: '$username:$password');
