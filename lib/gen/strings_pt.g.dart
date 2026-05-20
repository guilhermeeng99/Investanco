///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsPt = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// pt: 'Investanco'
	String get appName => 'Investanco';

	late final TranslationsCommonPt common = TranslationsCommonPt._(_root);
	late final TranslationsCurrenciesPt currencies = TranslationsCurrenciesPt._(_root);
	late final TranslationsNavPt nav = TranslationsNavPt._(_root);
	late final TranslationsDashboardPt dashboard = TranslationsDashboardPt._(_root);
	late final TranslationsInstitutionsPt institutions = TranslationsInstitutionsPt._(_root);
	late final TranslationsAssetsPt assets = TranslationsAssetsPt._(_root);
}

// Path: common
class TranslationsCommonPt {
	TranslationsCommonPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Salvar'
	String get save => 'Salvar';

	/// pt: 'Cancelar'
	String get cancel => 'Cancelar';

	/// pt: 'Excluir'
	String get delete => 'Excluir';

	/// pt: 'Editar'
	String get edit => 'Editar';

	/// pt: 'Adicionar'
	String get add => 'Adicionar';

	/// pt: 'Confirmar'
	String get confirm => 'Confirmar';

	/// pt: 'Campo obrigatório'
	String get required => 'Campo obrigatório';
}

// Path: currencies
class TranslationsCurrenciesPt {
	TranslationsCurrenciesPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Real (BRL)'
	String get brl => 'Real (BRL)';

	/// pt: 'Dólar (USD)'
	String get usd => 'Dólar (USD)';
}

// Path: nav
class TranslationsNavPt {
	TranslationsNavPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Carteira'
	String get dashboard => 'Carteira';

	/// pt: 'Instituições'
	String get institutions => 'Instituições';

	/// pt: 'Ativos'
	String get assets => 'Ativos';

	/// pt: 'Lançamentos'
	String get transactions => 'Lançamentos';
}

// Path: dashboard
class TranslationsDashboardPt {
	TranslationsDashboardPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Carteira'
	String get title => 'Carteira';

	/// pt: 'Adicione sua primeira instituição para começar a acompanhar seus investimentos.'
	String get empty => 'Adicione sua primeira instituição para começar a acompanhar seus investimentos.';
}

// Path: institutions
class TranslationsInstitutionsPt {
	TranslationsInstitutionsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Instituições'
	String get title => 'Instituições';

	/// pt: 'Nenhuma instituição ainda. Adicione Nubank, Avenue, etc.'
	String get empty => 'Nenhuma instituição ainda. Adicione Nubank, Avenue, etc.';

	/// pt: 'Nova instituição'
	String get add => 'Nova instituição';

	/// pt: 'Editar instituição'
	String get edit => 'Editar instituição';

	/// pt: 'Nome'
	String get name => 'Nome';

	/// pt: 'Tipo'
	String get kind => 'Tipo';

	/// pt: 'Moeda'
	String get currency => 'Moeda';

	/// pt: 'Excluir esta instituição?'
	String get deleteConfirm => 'Excluir esta instituição?';

	/// pt: 'Não é possível excluir: há lançamentos vinculados.'
	String get inUseError => 'Não é possível excluir: há lançamentos vinculados.';

	/// pt: 'Erro ao salvar.'
	String get saveError => 'Erro ao salvar.';

	late final TranslationsInstitutionsKindsPt kinds = TranslationsInstitutionsKindsPt._(_root);
}

// Path: assets
class TranslationsAssetsPt {
	TranslationsAssetsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Ativos'
	String get title => 'Ativos';

	/// pt: 'Nenhum ativo ainda. Cadastre PETR4, AAPL, Tesouro, etc.'
	String get empty => 'Nenhum ativo ainda. Cadastre PETR4, AAPL, Tesouro, etc.';

	/// pt: 'Novo ativo'
	String get add => 'Novo ativo';

	/// pt: 'Editar ativo'
	String get edit => 'Editar ativo';

	/// pt: 'Ticker'
	String get ticker => 'Ticker';

	/// pt: 'Nome'
	String get name => 'Nome';

	/// pt: 'Tipo'
	String get kind => 'Tipo';

	/// pt: 'Mercado'
	String get market => 'Mercado';

	/// pt: 'Moeda'
	String get currency => 'Moeda';

	/// pt: 'Excluir este ativo?'
	String get deleteConfirm => 'Excluir este ativo?';

	/// pt: 'Não é possível excluir: há lançamentos vinculados.'
	String get inUseError => 'Não é possível excluir: há lançamentos vinculados.';

	/// pt: 'Erro ao salvar.'
	String get saveError => 'Erro ao salvar.';

	late final TranslationsAssetsKindsPt kinds = TranslationsAssetsKindsPt._(_root);
	late final TranslationsAssetsMarketsPt markets = TranslationsAssetsMarketsPt._(_root);
}

// Path: institutions.kinds
class TranslationsInstitutionsKindsPt {
	TranslationsInstitutionsKindsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Banco'
	String get bank => 'Banco';

	/// pt: 'Corretora'
	String get broker => 'Corretora';

	/// pt: 'Corretora internacional'
	String get internationalBroker => 'Corretora internacional';

	/// pt: 'Cripto'
	String get crypto => 'Cripto';

	/// pt: 'Outro'
	String get other => 'Outro';
}

// Path: assets.kinds
class TranslationsAssetsKindsPt {
	TranslationsAssetsKindsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Ação (BR)'
	String get stockBr => 'Ação (BR)';

	/// pt: 'FII'
	String get fiiBr => 'FII';

	/// pt: 'ETF (BR)'
	String get etfBr => 'ETF (BR)';

	/// pt: 'BDR'
	String get bdrBr => 'BDR';

	/// pt: 'Ação (EUA)'
	String get stockUs => 'Ação (EUA)';

	/// pt: 'ETF (EUA)'
	String get etfUs => 'ETF (EUA)';

	/// pt: 'Cripto'
	String get crypto => 'Cripto';

	/// pt: 'Tesouro Direto'
	String get treasury => 'Tesouro Direto';

	/// pt: 'Renda fixa'
	String get fixedIncome => 'Renda fixa';

	/// pt: 'Fundo'
	String get fund => 'Fundo';

	/// pt: 'Caixa'
	String get cash => 'Caixa';
}

// Path: assets.markets
class TranslationsAssetsMarketsPt {
	TranslationsAssetsMarketsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Brasil'
	String get br => 'Brasil';

	/// pt: 'EUA'
	String get us => 'EUA';

	/// pt: 'Global'
	String get global => 'Global';
}

/// The flat map containing all translations for locale <pt>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Investanco',
			'common.save' => 'Salvar',
			'common.cancel' => 'Cancelar',
			'common.delete' => 'Excluir',
			'common.edit' => 'Editar',
			'common.add' => 'Adicionar',
			'common.confirm' => 'Confirmar',
			'common.required' => 'Campo obrigatório',
			'currencies.brl' => 'Real (BRL)',
			'currencies.usd' => 'Dólar (USD)',
			'nav.dashboard' => 'Carteira',
			'nav.institutions' => 'Instituições',
			'nav.assets' => 'Ativos',
			'nav.transactions' => 'Lançamentos',
			'dashboard.title' => 'Carteira',
			'dashboard.empty' => 'Adicione sua primeira instituição para começar a acompanhar seus investimentos.',
			'institutions.title' => 'Instituições',
			'institutions.empty' => 'Nenhuma instituição ainda. Adicione Nubank, Avenue, etc.',
			'institutions.add' => 'Nova instituição',
			'institutions.edit' => 'Editar instituição',
			'institutions.name' => 'Nome',
			'institutions.kind' => 'Tipo',
			'institutions.currency' => 'Moeda',
			'institutions.deleteConfirm' => 'Excluir esta instituição?',
			'institutions.inUseError' => 'Não é possível excluir: há lançamentos vinculados.',
			'institutions.saveError' => 'Erro ao salvar.',
			'institutions.kinds.bank' => 'Banco',
			'institutions.kinds.broker' => 'Corretora',
			'institutions.kinds.internationalBroker' => 'Corretora internacional',
			'institutions.kinds.crypto' => 'Cripto',
			'institutions.kinds.other' => 'Outro',
			'assets.title' => 'Ativos',
			'assets.empty' => 'Nenhum ativo ainda. Cadastre PETR4, AAPL, Tesouro, etc.',
			'assets.add' => 'Novo ativo',
			'assets.edit' => 'Editar ativo',
			'assets.ticker' => 'Ticker',
			'assets.name' => 'Nome',
			'assets.kind' => 'Tipo',
			'assets.market' => 'Mercado',
			'assets.currency' => 'Moeda',
			'assets.deleteConfirm' => 'Excluir este ativo?',
			'assets.inUseError' => 'Não é possível excluir: há lançamentos vinculados.',
			'assets.saveError' => 'Erro ao salvar.',
			'assets.kinds.stockBr' => 'Ação (BR)',
			'assets.kinds.fiiBr' => 'FII',
			'assets.kinds.etfBr' => 'ETF (BR)',
			'assets.kinds.bdrBr' => 'BDR',
			'assets.kinds.stockUs' => 'Ação (EUA)',
			'assets.kinds.etfUs' => 'ETF (EUA)',
			'assets.kinds.crypto' => 'Cripto',
			'assets.kinds.treasury' => 'Tesouro Direto',
			'assets.kinds.fixedIncome' => 'Renda fixa',
			'assets.kinds.fund' => 'Fundo',
			'assets.kinds.cash' => 'Caixa',
			'assets.markets.br' => 'Brasil',
			'assets.markets.us' => 'EUA',
			'assets.markets.global' => 'Global',
			_ => null,
		};
	}
}
