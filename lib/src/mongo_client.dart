import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';

class MongoClient {
  final Uri uri;
  final String username;
  final String password;
  final ConnectionPool connectionPool;

  static const int maxConnections = 3;

  Db db;

  MongoClient(this.uri, this.username, this.password)
      : connectionPool = new ConnectionPool(
            maxConnections,
            () => new Db(
                makeAuthenticatedUri(uri, username, password).toString()));

  Future<AuthResult> testConnection() async {
    var uriWithAuth = makeAuthenticatedUri(uri, username, password);

    db = new Db(uriWithAuth.toString());
    try {
      await db.open();
      db.close();
      return AuthResult.ok;
    } on SocketException catch (_) {
      return AuthResult.notFound;
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
    var db = await connectionPool.connect();
    return db.getCollectionNames();
  }
}

enum AuthResult { ok, authError, notFound, other }

Uri makeAuthenticatedUri(Uri source, String username, String password) =>
    source.replace(userInfo: '$username:$password');
