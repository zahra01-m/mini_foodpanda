import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foodpanda/core/utils/error_text.dart';

void main() {
  FirebaseException ex(String code) => FirebaseException(plugin: 'cloud_firestore', code: code);

  test('permission-denied points at the security rules', () {
    expect(friendlyError(ex('permission-denied')), contains('permission denied'));
  });

  test('unavailable is reported as a connection problem', () {
    expect(friendlyError(ex('unavailable')), contains('connection'));
  });

  test('failed-precondition mentions the missing index', () {
    expect(friendlyError(ex('failed-precondition')), contains('index'));
  });

  test('unknown errors get a generic message, never raw exception text', () {
    final msg = friendlyError(StateError('boom: secret internals'));
    expect(msg, isNot(contains('secret')));
    expect(msg, isNotEmpty);
  });
}
