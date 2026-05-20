import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/fixed_income_metadata.dart';

import '../../harness/factories/asset_factory.dart';

void main() {
  test('write then read round-trips basis and rate', () {
    final metadata = FixedIncomeMetadata.write(FixedIncomeBasis.ipca, 6.5);
    final parsed = FixedIncomeMetadata.read(assetFactory(metadata: metadata));

    expect(parsed?.$1, FixedIncomeBasis.ipca);
    expect(parsed?.$2, 6.5);
  });

  test('formats whole rates without a trailing decimal', () {
    final metadata = FixedIncomeMetadata.write(FixedIncomeBasis.cdi, 110);

    expect(metadata[FixedIncomeMetadata.rateKey], '110');
  });

  test('read returns null when metadata is absent or invalid', () {
    expect(FixedIncomeMetadata.read(assetFactory()), isNull);
    expect(
      FixedIncomeMetadata.read(assetFactory(metadata: const {'fiBasis': 'cdi'})),
      isNull,
    );
    expect(
      FixedIncomeMetadata.read(
        assetFactory(metadata: const {'fiBasis': 'bogus', 'fiRate': '10'}),
      ),
      isNull,
    );
  });
}
