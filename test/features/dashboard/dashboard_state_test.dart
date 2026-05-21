import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/institution_factory.dart';

void main() {
  DashboardLoaded loaded({
    Map<String, Institution> institutions = const {},
    Map<String, Asset> assets = const {},
  }) {
    return DashboardLoaded(
      portfolio: PortfolioValuation.empty(),
      assetsById: assets,
      institutionsById: institutions,
      isRefreshing: false,
      snapshots: const [],
    );
  }

  group('nextSetupStep', () {
    test('is institution when nothing has been added', () {
      expect(loaded().nextSetupStep, PortfolioSetupStep.institution);
    });

    test('is asset when an institution exists but no asset', () {
      final state = loaded(institutions: {'i': institutionFactory()});
      expect(state.nextSetupStep, PortfolioSetupStep.asset);
    });

    test('is transaction when institutions and assets exist', () {
      final state = loaded(
        institutions: {'i': institutionFactory()},
        assets: {'a': assetFactory()},
      );
      expect(state.nextSetupStep, PortfolioSetupStep.transaction);
    });
  });
}
