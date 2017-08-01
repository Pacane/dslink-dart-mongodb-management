import 'dart:io';
import 'package:mongo_test_permissions/dslink.dart';
import 'package:test/test.dart';
import 'package:dslink/utils.dart';

String password = Platform.environment['MONGO_PASSWORD'];
String username = Platform.environment['MONGO_USERNAME'];
String address = Platform.environment['MONGO_ADDRESS'];
String databaseName = Platform.environment['MONGO_DBNAME'];

main() {
  setUp(() {
    expect(password, isNotNull);
    expect(username, isNotNull);
    expect(address, isNotNull);
    expect(databaseName, isNotNull);
  });

  test("authenticate returns OK with successful authentication", () async {
    var sut = new MongoClient(address, username, password, databaseName);

    var result = await sut.authenticate();

    expect(result, AuthResult.ok);
  });

  test("authenticate returns an Auth Error with bad password", () async {
    var wrongPassword = 're0e9wfjdskl0-sd';
    var sut = new MongoClient(address, username, wrongPassword, databaseName);

    var result = await sut.authenticate();

    expect(result, AuthResult.auth);
  });

  test("authenticate returns an Auth Error with bad username", () async {
    var wrongUsername = 're0e9wfjdskl0-sd';
    var sut = new MongoClient(address, wrongUsername, password, databaseName);

    var result = await sut.authenticate();

    expect(result, AuthResult.auth);
  });

  test("authenticate returns a NotFound error with bad address", () async {
    var wrongAddress = 'somethingwrong:27000';
    var sut = new MongoClient(wrongAddress, username, password, databaseName);

    var result = await sut.authenticate();

    expect(result, AuthResult.notFound);
  });
}
