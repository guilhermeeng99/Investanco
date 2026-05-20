import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/gen/strings.g.dart';

/// Localized label for an [AssetKind].
String assetKindLabel(AssetKind kind) => switch (kind) {
      AssetKind.stockBr => t.assets.kinds.stockBr,
      AssetKind.fiiBr => t.assets.kinds.fiiBr,
      AssetKind.etfBr => t.assets.kinds.etfBr,
      AssetKind.bdrBr => t.assets.kinds.bdrBr,
      AssetKind.stockUs => t.assets.kinds.stockUs,
      AssetKind.etfUs => t.assets.kinds.etfUs,
      AssetKind.crypto => t.assets.kinds.crypto,
      AssetKind.treasury => t.assets.kinds.treasury,
      AssetKind.fixedIncome => t.assets.kinds.fixedIncome,
      AssetKind.fund => t.assets.kinds.fund,
      AssetKind.cash => t.assets.kinds.cash,
    };

/// Localized label for a [Market].
String marketLabel(Market market) => switch (market) {
      Market.br => t.assets.markets.br,
      Market.us => t.assets.markets.us,
      Market.global => t.assets.markets.global,
    };
