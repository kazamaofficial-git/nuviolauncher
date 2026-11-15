import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/data/models/license_state.dart';

void main() {
  final checked = DateTime.utc(2026, 11, 1);
  LicenseState build({DateTime? expiresAt, List<String> features = const ['plus']}) =>
      LicenseState(
        key: 'NUVIO-AAAA-BBBB-CCCC',
        checkedAt: checked,
        info: LicenseInfo(
          keyMasked: 'NUVIO-AAAA-••••-CCCC',
          plan: 'plus',
          features: features,
          expiresAt: expiresAt,
          maxDevices: 2,
          devicesUsed: 1,
        ),
      );

  test('grants plus inside the 7-day offline grace period', () {
    final s = build();
    expect(s.grantsFeature('plus', checked.add(const Duration(days: 6))), isTrue);
    expect(s.statusAt(checked.add(const Duration(days: 6))), LicenseStatus.active);
  });

  test('requires revalidation after the grace period', () {
    final s = build();
    final later = checked.add(const Duration(days: 8));
    expect(s.grantsFeature('plus', later), isFalse);
    expect(s.statusAt(later), LicenseStatus.needsRevalidation);
  });

  test('expired licences grant nothing', () {
    final s = build(expiresAt: checked.add(const Duration(days: 1)));
    final later = checked.add(const Duration(days: 2));
    expect(s.statusAt(later), LicenseStatus.expired);
    expect(s.grantsFeature('plus', later), isFalse);
  });

  test('feature must be listed on the licence', () {
    expect(build(features: const []).grantsFeature('plus', checked), isFalse);
  });
}
