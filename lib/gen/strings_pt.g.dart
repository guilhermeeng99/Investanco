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
			_ => null,
		};
	}
}
