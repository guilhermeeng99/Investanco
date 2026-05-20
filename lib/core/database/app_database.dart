import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Institutions where assets are custodied. Row class renamed to avoid clashing
/// with the domain `Institution` entity.
@DataClassName('InstitutionRow')
class Institutions extends Table {
  /// Stable unique id.
  TextColumn get id => text()();

  /// Display name.
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `InstitutionKind` name.
  TextColumn get kind => text()();

  /// `Currency` name.
  TextColumn get currency => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Tradable instruments. Row class renamed to avoid clashing with `Asset`.
@DataClassName('AssetRow')
class Assets extends Table {
  /// Stable unique id.
  TextColumn get id => text()();

  /// Quote symbol or synthetic id.
  TextColumn get ticker => text()();

  /// Human-readable label.
  TextColumn get name => text()();

  /// `AssetKind` name.
  TextColumn get kind => text()();

  /// `Market` name.
  TextColumn get market => text()();

  /// `Currency` name (native).
  TextColumn get currency => text()();

  /// JSON-encoded `Map<String, String>` of kind-specific metadata.
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Buy/sell/dividend events. Row class renamed to avoid clashing with the domain
/// `AssetTransaction` and Drift's own `Transaction`.
@DataClassName('TransactionRow')
class Transactions extends Table {
  /// Stable unique id.
  TextColumn get id => text()();

  /// FK → Institutions.id.
  TextColumn get institutionId => text()();

  /// FK → Assets.id.
  TextColumn get assetId => text()();

  /// `TransactionKind` name.
  TextColumn get kind => text()();

  /// Units traded (fractional allowed).
  RealColumn get quantity => real()();

  /// Unit price in minor units (native currency).
  IntColumn get unitPriceMinor => integer()();

  /// Fees in minor units.
  IntColumn get feesMinor => integer()();

  /// Total amount in minor units (dividend total, or quantity*unitPrice).
  IntColumn get amountMinor => integer()();

  /// `Currency` name of the monetary fields.
  TextColumn get currency => text()();

  /// Event date.
  DateTimeColumn get date => dateTime()();

  /// Optional note.
  TextColumn get notes => text().nullable()();

  /// Audit timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Audit timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local SQLite database (offline-first source of truth). On web it runs via the
/// Drift worker + sqlite3 WASM assets (downloaded in CI / shipped with the app).
/// Cached unit prices. Row class renamed to avoid clashing with `Quote`.
@DataClassName('QuoteRow')
class Quotes extends Table {
  /// Asset id (one cached quote per asset).
  TextColumn get assetId => text()();

  /// Latest unit price in minor units (native currency).
  IntColumn get unitPriceMinor => integer()();

  /// Previous close in minor units (nullable).
  IntColumn get previousCloseMinor => integer().nullable()();

  /// `Currency` name of the price.
  TextColumn get currency => text()();

  /// When the source reported the price.
  DateTimeColumn get asOf => dateTime()();

  /// When we cached it.
  DateTimeColumn get fetchedAt => dateTime()();

  /// `QuoteSource` name.
  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

@DriftDatabase(tables: [Institutions, Assets, Transactions, Quotes])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or uses [executor] (e.g. an in-memory
  /// database in tests).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'investanco'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(quotes);
        },
      );
}
