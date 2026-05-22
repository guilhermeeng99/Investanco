import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Icons a user can pick for an allocation class, keyed by a stable string
/// persisted on the class. Add entries freely; never rename a key already in use
/// (existing classes reference it). See `docs/specs/allocation.md`.
const Map<String, FaIconData> allocationIcons = {
  'chartPie': FontAwesomeIcons.chartPie,
  'arrowTrendUp': FontAwesomeIcons.arrowTrendUp,
  'building': FontAwesomeIcons.building,
  'house': FontAwesomeIcons.house,
  'bitcoin': FontAwesomeIcons.bitcoin,
  'landmark': FontAwesomeIcons.landmark,
  'globe': FontAwesomeIcons.earthAmericas,
  'coins': FontAwesomeIcons.coins,
  'piggyBank': FontAwesomeIcons.piggyBank,
  'industry': FontAwesomeIcons.industry,
  'seedling': FontAwesomeIcons.seedling,
  'gem': FontAwesomeIcons.gem,
};

/// Default icon key for a new class.
const String defaultAllocationIconKey = 'chartPie';

/// Resolves an icon key to its glyph, falling back to the default.
FaIconData allocationIcon(String key) =>
    allocationIcons[key] ?? FontAwesomeIcons.chartPie;

/// Colors a user can pick for an allocation class (ARGB ints).
const List<int> allocationPalette = [
  0xFF00A868,
  0xFF2F6FED,
  0xFFEF6C00,
  0xFFD32F2F,
  0xFF8E24AA,
  0xFF00897B,
  0xFF5E35B1,
  0xFFC0CA33,
  0xFF6D4C41,
  0xFF3949AB,
  0xFFE91E63,
  0xFF43A047,
];

/// A deterministic palette color for the n-th created class.
int defaultAllocationColor(int index) =>
    allocationPalette[index % allocationPalette.length];
