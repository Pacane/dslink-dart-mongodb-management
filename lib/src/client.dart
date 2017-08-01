import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:io';

enum AuthResult { ok, notFound, server, auth }

class MongoClient {
  String databaseName;
  String username;
  String password;
  String address;

  /// [address] Should be a String representing the address of the mongoDB
  /// instance. e.g. mongodb://localhost:6000
  MongoClient(this.address, this.username, this.password, this.databaseName);

  Future<AuthResult> authenticate() async {
    var db = new Db('mongodb://$username:$password@$address/$databaseName');
    try {
      await db.open();
      return AuthResult.ok;
    } on SocketException catch(e) {
      return AuthResult.notFound;
    } catch (e) {
      var errorCode = e['code'];

      if (errorCode == null || e['ok'] != 0.0) {
        return AuthResult.server;
      }

      if (errorCode == 18) {
        return AuthResult.auth;
      } else {
        return AuthResult.server;
      }
    }
  }
}
