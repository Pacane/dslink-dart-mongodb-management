import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';

class MongoClient {
  final Uri uri;
  final String username;
  final String password;

  Db db;

  MongoClient(this.uri, this.username, this.password);

  Future<AuthResult> testConnection() async {
    var uriWithAuth = uri.replace(userInfo: '$username:$password');

    db = new Db(uriWithAuth.toString());
    try {
      var res = await db.open();
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
}

enum AuthResult { ok, authError, notFound, other }
