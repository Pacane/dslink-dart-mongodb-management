import 'package:dslink_dslink_mongodb_management/nodes.dart';
import 'package:dslink_dslink_mongodb_management/utils.dart';
import 'package:test/test.dart';
import 'mocks.dart';

void main() {
  Map<String, dynamic> validParams;

  final code = '{}';
  final limit = 0;
  final skip = 0;

  setUp(() {
    validParams = {
      QueryNodeParams.code: code,
      QueryNodeParams.skip: skip,
      QueryNodeParams.limit: limit
    };
  });

  group('Null parameters validation', () {
    final testCases = [
      const Tuple(QueryNodeParams.code, QueryNodeParams.invalidCodeErrorMsg),
      const Tuple(QueryNodeParams.limit, QueryNodeParams.invalidLimitErrorMsg),
      const Tuple(QueryNodeParams.skip, QueryNodeParams.invalidSkipErrorMsg),
    ];

    for (var testCase in testCases) {
      test('Throws when $testCase is null', () {
        expect(
            () => QueryNodeParams
                .validateParams(validParams..remove(testCase.first)),
            throwsA(testCase.second));
      });
    }
  });
}
