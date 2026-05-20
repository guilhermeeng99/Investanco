import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// Stable colour per asset class, used by avatars, the allocation chart and
/// legends. Lives with the asset feature so the dashboard depends on assets
/// (not the other way around).
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

/// Glyph per asset class, used in pickers and detail headers.
FaIconData assetKindIcon(AssetKind kind) => switch (kind) {
      AssetKind.stockBr || AssetKind.stockUs => FontAwesomeIcons.chartLine,
      AssetKind.fiiBr => FontAwesomeIcons.building,
      AssetKind.etfBr || AssetKind.etfUs => FontAwesomeIcons.layerGroup,
      AssetKind.bdrBr => FontAwesomeIcons.certificate,
      AssetKind.crypto => FontAwesomeIcons.bitcoin,
      AssetKind.treasury => FontAwesomeIcons.landmark,
      AssetKind.fixedIncome => FontAwesomeIcons.piggyBank,
      AssetKind.fund => FontAwesomeIcons.boxesStacked,
      AssetKind.cash => FontAwesomeIcons.moneyBill,
    };
