import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/records/presentation/pages/records_page.dart';

void main() {
  group('recordsTabFromQuery (deep-link → initial sub-view)', () {
    test('maps "transactions" to the transactions sub-view', () {
      expect(recordsTabFromQuery('transactions'), RecordsTab.transactions);
    });

    test('maps "assets" to the assets sub-view', () {
      expect(recordsTabFromQuery('assets'), RecordsTab.assets);
    });

    test('defaults to assets for a null or unknown value', () {
      expect(recordsTabFromQuery(null), RecordsTab.assets);
      expect(recordsTabFromQuery('whatever'), RecordsTab.assets);
    });
  });
}
