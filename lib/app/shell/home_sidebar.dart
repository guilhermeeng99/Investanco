part of 'home_shell.dart';

const _railCollapsedWidth = 80.0;
const _railExpandedWidth = 240.0;
const _railAnimDuration = Duration(milliseconds: 240);
const Curve _railAnimCurve = Curves.easeOutCubic;

/// Collapsible side rail: brand + collapse toggle, primary nav items with an
/// active left-accent bar, and a profile tile pinned at the bottom.
class _Sidebar extends StatefulWidget {
  const _Sidebar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _expanded = false;

  void _toggle() {
    unawaited(HapticFeedback.selectionClick());
    setState(() => _expanded = !_expanded);
  }

  void _select(int index) {
    unawaited(HapticFeedback.selectionClick());
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final destinations = _mainDestinations();
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return AnimatedContainer(
      duration: _railAnimDuration,
      curve: _railAnimCurve,
      width: _expanded ? _railExpandedWidth : _railCollapsedWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(
            color: colors.surfaceVariant.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrandRow(expanded: _expanded, onToggle: _toggle),
              const SizedBox(height: 24),
              for (var i = 0; i < destinations.length; i++)
                _RailItem(
                  spec: destinations[i],
                  expanded: _expanded,
                  isActive: widget.currentIndex == i,
                  onTap: () => _select(i),
                ),
              const Spacer(),
              _ProfileTile(
                expanded: _expanded,
                user: user,
                isActive: widget.currentIndex == HomeShell.profileIndex,
                onTap: () => _select(HomeShell.profileIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(width: 52, child: Center(child: _BrandMark(onTap: onToggle))),
          if (expanded)
            Expanded(
              child: Text(
                t.appName,
                style: context.textTheme.titleMedium?.copyWith(
                  color: colors.onBackground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              t.appName.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.spec,
    required this.expanded,
    required this.isActive,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool expanded;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = isActive ? colors.primary : colors.onBackgroundLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          if (isActive)
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Material(
            color: isActive
                ? colors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Center(
                        child: FaIcon(spec.icon, size: 17, color: foreground),
                      ),
                    ),
                    if (expanded)
                      Expanded(
                        child: Text(
                          spec.label,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: isActive
                                ? colors.onBackground
                                : colors.onBackgroundLight,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.expanded,
    required this.user,
    required this.isActive,
    required this.onTap,
  });

  final bool expanded;
  final AuthUser? user;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: isActive
            ? colors.primary.withValues(alpha: 0.10)
            : colors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _UserAvatar(user: user),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.name.isNotEmpty ?? false
                              ? user!.name
                              : t.nav.profile,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: colors.onBackground,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.nav.profile,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.onBackgroundLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 11,
                    color: colors.onBackgroundLight,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final photoUrl = user?.photoUrl;
    final initial = _initialOf(user?.name);
    return SizedBox(
      width: 36,
      height: 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: photoUrl != null && photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initialFallback(colors, initial),
              )
            : _initialFallback(colors, initial),
      ),
    );
  }

  Widget _initialFallback(AppColorsData colors, String initial) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.primaryLight.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static String _initialOf(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    return name.trim().substring(0, 1).toUpperCase();
  }
}
