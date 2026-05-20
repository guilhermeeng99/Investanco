// Intentionally a one-member abstraction: it isolates the uuid dependency
// behind a project-owned port so it can be injected via get_it and faked in
// tests (per CLAUDE.md "wrap external libraries behind interfaces").
// ignore_for_file: one_member_abstracts
import 'package:uuid/uuid.dart';

/// Generates unique ids for new entities. Wrapped behind an interface so the
/// uuid dependency stays out of the domain/presentation layers and can be
/// faked in tests.
abstract class IdGenerator {
  /// Returns a new globally-unique id.
  String newId();
}

/// Default [IdGenerator] backed by UUID v4.
class UuidGenerator implements IdGenerator {
  /// Creates a UUID-backed generator.
  const UuidGenerator();

  @override
  String newId() => const Uuid().v4();
}
