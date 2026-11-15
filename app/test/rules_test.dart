import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/data/models/rule_environment.dart';

void main() {
  const win = RuleEnvironment(osName: 'windows');
  const mac = RuleEnvironment(osName: 'osx');

  test('no rules means allowed', () {
    expect(rulesAllow(null, win), isTrue);
    expect(rulesAllow(const [], win), isTrue);
  });

  test('allow + disallow for a specific OS', () {
    final rules = [
      {'action': 'allow'},
      {
        'action': 'disallow',
        'os': {'name': 'osx'},
      },
    ];
    expect(rulesAllow(rules, win), isTrue);
    expect(rulesAllow(rules, mac), isFalse);
  });

  test('os-only allow rule excludes other systems', () {
    final rules = [
      {
        'action': 'allow',
        'os': {'name': 'windows'},
      },
    ];
    expect(rulesAllow(rules, win), isTrue);
    expect(rulesAllow(rules, mac), isFalse);
  });

  test('feature rules require the feature to be present', () {
    final rules = [
      {
        'action': 'allow',
        'features': {'is_demo_user': true},
      },
    ];
    expect(rulesAllow(rules, win), isFalse);
    expect(
      rulesAllow(rules, const RuleEnvironment(osName: 'windows', features: {'is_demo_user'})),
      isTrue,
    );
  });
}
