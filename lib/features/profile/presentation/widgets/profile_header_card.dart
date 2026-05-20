import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Hero element of the profile page — the user's identity as a card with a
/// gradient-tinted avatar (or photo) on the left and name + email on the right.
/// Mirrors financo's `ProfileHeaderCard`.
class ProfileHeaderCard extends StatefulWidget {
  /// Creates the header card.
  const ProfileHeaderCard({
    required this.name,
    required this.email,
    this.photoUrl,
    super.key,
  });

  /// Display name.
  final String name;

  /// Account email.
  final String email;

  /// Avatar URL, when available.
  final String? photoUrl;

  @override
  State<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<ProfileHeaderCard> {
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _Avatar(
            name: widget.name,
            photoUrl: widget.photoUrl,
            imageError: _imageError,
            onImageError: () => setState(() => _imageError = true),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name.isEmpty ? widget.email : widget.name,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: colors.onBackground,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.email,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onBackgroundLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.photoUrl,
    required this.imageError,
    required this.onImageError,
  });

  final String name;
  final String? photoUrl;
  final bool imageError;
  final VoidCallback onImageError;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty && !imageError;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onImageError();
                });
                return _initialFallback();
              },
            )
          : _initialFallback(),
    );
  }

  Widget _initialFallback() {
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          height: 1,
        ),
      ),
    );
  }
}
