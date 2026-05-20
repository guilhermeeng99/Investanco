import 'package:equatable/equatable.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// State for the assets cubit. See `docs/specs/assets.md`.
sealed class AssetsState extends Equatable {
  const AssetsState();

  @override
  List<Object?> get props => [];
}

/// Initial loading state.
class AssetsLoading extends AssetsState {
  /// Creates the loading state.
  const AssetsLoading();
}

/// Loaded with the current list (possibly empty).
class AssetsLoaded extends AssetsState {
  /// Creates the loaded state.
  const AssetsLoaded(this.assets);

  /// Current assets, ordered by ticker.
  final List<Asset> assets;

  @override
  List<Object?> get props => [assets];
}

/// The list stream failed.
class AssetsError extends AssetsState {
  /// Creates the error state.
  const AssetsError();
}
