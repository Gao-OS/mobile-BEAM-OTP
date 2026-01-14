import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beam_vm_example/main.dart';

void main() {
  testWidgets('App shows OTP version and status', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that OTP version label is shown
    expect(find.textContaining('OTP Version:'), findsOneWidget);

    // Verify that status is shown
    expect(find.textContaining('Status:'), findsOneWidget);
  });
}
