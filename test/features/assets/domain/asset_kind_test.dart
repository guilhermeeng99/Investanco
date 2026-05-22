import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

void main() {
  group('AssetKind.selectableKinds', () {
    test('offers exactly the kinds in active use, in order', () {
      expect(AssetKind.selectableKinds, [
        AssetKind.etfUs,
        AssetKind.crypto,
        AssetKind.fixedIncome,
      ]);
    });

    test('is a subset of the full enum (so stored data still deserializes)', () {
      expect(
        AssetKind.selectableKinds.every(AssetKind.values.contains),
        isTrue,
      );
    });
  });
}
