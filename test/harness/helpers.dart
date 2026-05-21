import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';

/// Opens an in-memory [AppDatabase] and registers its teardown for the current
/// test, so data tests no longer repeat the open/close boilerplate. Call from a
/// `setUp` callback (or a test body):
///
/// ```dart
/// late AppDatabase db;
/// setUp(() => db = memoryDatabase());
/// ```
AppDatabase memoryDatabase() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}
