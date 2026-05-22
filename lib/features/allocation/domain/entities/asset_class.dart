import 'package:equatable/equatable.dart';

/// A user-defined allocation bucket. Both **classes** (root) and **subclasses**
/// are this same entity, distinguished by [parentId] (null = root).
///
/// [targetPercent] is the share of the **whole portfolio** for a root, and the
/// share of the **parent class** for a subclass. See `docs/specs/allocation.md`.
class AssetClass extends Equatable {
  /// Creates an allocation class.
  const AssetClass({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.targetPercent,
    required this.createdAt,
    this.parentId,
  });

  /// Stable unique id.
  final String id;

  /// Display name (e.g. "Ações EUA", "VOO").
  final String name;

  /// Key into the presentation icon map (`allocationIcons`).
  final String iconKey;

  /// ARGB color value (rendered via `Color(colorValue)` in the UI).
  final int colorValue;

  /// Target share in percent (`[0, 100]`): of the whole portfolio for a root,
  /// of the parent class for a subclass.
  final double targetPercent;

  /// Parent class id, or null for a root class.
  final String? parentId;

  /// Creation timestamp (drives ordering).
  final DateTime createdAt;

  /// Whether this is a root class (not a subclass).
  bool get isRoot => parentId == null;

  /// Whether this is a subclass (has a parent).
  bool get isSubclass => parentId != null;

  /// [targetPercent] as a `[0, 1]` fraction.
  double get targetFraction => targetPercent / 100;

  /// Returns a copy with the given fields replaced. Pass [clearParentId] to
  /// promote a subclass back to a root.
  AssetClass copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    double? targetPercent,
    String? parentId,
    bool clearParentId = false,
  }) {
    return AssetClass(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      targetPercent: targetPercent ?? this.targetPercent,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, iconKey, colorValue, targetPercent, parentId, createdAt];
}
