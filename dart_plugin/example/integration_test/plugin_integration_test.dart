// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:beam_vm/beam_vm.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getOtpVersion test', (WidgetTester tester) async {
    final beamVm = BeamVm();
    final version = await beamVm.otpVersion;
    // The version string depends on the embedded runtime
    expect(version.isNotEmpty, true);
  });

  testWidgets('initial status is uninitialized', (WidgetTester tester) async {
    final beamVm = BeamVm();
    expect(beamVm.status, equals(BeamVmStatus.uninitialized));
    expect(beamVm.isInitialized, isFalse);
  });
}
