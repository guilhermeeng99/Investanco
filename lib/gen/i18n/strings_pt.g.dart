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
	late final TranslationsTransactionsPt transactions = TranslationsTransactionsPt._(_root);
	late final TranslationsSettingsPt settings = TranslationsSettingsPt._(_root);
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

	/// pt: 'Tentar novamente'
	String get retry => 'Tentar novamente';
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

	/// pt: 'Configurações'
	String get settings => 'Configurações';
}

// Path: dashboard
class TranslationsDashboardPt {
	TranslationsDashboardPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Carteira'
	String get title => 'Carteira';

	/// pt: 'Cadastre instituição, ativo e um lançamento para acompanhar seus investimentos.'
	String get empty => 'Cadastre instituição, ativo e um lançamento para acompanhar seus investimentos.';

	/// pt: 'Comece sua carteira'
	String get emptyTitle => 'Comece sua carteira';

	/// pt: 'Adicionar instituição'
	String get addFirst => 'Adicionar instituição';

	/// pt: 'Não foi possível carregar sua carteira.'
	String get loadError => 'Não foi possível carregar sua carteira.';

	/// pt: 'Patrimônio total'
	String get total => 'Patrimônio total';

	/// pt: 'Investido'
	String get invested => 'Investido';

	/// pt: 'Lucro/Prejuízo'
	String get profit => 'Lucro/Prejuízo';

	/// pt: 'Variação do dia'
	String get dayChange => 'Variação do dia';

	/// pt: 'Alocação por classe'
	String get allocation => 'Alocação por classe';

	/// pt: 'Evolução do patrimônio'
	String get evolution => 'Evolução do patrimônio';

	/// pt: 'Posições'
	String get holdings => 'Posições';

	/// pt: 'Atualizado'
	String get lastSync => 'Atualizado';

	/// pt: 'nunca'
	String get never => 'nunca';

	/// pt: 'Atualizar'
	String get refresh => 'Atualizar';

	/// pt: 'Cotações podem estar desatualizadas'
	String get pricesStale => 'Cotações podem estar desatualizadas';
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

	/// pt: 'Nome no Tesouro Direto'
	String get tesouroName => 'Nome no Tesouro Direto';

	/// pt: 'Exato como no site, ex.: Tesouro Selic 2027.'
	String get tesouroNameHelp => 'Exato como no site, ex.: Tesouro Selic 2027.';

	/// pt: 'Indexador'
	String get fixedIncomeBasis => 'Indexador';

	/// pt: 'Taxa contratada (%)'
	String get fixedIncomeRate => 'Taxa contratada (%)';

	/// pt: 'CDI/Selic: % do índice. Prefixado: % a.a. IPCA+: spread % a.a.'
	String get fixedIncomeRateHelp => 'CDI/Selic: % do índice. Prefixado: % a.a. IPCA+: spread % a.a.';

	late final TranslationsAssetsBasisPt basis = TranslationsAssetsBasisPt._(_root);

	/// pt: 'Excluir este ativo?'
	String get deleteConfirm => 'Excluir este ativo?';

	/// pt: 'Não é possível excluir: há lançamentos vinculados.'
	String get inUseError => 'Não é possível excluir: há lançamentos vinculados.';

	/// pt: 'Erro ao salvar.'
	String get saveError => 'Erro ao salvar.';

	late final TranslationsAssetsKindsPt kinds = TranslationsAssetsKindsPt._(_root);
	late final TranslationsAssetsMarketsPt markets = TranslationsAssetsMarketsPt._(_root);
}

// Path: transactions
class TranslationsTransactionsPt {
	TranslationsTransactionsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Lançamentos'
	String get title => 'Lançamentos';

	/// pt: 'Nenhum lançamento ainda. Registre compras, vendas e dividendos.'
	String get empty => 'Nenhum lançamento ainda. Registre compras, vendas e dividendos.';

	/// pt: 'Novo lançamento'
	String get add => 'Novo lançamento';

	/// pt: 'Editar lançamento'
	String get edit => 'Editar lançamento';

	/// pt: 'Instituição'
	String get institution => 'Instituição';

	/// pt: 'Ativo'
	String get asset => 'Ativo';

	/// pt: 'Tipo'
	String get kind => 'Tipo';

	/// pt: 'Quantidade'
	String get quantity => 'Quantidade';

	/// pt: 'Preço unitário'
	String get unitPrice => 'Preço unitário';

	/// pt: 'Taxas'
	String get fees => 'Taxas';

	/// pt: 'Valor total'
	String get amount => 'Valor total';

	/// pt: 'Data'
	String get date => 'Data';

	/// pt: 'Observações'
	String get notes => 'Observações';

	/// pt: 'Excluir este lançamento?'
	String get deleteConfirm => 'Excluir este lançamento?';

	/// pt: 'Erro ao salvar.'
	String get saveError => 'Erro ao salvar.';

	/// pt: 'Cadastre uma instituição e um ativo antes.'
	String get needPrereqs => 'Cadastre uma instituição e um ativo antes.';

	late final TranslationsTransactionsKindsPt kinds = TranslationsTransactionsKindsPt._(_root);
}

// Path: settings
class TranslationsSettingsPt {
	TranslationsSettingsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Configurações'
	String get title => 'Configurações';

	/// pt: 'Aparência'
	String get appearance => 'Aparência';

	/// pt: 'Cotações e dados'
	String get quotes => 'Cotações e dados';

	/// pt: 'Geral'
	String get general => 'Geral';

	/// pt: 'Idioma'
	String get language => 'Idioma';

	/// pt: 'Português'
	String get languagePt => 'Português';

	/// pt: 'Inglês'
	String get languageEn => 'Inglês';

	/// pt: 'Tema'
	String get theme => 'Tema';

	/// pt: 'Sistema'
	String get themeSystem => 'Sistema';

	/// pt: 'Claro'
	String get themeLight => 'Claro';

	/// pt: 'Escuro'
	String get themeDark => 'Escuro';

	/// pt: 'Token brapi (opcional)'
	String get brapiToken => 'Token brapi (opcional)';

	/// pt: 'Aumenta o limite de cotações da B3.'
	String get brapiTokenHelp => 'Aumenta o limite de cotações da B3.';

	/// pt: 'Token Finnhub (ativos EUA)'
	String get finnhubToken => 'Token Finnhub (ativos EUA)';

	/// pt: 'Grátis em finnhub.io — necessário p/ cotação de ações/ETFs dos EUA.'
	String get finnhubTokenHelp => 'Grátis em finnhub.io — necessário p/ cotação de ações/ETFs dos EUA.';

	/// pt: 'Moeda base'
	String get baseCurrency => 'Moeda base';
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

// Path: assets.basis
class TranslationsAssetsBasisPt {
	TranslationsAssetsBasisPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'CDI'
	String get cdi => 'CDI';

	/// pt: 'Selic'
	String get selic => 'Selic';

	/// pt: 'Prefixado'
	String get prefixed => 'Prefixado';

	/// pt: 'IPCA+'
	String get ipca => 'IPCA+';
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

// Path: transactions.kinds
class TranslationsTransactionsKindsPt {
	TranslationsTransactionsKindsPt._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pt: 'Compra'
	String get buy => 'Compra';

	/// pt: 'Venda'
	String get sell => 'Venda';

	/// pt: 'Dividendo'
	String get dividend => 'Dividendo';
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
			'common.retry' => 'Tentar novamente',
			'currencies.brl' => 'Real (BRL)',
			'currencies.usd' => 'Dólar (USD)',
			'nav.dashboard' => 'Carteira',
			'nav.institutions' => 'Instituições',
			'nav.assets' => 'Ativos',
			'nav.transactions' => 'Lançamentos',
			'nav.settings' => 'Configurações',
			'dashboard.title' => 'Carteira',
			'dashboard.empty' => 'Cadastre instituição, ativo e um lançamento para acompanhar seus investimentos.',
			'dashboard.emptyTitle' => 'Comece sua carteira',
			'dashboard.addFirst' => 'Adicionar instituição',
			'dashboard.loadError' => 'Não foi possível carregar sua carteira.',
			'dashboard.total' => 'Patrimônio total',
			'dashboard.invested' => 'Investido',
			'dashboard.profit' => 'Lucro/Prejuízo',
			'dashboard.dayChange' => 'Variação do dia',
			'dashboard.allocation' => 'Alocação por classe',
			'dashboard.evolution' => 'Evolução do patrimônio',
			'dashboard.holdings' => 'Posições',
			'dashboard.lastSync' => 'Atualizado',
			'dashboard.never' => 'nunca',
			'dashboard.refresh' => 'Atualizar',
			'dashboard.pricesStale' => 'Cotações podem estar desatualizadas',
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
			'assets.tesouroName' => 'Nome no Tesouro Direto',
			'assets.tesouroNameHelp' => 'Exato como no site, ex.: Tesouro Selic 2027.',
			'assets.fixedIncomeBasis' => 'Indexador',
			'assets.fixedIncomeRate' => 'Taxa contratada (%)',
			'assets.fixedIncomeRateHelp' => 'CDI/Selic: % do índice. Prefixado: % a.a. IPCA+: spread % a.a.',
			'assets.basis.cdi' => 'CDI',
			'assets.basis.selic' => 'Selic',
			'assets.basis.prefixed' => 'Prefixado',
			'assets.basis.ipca' => 'IPCA+',
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
			'transactions.title' => 'Lançamentos',
			'transactions.empty' => 'Nenhum lançamento ainda. Registre compras, vendas e dividendos.',
			'transactions.add' => 'Novo lançamento',
			'transactions.edit' => 'Editar lançamento',
			'transactions.institution' => 'Instituição',
			'transactions.asset' => 'Ativo',
			'transactions.kind' => 'Tipo',
			'transactions.quantity' => 'Quantidade',
			'transactions.unitPrice' => 'Preço unitário',
			'transactions.fees' => 'Taxas',
			'transactions.amount' => 'Valor total',
			'transactions.date' => 'Data',
			'transactions.notes' => 'Observações',
			'transactions.deleteConfirm' => 'Excluir este lançamento?',
			'transactions.saveError' => 'Erro ao salvar.',
			'transactions.needPrereqs' => 'Cadastre uma instituição e um ativo antes.',
			'transactions.kinds.buy' => 'Compra',
			'transactions.kinds.sell' => 'Venda',
			'transactions.kinds.dividend' => 'Dividendo',
			'settings.title' => 'Configurações',
			'settings.appearance' => 'Aparência',
			'settings.quotes' => 'Cotações e dados',
			'settings.general' => 'Geral',
			'settings.language' => 'Idioma',
			'settings.languagePt' => 'Português',
			'settings.languageEn' => 'Inglês',
			'settings.theme' => 'Tema',
			'settings.themeSystem' => 'Sistema',
			'settings.themeLight' => 'Claro',
			'settings.themeDark' => 'Escuro',
			'settings.brapiToken' => 'Token brapi (opcional)',
			'settings.brapiTokenHelp' => 'Aumenta o limite de cotações da B3.',
			'settings.finnhubToken' => 'Token Finnhub (ativos EUA)',
			'settings.finnhubTokenHelp' => 'Grátis em finnhub.io — necessário p/ cotação de ações/ETFs dos EUA.',
			'settings.baseCurrency' => 'Moeda base',
			_ => null,
		};
	}
}
