import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/core/utils/offline_uuid.dart';

void main() {
  group('offlineUuid', () {
    test('is deterministic and name-specific', () {
      expect(offlineUuid('Steve'), offlineUuid('Steve'));
      expect(offlineUuid('Steve'), isNot(offlineUuid('Alex')));
    });

    test('is a version-3 IETF UUID', () {
      final uuid = offlineUuid('Steve');
      expect(
        uuid,
        matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-3[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        )),
      );
    });
  });

  group('isValidUsername', () {
    test('accepts 3-16 chars of letters, digits and underscore', () {
      expect(isValidUsername('Steve_01'), isTrue);
      expect(isValidUsername('ab'), isFalse);
      expect(isValidUsername('has space'), isFalse);
      expect(isValidUsername('a' * 17), isFalse);
    });
  });
}
