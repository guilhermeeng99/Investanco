import 'package:flutter/material.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// Stable color per asset class, used by the allocation chart and legends.
Color assetKindColor(AssetKind kind) => switch (kind) {
      AssetKind.stockBr => const Color(0xFF1565C0),
      AssetKind.fiiBr => const Color(0xFF6A1B9A),
      AssetKind.etfBr => const Color(0xFF00838F),
      AssetKind.bdrBr => const Color(0xFF4527A0),
      AssetKind.stockUs => const Color(0xFF2E7D32),
      AssetKind.etfUs => const Color(0xFF558B2F),
      AssetKind.crypto => const Color(0xFFEF6C00),
      AssetKind.treasury => const Color(0xFF00695C),
      AssetKind.fixedIncome => const Color(0xFF283593),
      AssetKind.fund => const Color(0xFFAD1457),
      AssetKind.cash => const Color(0xFF546E7A),
    };
