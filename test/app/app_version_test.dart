import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_tab/app/app_version.dart';

void main() {
  test('the version shown matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+)\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(appVersion, match.group(1));
    expect(appBuild, int.parse(match.group(2)!));
  });
}
