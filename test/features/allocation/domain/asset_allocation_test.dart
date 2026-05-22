import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/allocation/domain/asset_allocation.dart';

import '../../../harness/factories/asset_factory.dart';

void main() {
  group('applyAllocation', () {
    test('writes the class id and a whole target without a decimal', () {
      final result = applyAllocation(
        const {},
        classId: 'equities',
        targetPercent: 60,
      );

      expect(result[allocationClassIdKey], 'equities');
      expect(result[allocationTargetKey], '60');
    });

    test('keeps a fractional target in its natural form', () {
      final result = applyAllocation(
        const {},
        classId: 'equities',
        targetPercent: 12.5,
      );

      expect(result[allocationTargetKey], '12.5');
    });

    test('preserves unrelated metadata keys', () {
      final result = applyAllocation(
        const {'tesouroName': 'Tesouro IPCA+ 2029'},
        classId: 'fixedIncome',
        targetPercent: 10,
      );

      expect(result['tesouroName'], 'Tesouro IPCA+ 2029');
    });

    test('a null class id clears both allocation keys but keeps the rest', () {
      final result = applyAllocation(
        const {
          allocationClassIdKey: 'equities',
          allocationTargetKey: '60',
          'tesouroName': 'X',
        },
        classId: null,
        targetPercent: 0,
      );

      expect(result.containsKey(allocationClassIdKey), isFalse);
      expect(result.containsKey(allocationTargetKey), isFalse);
      expect(result['tesouroName'], 'X');
    });

    test('an empty class id also clears the allocation keys', () {
      final result = applyAllocation(
        const {allocationClassIdKey: 'equities', allocationTargetKey: '60'},
        classId: '',
        targetPercent: 0,
      );

      expect(result.containsKey(allocationClassIdKey), isFalse);
      expect(result.containsKey(allocationTargetKey), isFalse);
    });

    test('does not mutate the caller-supplied map', () {
      final original = <String, String>{};
      applyAllocation(original, classId: 'x', targetPercent: 5);
      expect(original, isEmpty);
    });
  });

  group('read helpers', () {
    test('allocationClassIdOf returns the id, or null when absent/empty', () {
      expect(
        allocationClassIdOf(
          assetFactory(metadata: const {allocationClassIdKey: 'eq'}),
        ),
        'eq',
      );
      expect(allocationClassIdOf(assetFactory()), isNull);
      expect(
        allocationClassIdOf(
          assetFactory(metadata: const {allocationClassIdKey: ''}),
        ),
        isNull,
      );
    });

    test('allocationTargetOf parses the target, defaulting to 0', () {
      expect(
        allocationTargetOf(
          assetFactory(metadata: const {allocationTargetKey: '60'}),
        ),
        60,
      );
      expect(allocationTargetOf(assetFactory()), 0);
    });
  });
}
