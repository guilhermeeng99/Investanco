///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Investanco';
	@override late final _TranslationsCommonEn common = _TranslationsCommonEn._(_root);
	@override late final _TranslationsCurrenciesEn currencies = _TranslationsCurrenciesEn._(_root);
	@override late final _TranslationsNavEn nav = _TranslationsNavEn._(_root);
	@override late final _TranslationsDashboardEn dashboard = _TranslationsDashboardEn._(_root);
	@override late final _TranslationsInstitutionsEn institutions = _TranslationsInstitutionsEn._(_root);
	@override late final _TranslationsAssetsEn assets = _TranslationsAssetsEn._(_root);
	@override late final _TranslationsTransactionsEn transactions = _TranslationsTransactionsEn._(_root);
	@override late final _TranslationsImportCsvEn importCsv = _TranslationsImportCsvEn._(_root);
	@override late final _TranslationsProfileEn profile = _TranslationsProfileEn._(_root);
	@override late final _TranslationsStartupEn startup = _TranslationsStartupEn._(_root);
	@override late final _TranslationsOnboardingEn onboarding = _TranslationsOnboardingEn._(_root);
	@override late final _TranslationsAuthEn auth = _TranslationsAuthEn._(_root);
}

// Path: common
class _TranslationsCommonEn implements TranslationsCommonPt {
	_TranslationsCommonEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get save => 'Save';
	@override String get cancel => 'Cancel';
	@override String get delete => 'Delete';
	@override String get edit => 'Edit';
	@override String get add => 'Add';
	@override String get confirm => 'Confirm';
	@override String get ok => 'OK';
	@override String get required => 'Required field';
	@override String get retry => 'Try again';
}

// Path: currencies
class _TranslationsCurrenciesEn implements TranslationsCurrenciesPt {
	_TranslationsCurrenciesEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get brl => 'Real (BRL)';
	@override String get usd => 'Dollar (USD)';
}

// Path: nav
class _TranslationsNavEn implements TranslationsNavPt {
	_TranslationsNavEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get dashboard => 'Portfolio';
	@override String get assets => 'Assets';
	@override String get transactions => 'Transactions';
	@override String get profile => 'Profile';
}

// Path: dashboard
class _TranslationsDashboardEn implements TranslationsDashboardPt {
	_TranslationsDashboardEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Portfolio';
	@override String get empty => 'Add an institution, an asset and a transaction to start tracking your investments.';
	@override String get emptyTitle => 'Start your portfolio';
	@override String get addFirst => 'Add institution';
	@override String get loadError => 'We could not load your portfolio.';
	@override String get total => 'Total net worth';
	@override String get invested => 'Invested';
	@override String get profit => 'Profit/Loss';
	@override String get dayChange => 'Day change';
	@override String get allocation => 'Allocation by class';
	@override String get evolution => 'Net worth evolution';
	@override String get holdings => 'Positions';
	@override String get lastSync => 'Updated';
	@override String get never => 'never';
	@override String get refresh => 'Refresh';
	@override String get pricesStale => 'Quotes may be outdated';
}

// Path: institutions
class _TranslationsInstitutionsEn implements TranslationsInstitutionsPt {
	_TranslationsInstitutionsEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Institutions';
	@override String get empty => 'No institutions yet. Add Nubank, Avenue, etc.';
	@override String get add => 'New institution';
	@override String get edit => 'Edit institution';
	@override String get name => 'Name';
	@override String get kind => 'Type';
	@override String get currency => 'Currency';
	@override String get deleteConfirm => 'Delete this institution?';
	@override String get inUseError => 'Cannot delete: there are linked transactions.';
	@override String get saveError => 'Error while saving.';
	@override late final _TranslationsInstitutionsKindsEn kinds = _TranslationsInstitutionsKindsEn._(_root);
}

// Path: assets
class _TranslationsAssetsEn implements TranslationsAssetsPt {
	_TranslationsAssetsEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Assets';
	@override String get empty => 'No assets yet. Add PETR4, AAPL, Treasury bonds, etc.';
	@override String get add => 'New asset';
	@override String get edit => 'Edit asset';
	@override String get ticker => 'Ticker';
	@override String get name => 'Name';
	@override String get kind => 'Type';
	@override String get market => 'Market';
	@override String get currency => 'Currency';
	@override String get tesouroName => 'Tesouro Direto name';
	@override String get tesouroNameHelp => 'Exactly as on the site, e.g. Tesouro Selic 2027.';
	@override String get fixedIncomeBasis => 'Index';
	@override String get fixedIncomeRate => 'Contracted rate (%)';
	@override String get fixedIncomeRateHelp => 'CDI/Selic: % of the index. Prefixed: % p.a. IPCA+: spread % p.a.';
	@override late final _TranslationsAssetsBasisEn basis = _TranslationsAssetsBasisEn._(_root);
	@override String get deleteConfirm => 'Delete this asset?';
	@override String get inUseError => 'Cannot delete: there are linked transactions.';
	@override String get saveError => 'Error while saving.';
	@override late final _TranslationsAssetsKindsEn kinds = _TranslationsAssetsKindsEn._(_root);
	@override late final _TranslationsAssetsMarketsEn markets = _TranslationsAssetsMarketsEn._(_root);
}

// Path: transactions
class _TranslationsTransactionsEn implements TranslationsTransactionsPt {
	_TranslationsTransactionsEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Transactions';
	@override String get empty => 'No transactions yet. Record buys, sells and dividends.';
	@override String get add => 'New transaction';
	@override String get edit => 'Edit transaction';
	@override String get institution => 'Institution';
	@override String get asset => 'Asset';
	@override String get kind => 'Type';
	@override String get quantity => 'Quantity';
	@override String get unitPrice => 'Unit price';
	@override String get fees => 'Fees';
	@override String get amount => 'Total amount';
	@override String get date => 'Date';
	@override String get notes => 'Notes';
	@override String get deleteConfirm => 'Delete this transaction?';
	@override String get saveError => 'Error while saving.';
	@override String get needPrereqs => 'Add an institution and an asset first.';
	@override late final _TranslationsTransactionsKindsEn kinds = _TranslationsTransactionsKindsEn._(_root);
}

// Path: importCsv
class _TranslationsImportCsvEn implements TranslationsImportCsvPt {
	_TranslationsImportCsvEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Import CSV';
	@override String get intro => 'Bulk-add your portfolio from a spreadsheet. Each row is one position: ticker, type, institution, quantity and average price. Existing assets and institutions are reused; new ones are created automatically.';
	@override String get downloadExample => 'Download example';
	@override String get selectFile => 'Select file';
	@override String get confirmTitle => 'Confirm import';
	@override String confirmBody({required Object count}) => 'Import ${count} rows? Existing assets and institutions are reused, so re-importing won\'t duplicate them.';
	@override String success({required Object assets, required Object transactions}) => 'Imported ${assets} new assets and ${transactions} transactions.';
	@override String get exampleDownloaded => 'Example CSV downloaded.';
	@override String get exampleFailed => 'Could not generate the example file.';
	@override String get errorTitle => 'Could not import';
}

// Path: profile
class _TranslationsProfileEn implements TranslationsProfilePt {
	_TranslationsProfileEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Profile';
	@override String get sectionYourData => 'Your data';
	@override String get sectionPreferences => 'Preferences';
	@override String get sectionAccount => 'Account';
	@override String get sectionGetTheApp => 'Get the app';
	@override String get sectionDangerZone => 'Danger zone';
	@override String get theme => 'Theme';
	@override String get themeSystem => 'System';
	@override String get themeLight => 'Light';
	@override String get themeDark => 'Dark';
	@override String get lightPalette => 'Light palette';
	@override String get darkPalette => 'Dark palette';
	@override String get language => 'Language';
	@override String get languageSystem => 'System';
	@override String get languagePt => 'Portuguese';
	@override String get languageEn => 'English';
	@override String get baseCurrency => 'Base currency';
	@override String get downloadApk => 'Download for Android';
	@override String get downloadApkDescription => 'Install the APK on your Android phone.';
	@override String get signOut => 'Sign out';
	@override String get signOutConfirm => 'Are you sure you want to sign out?';
	@override String get clearData => 'Clear my data';
	@override String get clearDataDescription => 'Removes all your data, in the cloud and on this device.';
	@override String get clearDataConfirmHeadline => 'This action is permanent';
	@override String get clearDataConfirmBody => 'All your institutions, assets and transactions will be permanently erased — in the cloud and on this device. This cannot be undone.';
	@override String get clearDataConfirmField => 'Type your email to confirm';
	@override String get clearDataSuccess => 'Your data has been cleared.';
	@override String get version => 'Version';
}

// Path: startup
class _TranslationsStartupEn implements TranslationsStartupPt {
	_TranslationsStartupEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Your portfolio, always up to date';
	@override String get stepCheckingAuth => 'Checking your account...';
	@override String get stepSyncingData => 'Syncing your data...';
	@override String get stepReady => 'All set';
	@override String get errorTitle => 'Something went wrong';
	@override String get errorRetry => 'Try again';
}

// Path: onboarding
class _TranslationsOnboardingEn implements TranslationsOnboardingPt {
	_TranslationsOnboardingEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Skip';
	@override String get next => 'Next';
	@override String get step1Title => 'Your whole portfolio in one place';
	@override String get step1Body => 'Consolidate your holdings from Nubank, Avenue and other institutions — you only register what you own.';
	@override String get step2Title => 'Automatic quotes';
	@override String get step2Body => 'Prices, FX and indices update on their own from public APIs. No broker login, no spreadsheet.';
	@override String get step3Title => 'Track your performance';
	@override String get step3Body => 'See net worth, profit/loss and allocation by class, in real time and in your currency.';
}

// Path: auth
class _TranslationsAuthEn implements TranslationsAuthPt {
	_TranslationsAuthEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get continueWithGoogle => 'Continue with Google';
	@override String get signInSubtitle => 'Sign in to start tracking your investments.';
	@override String get signInError => 'Could not sign in. Please try again.';
}

// Path: institutions.kinds
class _TranslationsInstitutionsKindsEn implements TranslationsInstitutionsKindsPt {
	_TranslationsInstitutionsKindsEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get bank => 'Bank';
	@override String get broker => 'Brokerage';
	@override String get internationalBroker => 'International brokerage';
	@override String get crypto => 'Crypto';
	@override String get other => 'Other';
}

// Path: assets.basis
class _TranslationsAssetsBasisEn implements TranslationsAssetsBasisPt {
	_TranslationsAssetsBasisEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get cdi => 'CDI';
	@override String get selic => 'Selic';
	@override String get prefixed => 'Prefixed';
	@override String get ipca => 'IPCA+';
}

// Path: assets.kinds
class _TranslationsAssetsKindsEn implements TranslationsAssetsKindsPt {
	_TranslationsAssetsKindsEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get stockBr => 'Stock (BR)';
	@override String get fiiBr => 'REIT (FII)';
	@override String get etfBr => 'ETF (BR)';
	@override String get bdrBr => 'BDR';
	@override String get stockUs => 'Stock (US)';
	@override String get etfUs => 'ETF (US)';
	@override String get crypto => 'Crypto';
	@override String get treasury => 'Treasury bonds';
	@override String get fixedIncome => 'Fixed income';
	@override String get fund => 'Fund';
	@override String get cash => 'Cash';
}

// Path: assets.markets
class _TranslationsAssetsMarketsEn implements TranslationsAssetsMarketsPt {
	_TranslationsAssetsMarketsEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get br => 'Brazil';
	@override String get us => 'US';
	@override String get global => 'Global';
}

// Path: transactions.kinds
class _TranslationsTransactionsKindsEn implements TranslationsTransactionsKindsPt {
	_TranslationsTransactionsKindsEn._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get buy => 'Buy';
	@override String get sell => 'Sell';
	@override String get dividend => 'Dividend';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Investanco',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.delete' => 'Delete',
			'common.edit' => 'Edit',
			'common.add' => 'Add',
			'common.confirm' => 'Confirm',
			'common.ok' => 'OK',
			'common.required' => 'Required field',
			'common.retry' => 'Try again',
			'currencies.brl' => 'Real (BRL)',
			'currencies.usd' => 'Dollar (USD)',
			'nav.dashboard' => 'Portfolio',
			'nav.assets' => 'Assets',
			'nav.transactions' => 'Transactions',
			'nav.profile' => 'Profile',
			'dashboard.title' => 'Portfolio',
			'dashboard.empty' => 'Add an institution, an asset and a transaction to start tracking your investments.',
			'dashboard.emptyTitle' => 'Start your portfolio',
			'dashboard.addFirst' => 'Add institution',
			'dashboard.loadError' => 'We could not load your portfolio.',
			'dashboard.total' => 'Total net worth',
			'dashboard.invested' => 'Invested',
			'dashboard.profit' => 'Profit/Loss',
			'dashboard.dayChange' => 'Day change',
			'dashboard.allocation' => 'Allocation by class',
			'dashboard.evolution' => 'Net worth evolution',
			'dashboard.holdings' => 'Positions',
			'dashboard.lastSync' => 'Updated',
			'dashboard.never' => 'never',
			'dashboard.refresh' => 'Refresh',
			'dashboard.pricesStale' => 'Quotes may be outdated',
			'institutions.title' => 'Institutions',
			'institutions.empty' => 'No institutions yet. Add Nubank, Avenue, etc.',
			'institutions.add' => 'New institution',
			'institutions.edit' => 'Edit institution',
			'institutions.name' => 'Name',
			'institutions.kind' => 'Type',
			'institutions.currency' => 'Currency',
			'institutions.deleteConfirm' => 'Delete this institution?',
			'institutions.inUseError' => 'Cannot delete: there are linked transactions.',
			'institutions.saveError' => 'Error while saving.',
			'institutions.kinds.bank' => 'Bank',
			'institutions.kinds.broker' => 'Brokerage',
			'institutions.kinds.internationalBroker' => 'International brokerage',
			'institutions.kinds.crypto' => 'Crypto',
			'institutions.kinds.other' => 'Other',
			'assets.title' => 'Assets',
			'assets.empty' => 'No assets yet. Add PETR4, AAPL, Treasury bonds, etc.',
			'assets.add' => 'New asset',
			'assets.edit' => 'Edit asset',
			'assets.ticker' => 'Ticker',
			'assets.name' => 'Name',
			'assets.kind' => 'Type',
			'assets.market' => 'Market',
			'assets.currency' => 'Currency',
			'assets.tesouroName' => 'Tesouro Direto name',
			'assets.tesouroNameHelp' => 'Exactly as on the site, e.g. Tesouro Selic 2027.',
			'assets.fixedIncomeBasis' => 'Index',
			'assets.fixedIncomeRate' => 'Contracted rate (%)',
			'assets.fixedIncomeRateHelp' => 'CDI/Selic: % of the index. Prefixed: % p.a. IPCA+: spread % p.a.',
			'assets.basis.cdi' => 'CDI',
			'assets.basis.selic' => 'Selic',
			'assets.basis.prefixed' => 'Prefixed',
			'assets.basis.ipca' => 'IPCA+',
			'assets.deleteConfirm' => 'Delete this asset?',
			'assets.inUseError' => 'Cannot delete: there are linked transactions.',
			'assets.saveError' => 'Error while saving.',
			'assets.kinds.stockBr' => 'Stock (BR)',
			'assets.kinds.fiiBr' => 'REIT (FII)',
			'assets.kinds.etfBr' => 'ETF (BR)',
			'assets.kinds.bdrBr' => 'BDR',
			'assets.kinds.stockUs' => 'Stock (US)',
			'assets.kinds.etfUs' => 'ETF (US)',
			'assets.kinds.crypto' => 'Crypto',
			'assets.kinds.treasury' => 'Treasury bonds',
			'assets.kinds.fixedIncome' => 'Fixed income',
			'assets.kinds.fund' => 'Fund',
			'assets.kinds.cash' => 'Cash',
			'assets.markets.br' => 'Brazil',
			'assets.markets.us' => 'US',
			'assets.markets.global' => 'Global',
			'transactions.title' => 'Transactions',
			'transactions.empty' => 'No transactions yet. Record buys, sells and dividends.',
			'transactions.add' => 'New transaction',
			'transactions.edit' => 'Edit transaction',
			'transactions.institution' => 'Institution',
			'transactions.asset' => 'Asset',
			'transactions.kind' => 'Type',
			'transactions.quantity' => 'Quantity',
			'transactions.unitPrice' => 'Unit price',
			'transactions.fees' => 'Fees',
			'transactions.amount' => 'Total amount',
			'transactions.date' => 'Date',
			'transactions.notes' => 'Notes',
			'transactions.deleteConfirm' => 'Delete this transaction?',
			'transactions.saveError' => 'Error while saving.',
			'transactions.needPrereqs' => 'Add an institution and an asset first.',
			'transactions.kinds.buy' => 'Buy',
			'transactions.kinds.sell' => 'Sell',
			'transactions.kinds.dividend' => 'Dividend',
			'importCsv.title' => 'Import CSV',
			'importCsv.intro' => 'Bulk-add your portfolio from a spreadsheet. Each row is one position: ticker, type, institution, quantity and average price. Existing assets and institutions are reused; new ones are created automatically.',
			'importCsv.downloadExample' => 'Download example',
			'importCsv.selectFile' => 'Select file',
			'importCsv.confirmTitle' => 'Confirm import',
			'importCsv.confirmBody' => ({required Object count}) => 'Import ${count} rows? Existing assets and institutions are reused, so re-importing won\'t duplicate them.',
			'importCsv.success' => ({required Object assets, required Object transactions}) => 'Imported ${assets} new assets and ${transactions} transactions.',
			'importCsv.exampleDownloaded' => 'Example CSV downloaded.',
			'importCsv.exampleFailed' => 'Could not generate the example file.',
			'importCsv.errorTitle' => 'Could not import',
			'profile.title' => 'Profile',
			'profile.sectionYourData' => 'Your data',
			'profile.sectionPreferences' => 'Preferences',
			'profile.sectionAccount' => 'Account',
			'profile.sectionGetTheApp' => 'Get the app',
			'profile.sectionDangerZone' => 'Danger zone',
			'profile.theme' => 'Theme',
			'profile.themeSystem' => 'System',
			'profile.themeLight' => 'Light',
			'profile.themeDark' => 'Dark',
			'profile.lightPalette' => 'Light palette',
			'profile.darkPalette' => 'Dark palette',
			'profile.language' => 'Language',
			'profile.languageSystem' => 'System',
			'profile.languagePt' => 'Portuguese',
			'profile.languageEn' => 'English',
			'profile.baseCurrency' => 'Base currency',
			'profile.downloadApk' => 'Download for Android',
			'profile.downloadApkDescription' => 'Install the APK on your Android phone.',
			'profile.signOut' => 'Sign out',
			'profile.signOutConfirm' => 'Are you sure you want to sign out?',
			'profile.clearData' => 'Clear my data',
			'profile.clearDataDescription' => 'Removes all your data, in the cloud and on this device.',
			'profile.clearDataConfirmHeadline' => 'This action is permanent',
			'profile.clearDataConfirmBody' => 'All your institutions, assets and transactions will be permanently erased — in the cloud and on this device. This cannot be undone.',
			'profile.clearDataConfirmField' => 'Type your email to confirm',
			'profile.clearDataSuccess' => 'Your data has been cleared.',
			'profile.version' => 'Version',
			'startup.tagline' => 'Your portfolio, always up to date',
			'startup.stepCheckingAuth' => 'Checking your account...',
			'startup.stepSyncingData' => 'Syncing your data...',
			'startup.stepReady' => 'All set',
			'startup.errorTitle' => 'Something went wrong',
			'startup.errorRetry' => 'Try again',
			'onboarding.skip' => 'Skip',
			'onboarding.next' => 'Next',
			'onboarding.step1Title' => 'Your whole portfolio in one place',
			'onboarding.step1Body' => 'Consolidate your holdings from Nubank, Avenue and other institutions — you only register what you own.',
			'onboarding.step2Title' => 'Automatic quotes',
			'onboarding.step2Body' => 'Prices, FX and indices update on their own from public APIs. No broker login, no spreadsheet.',
			'onboarding.step3Title' => 'Track your performance',
			'onboarding.step3Body' => 'See net worth, profit/loss and allocation by class, in real time and in your currency.',
			'auth.continueWithGoogle' => 'Continue with Google',
			'auth.signInSubtitle' => 'Sign in to start tracking your investments.',
			'auth.signInError' => 'Could not sign in. Please try again.',
			_ => null,
		};
	}
}
