import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/core/utils/version_compare.dart';

void main() {
  test('orders semantic versions', () {
    expect(compareVersions('1.2.0', '1.1.9'), greaterThan(0));
    expect(compareVersions('v1.0.0', '1.0.0'), 0);
  });

  test('pre-release is older than release', () {
    expect(compareVersions('0.1.0-beta.1', '0.1.0'), lessThan(0));
    expect(compareVersions('0.1.0-beta.2', '0.1.0-beta.1'), greaterThan(0));
  });

  test('isNewerVersion', () {
    expect(isNewerVersion('0.1.0-beta.2', '0.1.0-beta.1'), isTrue);
    expect(isNewerVersion('0.1.0-beta.1', '0.1.0-beta.1'), isFalse);
  });
}
