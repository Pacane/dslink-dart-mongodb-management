import 'package:dslink/dslink.dart';
import 'package:dslink_dslink_mongodb_management/mongo_dslink.dart';
import 'package:mockito/mockito.dart';

class LinkMock extends Mock implements LinkProvider {}

class MongoClientMock extends Mock implements MongoClient {}

class MongoClientFactoryMock extends Mock implements MongoClientFactory {}

// ignore: strong_mode_invalid_method_override_from_base
class ProviderMock extends Mock implements SimpleNodeProvider {}

class LinkProviderMock extends Mock implements LinkProvider {}
