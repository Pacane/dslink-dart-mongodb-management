import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:connection_pool/connection_pool.dart';

class MongoClient {
  final Uri uri;
  final String username;
  final String password;

  Db db;

  MongoClient(this.uri, this.username, this.password);

  Future<AuthResult> testConnection() async {
    var string = uri.toString();
    db = new Db(string);
    try {
      await db.open();
      db.close();
      return AuthResult.ok;
    } catch (e) {
      return AuthResult.authError;
    }
  }
}

enum AuthResult { ok, authError, notFound }

class MongoDbPool extends ConnectionPool<Db> {
  String uri;

  MongoDbPool(String this.uri, [int poolSize = 3]) : super(poolSize);

  @override
  void closeConnection(Db conn) {
    conn.close();
  }

  @override
  Future<Db> openNewConnection() {
    var conn = new Db(uri);
    return conn.open().then((_) => conn);
  }
}
