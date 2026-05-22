import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/assets/presentation/pages/assets_page.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/transactions/presentation/pages/transactions_page.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// The two sub-views hosted by the unified records tab.
enum RecordsTab { assets, transactions }

/// Maps the `tab` deep-link query value to a [RecordsTab]; an absent or unknown
/// value falls back to [RecordsTab.assets] (the default sub-view).
///
/// Example: `recordsTabFromQuery('transactions') == RecordsTab.transactions`.
RecordsTab recordsTabFromQuery(String? value) =>
    value == 'transactions' ? RecordsTab.transactions : RecordsTab.assets;

/// Unified "Registros" tab: hosts the Assets and Transactions views in a
/// swipeable [PageView] with a segmented toggle, replacing the two former primary
/// tabs. The FAB swaps to the active view's add/import stack. See
/// `docs/specs/records.md`.
class RecordsPage extends StatefulWidget {
  /// Creates the page, optionally landing on [initialTab] (e.g. a dashboard CTA
  /// deep-links to the transactions sub-view).
  const RecordsPage({this.initialTab = RecordsTab.assets, super.key});

  /// Route path.
  static const String routePath = '/records';

  /// Route name.
  static const String routeName = 'records';

  /// The sub-view shown first.
  final RecordsTab initialTab;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late final PageController _controller =
      PageController(initialPage: widget.initialTab.index);
  late RecordsTab _current = widget.initialTab;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggle tap: highlight + swap FAB immediately, then animate the page.
  void _select(RecordsTab tab) {
    if (tab == _current) return;
    setState(() => _current = tab);
    unawaited(
      _controller.animateToPage(
        tab.index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _onPageChanged(int index) =>
      setState(() => _current = RecordsTab.values[index]);

  @override
  Widget build(BuildContext context) {
    // Both cubits live above the Scaffold so the body and the FAB share each
    // scope (the FAB sits in `Scaffold.floatingActionButton`, a sibling subtree).
    return MultiBlocProvider(
      providers: [
        BlocProvider<AssetsCubit>(create: (_) => sl<AssetsCubit>()),
        BlocProvider<TransactionsCubit>(create: (_) => sl<TransactionsCubit>()),
      ],
      child: Scaffold(
        appBar: InvestancoAppBar(title: t.nav.records),
        floatingActionButton: _current == RecordsTab.assets
            ? const AssetsFab()
            : const TransactionsFab(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: InvestancoPillToggle<RecordsTab>(
                selected: _current,
                onChanged: _select,
                options: [
                  InvestancoPillToggleOption(
                    value: RecordsTab.assets,
                    label: t.assets.title,
                    icon: FontAwesomeIcons.coins,
                  ),
                  InvestancoPillToggleOption(
                    value: RecordsTab.transactions,
                    label: t.transactions.title,
                    icon: FontAwesomeIcons.rightLeft,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: const [AssetsView(), TransactionsView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
