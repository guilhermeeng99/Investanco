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

/// Local SQLite cache (Firestore is the source of truth). On web it runs via the
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

/// Daily portfolio value snapshots for the evolution chart. Row class renamed
/// to avoid clashing with `Snapshot`.
@DataClassName('SnapshotRow')
class Snapshots extends Table {
  /// `yyyy-MM-dd` key (one snapshot per day).
  TextColumn get id => text()();

  /// Snapshot date (local midnight).
  DateTimeColumn get date => dateTime()();

  /// Total value in minor units (base currency).
  IntColumn get totalValueMinor => integer()();

  /// Total invested in minor units (base currency).
  IntColumn get totalInvestedMinor => integer()();

  /// Total unrealized P/L in minor units (base currency).
  IntColumn get totalPlMinor => integer()();

  /// `Currency` name (base).
  TextColumn get currency => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single-row user settings (id is always 0). Row class renamed to avoid
/// clashing with the `AppSettings` entity.
@DataClassName('SettingsRow')
class Settings extends Table {
  /// Constant primary key (always 0).
  IntColumn get id => integer()();

  /// `AppThemeMode` name.
  TextColumn get themeMode => text()();

  /// `Currency` name (base).
  TextColumn get baseCurrency => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Institutions, Assets, Transactions, Quotes, Snapshots, Settings],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or uses [executor] (e.g. an in-memory
  /// database in tests).
  AppDatabase([QueryExecutor? executor])
      : super(
          executor ??
              driftDatabase(
                name: 'investanco',
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.dart.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(quotes);
          if (from < 3) await m.createTable(snapshots);
          if (from < 4) await m.createTable(settings);
          // v5 added a Finnhub token column; v6 dropped both token columns
          // (tokens are now build-time dart-define). Recreate the settings
          // table to the new shape, preserving theme + base currency.
          if (from < 6) await m.alterTable(TableMigration(settings));
        },
      );

  /// Wipes all user-owned data, keeping device-local [settings]. Children are
  /// deleted before parents to respect references. Drift watch streams emit
  /// afterwards, so every screen clears reactively. Used by "clear my data".
  Future<void> clearUserData() => transaction(() async {
        await delete(transactions).go();
        await delete(quotes).go();
        await delete(snapshots).go();
        await delete(assets).go();
        await delete(institutions).go();
      });

  /// Replaces the cloud-mirrored tables with [institutions], [assets],
  /// [transactions] and [snapshots] in a single transaction, so a startup sync
  /// makes the local cache match Firestore exactly (creates, edits **and**
  /// deletes from any device are reflected). Quotes (a derived cache) and
  /// settings (device-local) are preserved. See `docs/specs/cloud_sync.md`.
  Future<void> replaceMirroredData({
    required List<InstitutionRow> institutions,
    required List<AssetRow> assets,
    required List<TransactionRow> transactions,
    required List<SnapshotRow> snapshots,
  }) =>
      transaction(() async {
        await delete(this.transactions).go();
        await delete(this.snapshots).go();
        await delete(this.assets).go();
        await delete(this.institutions).go();
        await batch((b) {
          b
            ..insertAll(this.institutions, institutions)
            ..insertAll(this.assets, assets)
            ..insertAll(this.transactions, transactions)
            ..insertAll(this.snapshots, snapshots);
        });
      });
}
