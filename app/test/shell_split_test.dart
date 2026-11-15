import 'package:flutter_test/flutter_test.dart';
import 'package:nuvio_launcher/core/utils/shell_split.dart';

void main() {
  test('splits on whitespace and respects quotes', () {
    expect(
      splitArguments('-Xmx2G -Dname="hello world" -XX:+UseG1GC'),
      ['-Xmx2G', '-Dname=hello world', '-XX:+UseG1GC'],
    );
  });

  test('empty input gives no arguments', () {
    expect(splitArguments('   '), isEmpty);
  });
}
