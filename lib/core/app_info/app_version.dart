import 'package:equatable/equatable.dart';

/// Immutable snapshot of the running app's version, read from the platform
/// package info at startup (e.g. `0.1.0`). Mirrors financo's `AppVersion`.
class AppVersion extends Equatable {
  /// Creates a version snapshot.
  const AppVersion({required this.version});

  /// Semver string from `pubspec.yaml`.
  final String version;

  /// What the UI renders. Kept as a getter so formatting can evolve (e.g. add a
  /// build number) without touching call sites.
  String get display => version;

  @override
  List<Object> get props => [version];
}
