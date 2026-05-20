import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton placeholder block with a shimmer sweep, used while data loads.
/// Mirrors financo's `LoadingShimmer`.
class LoadingShimmer extends StatelessWidget {
  /// Creates a shimmer block.
  const LoadingShimmer({
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = 16,
    super.key,
  });

  /// Block width.
  final double width;

  /// Block height.
  final double height;

  /// Corner radius.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A vertical stack of [LoadingShimmer] blocks, a convenient default skeleton
/// for list pages while the first load completes.
class LoadingShimmerList extends StatelessWidget {
  /// Creates a list of shimmer rows.
  const LoadingShimmerList({
    this.itemCount = 6,
    this.itemHeight = 72,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  /// Number of skeleton rows.
  final int itemCount;

  /// Height of each row.
  final double itemHeight;

  /// Outer padding.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => LoadingShimmer(height: itemHeight),
    );
  }
}
