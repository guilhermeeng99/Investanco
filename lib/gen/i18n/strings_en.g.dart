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
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$errors$en errors = _Translations$errors$en._(_root);
	@override late final _Translations$currencies$en currencies = _Translations$currencies$en._(_root);
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
	@override late final _Translations$allocation$en allocation = _Translations$allocation$en._(_root);
	@override late final _Translations$dashboard$en dashboard = _Translations$dashboard$en._(_root);
	@override late final _Translations$institutions$en institutions = _Translations$institutions$en._(_root);
	@override late final _Translations$assets$en assets = _Translations$assets$en._(_root);
	@override late final _Translations$transactions$en transactions = _Translations$transactions$en._(_root);
	@override late final _Translations$importCsv$en importCsv = _Translations$importCsv$en._(_root);
	@override late final _Translations$importAssets$en importAssets = _Translations$importAssets$en._(_root);
	@override late final _Translations$importTransactions$en importTransactions = _Translations$importTransactions$en._(_root);
	@override late final _Translations$profile$en profile = _Translations$profile$en._(_root);
	@override late final _Translations$startup$en startup = _Translations$startup$en._(_root);
	@override late final _Translations$onboarding$en onboarding = _Translations$onboarding$en._(_root);
	@override late final _Translations$auth$en auth = _Translations$auth$en._(_root);
}

// Path: common
class _Translations$common$en implements Translations$common$pt {
	_Translations$common$en._(this._root);

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

// Path: errors
class _Translations$errors$en implements Translations$errors$pt {
	_Translations$errors$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get network => 'No internet connection.';
	@override String get server => 'Server error. Please try again.';
	@override String get storage => 'Could not access local data.';
	@override String get unexpected => 'Something went wrong. Please try again.';
	@override String get invalid => 'Invalid data.';
	@override String get inUse => 'Record is in use.';
	@override String get notFound => 'Record not found.';
}

// Path: currencies
class _Translations$currencies$en implements Translations$currencies$pt {
	_Translations$currencies$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get brl => 'Real (BRL)';
	@override String get usd => 'Dollar (USD)';
}

// Path: nav
class _Translations$nav$en implements Translations$nav$pt {
	_Translations$nav$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get dashboard => 'Portfolio';
	@override String get assets => 'Assets';
	@override String get transactions => 'Transactions';
	@override String get allocation => 'Investments';
	@override String get records => 'Records';
	@override String get profile => 'Profile';
}

// Path: allocation
class _Translations$allocation$en implements Translations$allocation$pt {
	_Translations$allocation$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heroTitle => 'INVESTED NET WORTH';
	@override String get loadError => 'Could not load the allocation.';
	@override String get refresh => 'Refresh';
	@override String get sectionClasses => 'Classes';
	@override String get sectionRebalance => 'Rebalancing';
	@override String classRowSubtitle({required Object actual, required Object target}) => '${actual} of ${target}';
	@override String get classRowOnTarget => 'on target';
	@override String classRowUnderTarget({required Object amount}) => '${amount} below';
	@override String classRowOverTarget({required Object amount}) => '${amount} above';
	@override String rebalanceAllocatePending({required Object amount}) => 'Allocate ${amount} unassigned';
	@override String rebalanceBuy({required Object amount, required Object className}) => 'Add ${amount} to ${className}';
	@override String rebalanceSell({required Object amount, required Object className}) => 'Trim ${amount} from ${className}';
	@override String get rebalanceBalanced => 'Your portfolio is on target.';
	@override String targetsBanner({required Object percent}) => 'Targets sum to ${percent}% — adjust to 100%.';
	@override String get noClassesHint => 'Create classes and set targets to track your allocation.';
	@override String get emptyTitle => 'Set up your allocation';
	@override String get emptyMessage => 'Create classes (e.g. US Equities, Fixed Income), set each one\'s target %, and assign your assets so the app can help you rebalance.';
	@override String get emptyAction => 'Create class';
	@override String get saveError => 'Could not save.';
	@override String get targetSumError => 'The class targets add up to more than 100%.';
	@override String get classNameLabel => 'Name';
	@override String get classNameHint => 'e.g. US Equities';
	@override String get targetPercentLabel => 'Target %';
	@override String get targetHelper => 'How much of your net worth you want in this class.';
	@override String get classIcon => 'Icon';
	@override String get classColor => 'Color';
	@override String get newClassTitle => 'New class';
	@override String get editClassTitle => 'Edit class';
	@override String get deleteClassTitle => 'Delete class';
	@override String get deleteClassConfirm => 'The class will be removed. Linked assets become unassigned.';
	@override String get classDetailTitle => 'Class';
	@override String get detailAssets => 'Assets';
	@override String get detailNoAssets => 'No assets in this class. Add an asset and set its target %.';
	@override String detailTargetAmount({required Object amount}) => 'Target: ${amount}';
	@override String get addAsset => 'Add asset';
	@override String subclassDetailLine({required Object amount, required Object percent}) => '${amount} · ${percent} of class';
	@override String subclassDetailLineTarget({required Object amount, required Object actual, required Object target}) => '${amount} · ${actual} of ${target}';
	@override String subclassSuggestionAdd({required Object amount}) => 'Add ${amount} to reach the target';
	@override String subclassSuggestionTrim({required Object amount}) => 'Trim ${amount} — above target';
	@override String get subclassSuggestionBalanced => 'On suggested target';
	@override String get subclassSuggestionNoTarget => 'Set a target % to see the suggestion';
}

// Path: dashboard
class _Translations$dashboard$en implements Translations$dashboard$pt {
	_Translations$dashboard$en._(this._root);

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
	@override String get holdings => 'Positions';
	@override String get lastSync => 'Updated';
	@override String get never => 'never';
	@override String get refresh => 'Refresh';
	@override String get pricesStale => 'Quotes may be outdated';
	@override String get filterAll => 'All';
	@override String get noPositionsForFilter => 'No positions for this institution.';
	@override String get inForeign => 'In USD';
}

// Path: institutions
class _Translations$institutions$en implements Translations$institutions$pt {
	_Translations$institutions$en._(this._root);

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
	@override String get duplicateName => 'An institution with this name already exists.';
	@override late final _Translations$institutions$kinds$en kinds = _Translations$institutions$kinds$en._(_root);
}

// Path: assets
class _Translations$assets$en implements Translations$assets$pt {
	_Translations$assets$en._(this._root);

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
	@override late final _Translations$assets$basis$en basis = _Translations$assets$basis$en._(_root);
	@override String get deleteConfirm => 'Delete this asset?';
	@override String get inUseError => 'Cannot delete: there are linked transactions.';
	@override String get saveError => 'Error while saving.';
	@override String get duplicateAsset => 'An asset with this ticker already exists in this market.';
	@override String get allocationClass => 'Allocation class';
	@override String get allocationClassPlaceholder => 'Select the class';
	@override String get allocationNoClasses => 'Create a class first';
	@override String get allocationClassRequired => 'Select the allocation class';
	@override String get allocationTarget => 'Target % in class';
	@override String get allocationTargetHelp => 'How much this asset should be within the class.';
	@override String get allocationTargetRequired => 'Enter a target % above 0';
	@override String get allocationUnassigned => 'No class';
	@override late final _Translations$assets$kinds$en kinds = _Translations$assets$kinds$en._(_root);
	@override late final _Translations$assets$markets$en markets = _Translations$assets$markets$en._(_root);
}

// Path: transactions
class _Translations$transactions$en implements Translations$transactions$pt {
	_Translations$transactions$en._(this._root);

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
	@override String get futureDateError => 'A transaction can\'t be dated in the future.';
	@override String get oversellError => 'This sell exceeds the quantity held on that date.';
	@override String get quantityError => 'Quantity must be greater than zero.';
	@override String get needPrereqs => 'Add an institution and an asset first.';
	@override String get filterAll => 'All';
	@override String get noFilterResults => 'No transactions for this institution.';
	@override late final _Translations$transactions$kinds$en kinds = _Translations$transactions$kinds$en._(_root);
}

// Path: importCsv
class _Translations$importCsv$en implements Translations$importCsv$pt {
	_Translations$importCsv$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get downloadExample => 'Download example';
	@override String get selectFile => 'Select file';
	@override String get exampleDownloaded => 'Example CSV downloaded.';
	@override String get exampleFailed => 'Could not generate the example file.';
	@override String get errorTitle => 'Could not import';
	@override String get fileError => 'Couldn\'t read the selected file. Make sure it\'s a valid CSV.';
	@override String get genericError => 'Something went wrong. Please try again.';
	@override String get fileInvalid => 'Invalid file. Check the format and try again.';
	@override String rowError({required Object line}) => 'Row ${line} of the file is invalid. Fix it and try again.';
	@override String get previewItemsHeader => 'Items';
	@override String previewReusedCount({required Object count}) => '+${count} reused';
	@override String get previewBadgeNew => 'New';
	@override String get previewNothingLeft => 'Nothing to import';
	@override String get previewEmptyTitle => 'Nothing left';
	@override String get previewEmpty => 'You removed every row. Go back to pick another file.';
	@override String get previewImporting => 'Importing…';
	@override String get previewRemoveRow => 'Remove';
}

// Path: importAssets
class _Translations$importAssets$en implements Translations$importAssets$pt {
	_Translations$importAssets$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Import assets';
	@override String get intro => 'Bulk-add your assets from a spreadsheet. One row per asset: ticker, name, type, market, currency. Existing assets (matched by ticker) are reused.';
	@override String get previewTitle => 'Review assets';
	@override String get previewSubtitle => 'Check what will be added before importing';
	@override String get statNew => 'New assets';
	@override String get reuseNote => 'Assets already in your portfolio (matched by ticker) are reused — re-importing won\'t duplicate them.';
	@override String submit({required Object count}) => 'Import ${count} assets';
	@override String success({required Object count}) => 'Imported ${count} new assets.';
}

// Path: importTransactions
class _Translations$importTransactions$en implements Translations$importTransactions$pt {
	_Translations$importTransactions$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Import transactions';
	@override String get intro => 'Bulk-add transactions from a spreadsheet. One row per movement: ticker, institution, operation, quantity, price, date. The referenced assets must already exist; missing institutions are created automatically.';
	@override String get previewTitle => 'Review transactions';
	@override String get previewSubtitle => 'Check what will be added before importing';
	@override String get statTransactions => 'Transactions';
	@override String get statNewInstitutions => 'New institutions';
	@override String get reuseNote => 'Missing institutions are created automatically; existing ones (matched by name) are reused.';
	@override String submit({required Object count}) => 'Import ${count} transactions';
	@override String success({required Object count}) => 'Imported ${count} transactions.';
	@override String get missingTitle => 'Assets not found';
	@override String missingBody({required Object tickers}) => 'These tickers aren\'t registered yet — import them on the Assets tab first: ${tickers}';
}

// Path: profile
class _Translations$profile$en implements Translations$profile$pt {
	_Translations$profile$en._(this._root);

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
	@override String get clearDataError => 'Couldn\'t clear your data. Please try again.';
	@override String get version => 'Version';
}

// Path: startup
class _Translations$startup$en implements Translations$startup$pt {
	_Translations$startup$en._(this._root);

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
class _Translations$onboarding$en implements Translations$onboarding$pt {
	_Translations$onboarding$en._(this._root);

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
class _Translations$auth$en implements Translations$auth$pt {
	_Translations$auth$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get continueWithGoogle => 'Continue with Google';
	@override String get signInSubtitle => 'Sign in to start tracking your investments.';
	@override String get signInError => 'Could not sign in. Please try again.';
	@override String get unauthorizedAccount => 'This account isn\'t authorized to use this app.';
}

// Path: institutions.kinds
class _Translations$institutions$kinds$en implements Translations$institutions$kinds$pt {
	_Translations$institutions$kinds$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get bank => 'Bank';
	@override String get broker => 'Brokerage';
	@override String get internationalBroker => 'International brokerage';
	@override String get crypto => 'Crypto';
	@override String get other => 'Other';
}

// Path: assets.basis
class _Translations$assets$basis$en implements Translations$assets$basis$pt {
	_Translations$assets$basis$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get cdi => 'CDI';
	@override String get selic => 'Selic';
	@override String get prefixed => 'Prefixed';
	@override String get ipca => 'IPCA+';
}

// Path: assets.kinds
class _Translations$assets$kinds$en implements Translations$assets$kinds$pt {
	_Translations$assets$kinds$en._(this._root);

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
class _Translations$assets$markets$en implements Translations$assets$markets$pt {
	_Translations$assets$markets$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get br => 'Brazil';
	@override String get us => 'US';
	@override String get global => 'Global';
}

// Path: transactions.kinds
class _Translations$transactions$kinds$en implements Translations$transactions$kinds$pt {
	_Translations$transactions$kinds$en._(this._root);

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
			'errors.network' => 'No internet connection.',
			'errors.server' => 'Server error. Please try again.',
			'errors.storage' => 'Could not access local data.',
			'errors.unexpected' => 'Something went wrong. Please try again.',
			'errors.invalid' => 'Invalid data.',
			'errors.inUse' => 'Record is in use.',
			'errors.notFound' => 'Record not found.',
			'currencies.brl' => 'Real (BRL)',
			'currencies.usd' => 'Dollar (USD)',
			'nav.dashboard' => 'Portfolio',
			'nav.assets' => 'Assets',
			'nav.transactions' => 'Transactions',
			'nav.allocation' => 'Investments',
			'nav.records' => 'Records',
			'nav.profile' => 'Profile',
			'allocation.heroTitle' => 'INVESTED NET WORTH',
			'allocation.loadError' => 'Could not load the allocation.',
			'allocation.refresh' => 'Refresh',
			'allocation.sectionClasses' => 'Classes',
			'allocation.sectionRebalance' => 'Rebalancing',
			'allocation.classRowSubtitle' => ({required Object actual, required Object target}) => '${actual} of ${target}',
			'allocation.classRowOnTarget' => 'on target',
			'allocation.classRowUnderTarget' => ({required Object amount}) => '${amount} below',
			'allocation.classRowOverTarget' => ({required Object amount}) => '${amount} above',
			'allocation.rebalanceAllocatePending' => ({required Object amount}) => 'Allocate ${amount} unassigned',
			'allocation.rebalanceBuy' => ({required Object amount, required Object className}) => 'Add ${amount} to ${className}',
			'allocation.rebalanceSell' => ({required Object amount, required Object className}) => 'Trim ${amount} from ${className}',
			'allocation.rebalanceBalanced' => 'Your portfolio is on target.',
			'allocation.targetsBanner' => ({required Object percent}) => 'Targets sum to ${percent}% — adjust to 100%.',
			'allocation.noClassesHint' => 'Create classes and set targets to track your allocation.',
			'allocation.emptyTitle' => 'Set up your allocation',
			'allocation.emptyMessage' => 'Create classes (e.g. US Equities, Fixed Income), set each one\'s target %, and assign your assets so the app can help you rebalance.',
			'allocation.emptyAction' => 'Create class',
			'allocation.saveError' => 'Could not save.',
			'allocation.targetSumError' => 'The class targets add up to more than 100%.',
			'allocation.classNameLabel' => 'Name',
			'allocation.classNameHint' => 'e.g. US Equities',
			'allocation.targetPercentLabel' => 'Target %',
			'allocation.targetHelper' => 'How much of your net worth you want in this class.',
			'allocation.classIcon' => 'Icon',
			'allocation.classColor' => 'Color',
			'allocation.newClassTitle' => 'New class',
			'allocation.editClassTitle' => 'Edit class',
			'allocation.deleteClassTitle' => 'Delete class',
			'allocation.deleteClassConfirm' => 'The class will be removed. Linked assets become unassigned.',
			'allocation.classDetailTitle' => 'Class',
			'allocation.detailAssets' => 'Assets',
			'allocation.detailNoAssets' => 'No assets in this class. Add an asset and set its target %.',
			'allocation.detailTargetAmount' => ({required Object amount}) => 'Target: ${amount}',
			'allocation.addAsset' => 'Add asset',
			'allocation.subclassDetailLine' => ({required Object amount, required Object percent}) => '${amount} · ${percent} of class',
			'allocation.subclassDetailLineTarget' => ({required Object amount, required Object actual, required Object target}) => '${amount} · ${actual} of ${target}',
			'allocation.subclassSuggestionAdd' => ({required Object amount}) => 'Add ${amount} to reach the target',
			'allocation.subclassSuggestionTrim' => ({required Object amount}) => 'Trim ${amount} — above target',
			'allocation.subclassSuggestionBalanced' => 'On suggested target',
			'allocation.subclassSuggestionNoTarget' => 'Set a target % to see the suggestion',
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
			'dashboard.holdings' => 'Positions',
			'dashboard.lastSync' => 'Updated',
			'dashboard.never' => 'never',
			'dashboard.refresh' => 'Refresh',
			'dashboard.pricesStale' => 'Quotes may be outdated',
			'dashboard.filterAll' => 'All',
			'dashboard.noPositionsForFilter' => 'No positions for this institution.',
			'dashboard.inForeign' => 'In USD',
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
			'institutions.duplicateName' => 'An institution with this name already exists.',
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
			'assets.duplicateAsset' => 'An asset with this ticker already exists in this market.',
			'assets.allocationClass' => 'Allocation class',
			'assets.allocationClassPlaceholder' => 'Select the class',
			'assets.allocationNoClasses' => 'Create a class first',
			'assets.allocationClassRequired' => 'Select the allocation class',
			'assets.allocationTarget' => 'Target % in class',
			'assets.allocationTargetHelp' => 'How much this asset should be within the class.',
			'assets.allocationTargetRequired' => 'Enter a target % above 0',
			'assets.allocationUnassigned' => 'No class',
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
			'transactions.futureDateError' => 'A transaction can\'t be dated in the future.',
			'transactions.oversellError' => 'This sell exceeds the quantity held on that date.',
			'transactions.quantityError' => 'Quantity must be greater than zero.',
			'transactions.needPrereqs' => 'Add an institution and an asset first.',
			'transactions.filterAll' => 'All',
			'transactions.noFilterResults' => 'No transactions for this institution.',
			'transactions.kinds.buy' => 'Buy',
			'transactions.kinds.sell' => 'Sell',
			'transactions.kinds.dividend' => 'Dividend',
			'importCsv.downloadExample' => 'Download example',
			'importCsv.selectFile' => 'Select file',
			'importCsv.exampleDownloaded' => 'Example CSV downloaded.',
			'importCsv.exampleFailed' => 'Could not generate the example file.',
			'importCsv.errorTitle' => 'Could not import',
			'importCsv.fileError' => 'Couldn\'t read the selected file. Make sure it\'s a valid CSV.',
			'importCsv.genericError' => 'Something went wrong. Please try again.',
			'importCsv.fileInvalid' => 'Invalid file. Check the format and try again.',
			'importCsv.rowError' => ({required Object line}) => 'Row ${line} of the file is invalid. Fix it and try again.',
			'importCsv.previewItemsHeader' => 'Items',
			'importCsv.previewReusedCount' => ({required Object count}) => '+${count} reused',
			'importCsv.previewBadgeNew' => 'New',
			'importCsv.previewNothingLeft' => 'Nothing to import',
			'importCsv.previewEmptyTitle' => 'Nothing left',
			'importCsv.previewEmpty' => 'You removed every row. Go back to pick another file.',
			'importCsv.previewImporting' => 'Importing…',
			'importCsv.previewRemoveRow' => 'Remove',
			'importAssets.title' => 'Import assets',
			'importAssets.intro' => 'Bulk-add your assets from a spreadsheet. One row per asset: ticker, name, type, market, currency. Existing assets (matched by ticker) are reused.',
			'importAssets.previewTitle' => 'Review assets',
			'importAssets.previewSubtitle' => 'Check what will be added before importing',
			'importAssets.statNew' => 'New assets',
			'importAssets.reuseNote' => 'Assets already in your portfolio (matched by ticker) are reused — re-importing won\'t duplicate them.',
			'importAssets.submit' => ({required Object count}) => 'Import ${count} assets',
			'importAssets.success' => ({required Object count}) => 'Imported ${count} new assets.',
			'importTransactions.title' => 'Import transactions',
			'importTransactions.intro' => 'Bulk-add transactions from a spreadsheet. One row per movement: ticker, institution, operation, quantity, price, date. The referenced assets must already exist; missing institutions are created automatically.',
			'importTransactions.previewTitle' => 'Review transactions',
			'importTransactions.previewSubtitle' => 'Check what will be added before importing',
			'importTransactions.statTransactions' => 'Transactions',
			'importTransactions.statNewInstitutions' => 'New institutions',
			'importTransactions.reuseNote' => 'Missing institutions are created automatically; existing ones (matched by name) are reused.',
			'importTransactions.submit' => ({required Object count}) => 'Import ${count} transactions',
			'importTransactions.success' => ({required Object count}) => 'Imported ${count} transactions.',
			'importTransactions.missingTitle' => 'Assets not found',
			'importTransactions.missingBody' => ({required Object tickers}) => 'These tickers aren\'t registered yet — import them on the Assets tab first: ${tickers}',
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
			'profile.clearDataError' => 'Couldn\'t clear your data. Please try again.',
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
			'auth.unauthorizedAccount' => 'This account isn\'t authorized to use this app.',
			_ => null,
		};
	}
}
