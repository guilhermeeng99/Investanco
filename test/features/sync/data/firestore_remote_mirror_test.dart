import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/sync/data/firestore_remote_mirror.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/auth_user_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockAuthRepository auth;
  late FirestoreRemoteMirror mirror;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockAuthRepository();
    mirror = FirestoreRemoteMirror(firestore, auth);
  });

  test('upsert writes the row under users/{uid}/{collection}/{id}', () async {
    when(() => auth.currentUser).thenReturn(authUserFactory(userId: 'u1'));

    await mirror.upsert('assets', 'a1', {'id': 'a1', 'ticker': 'PETR4'});

    final doc = await firestore.doc('users/u1/assets/a1').get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['ticker'], 'PETR4');
  });

  test('upsert is a no-op when signed out', () async {
    when(() => auth.currentUser).thenReturn(null);

    await mirror.upsert('assets', 'a1', {'id': 'a1'});

    // Nothing was written: even after a user appears, the doc is absent.
    when(() => auth.currentUser).thenReturn(authUserFactory(userId: 'u1'));
    final doc = await firestore.doc('users/u1/assets/a1').get();
    expect(doc.exists, isFalse);
  });

  test('delete removes the row for the current user', () async {
    when(() => auth.currentUser).thenReturn(authUserFactory(userId: 'u1'));
    await mirror.upsert('assets', 'a1', {'id': 'a1'});

    await mirror.delete('assets', 'a1');

    final doc = await firestore.doc('users/u1/assets/a1').get();
    expect(doc.exists, isFalse);
  });
}
