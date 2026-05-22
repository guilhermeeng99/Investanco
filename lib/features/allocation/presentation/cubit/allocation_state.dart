import 'package:equatable/equatable.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/entities/investment_overview.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// State for the allocation feature. See `docs/specs/allocation.md`.
sealed class AllocationState extends Equatable {
  const AllocationState();

  @override
  List<Object?> get props => [];
}

/// Computing the first overview from cache.
class AllocationLoading extends AllocationState {
  /// Creates the loading state.
  const AllocationLoading();
}

/// Loaded overview (rendered from cache, refreshed in the background).
class AllocationLoaded extends AllocationState {
  /// Creates the loaded state.
  const AllocationLoaded({
    required this.overview,
    required this.classes,
    required this.assets,
    required this.isRefreshing,
  });

  /// The computed allocation snapshot.
  final InvestmentOverview overview;

  /// All classes + subclasses (entities), for forms and detail views.
  final List<AssetClass> classes;

  /// All assets, for the assign-to-class flow.
  final List<Asset> assets;

  /// Whether a background refresh is in flight.
  final bool isRefreshing;

  /// The class entity for [id], or null.
  AssetClass? classById(String id) {
    for (final c in classes) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The asset entity for [id], or null.
  Asset? assetById(String id) {
    for (final a in assets) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// The overview slice for class [id], or null.
  InvestmentClassSlice? sliceById(String id) {
    for (final s in overview.classes) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  List<Object?> get props => [overview, classes, assets, isRefreshing];
}

/// No data could be loaded.
class AllocationError extends AllocationState {
  /// Creates the error state.
  const AllocationError();
}
