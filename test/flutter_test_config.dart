import 'dart:async';

import 'harness/mocks.dart';

/// Auto-discovered by `flutter test`: wraps every test file in the tree. Registers
/// the shared mocktail fallback values once so individual tests don't repeat them.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  registerCommonFallbacks();
  await testMain();
}
