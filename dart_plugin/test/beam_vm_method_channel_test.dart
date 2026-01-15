import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beam_vm/beam_vm.dart';
import 'package:beam_vm/beam_vm_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelBeamVm platform;
  late List<MethodCall> methodCalls;

  setUp(() {
    platform = MethodChannelBeamVm();
    methodCalls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('io.beamvm/beam_vm'),
      (MethodCall methodCall) async {
        methodCalls.add(methodCall);

        switch (methodCall.method) {
          case 'initialize':
            return true;
          case 'shutdown':
            return null;
          case 'call':
            return jsonEncode({'result': 'ok'});
          case 'send':
            return null;
          case 'getOtpVersion':
            return '28.3';
          case 'isInitialized':
            return true;
          case 'registerMessageHandler':
            return null;
          case 'unregisterMessageHandler':
            return null;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('io.beamvm/beam_vm'),
      null,
    );
  });

  group('MethodChannelBeamVm', () {
    group('status', () {
      test('initial status is uninitialized', () {
        expect(platform.status, equals(BeamVmStatus.uninitialized));
      });

      test('statusStream emits status changes', () async {
        final statuses = <BeamVmStatus>[];
        final subscription = platform.statusStream.listen(statuses.add);

        // Trigger status change via initialize
        await platform.initialize('/path');

        await Future.delayed(Duration.zero);

        expect(statuses, contains(BeamVmStatus.initializing));
        expect(statuses, contains(BeamVmStatus.running));

        await subscription.cancel();
      });
    });

    group('initialize', () {
      test('calls native initialize method', () async {
        await platform.initialize('/path/to/erlang');

        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('initialize'));
        expect(
          methodCalls.first.arguments,
          equals({'erlangPath': '/path/to/erlang'}),
        );
      });

      test('updates status to running on success', () async {
        await platform.initialize('/path');

        expect(platform.status, equals(BeamVmStatus.running));
      });

      test('updates status to error on failure', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('io.beamvm/beam_vm'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'initialize') {
              throw PlatformException(code: 'INIT_FAILED', message: 'Failed');
            }
            return null;
          },
        );

        expect(
          () => platform.initialize('/path'),
          throwsA(isA<BeamVmException>()),
        );
      });

      test('returns true on success', () async {
        final result = await platform.initialize('/path');
        expect(result, isTrue);
      });

      test('returns false when native returns false', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('io.beamvm/beam_vm'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'initialize') {
              return false;
            }
            return null;
          },
        );

        final result = await platform.initialize('/path');
        expect(result, isFalse);
        expect(platform.status, equals(BeamVmStatus.error));
      });
    });

    group('call', () {
      setUp(() async {
        await platform.initialize('/path');
        methodCalls.clear();
      });

      test('sends correct arguments to native', () async {
        await platform.call('Elixir.Math', 'add', [1, 2]);

        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('call'));
        expect(methodCalls.first.arguments['module'], equals('Elixir.Math'));
        expect(methodCalls.first.arguments['function'], equals('add'));
        expect(methodCalls.first.arguments['args'], equals(jsonEncode([1, 2])));
      });

      test('decodes JSON response', () async {
        final result = await platform.call('Elixir.Math', 'add', [1, 2]);

        expect(result, isA<Map>());
        expect(result['result'], equals('ok'));
      });

      test('throws when VM is not running', () async {
        final freshPlatform = MethodChannelBeamVm();

        expect(
          () => freshPlatform.call('Module', 'func', []),
          throwsA(isA<BeamVmException>()),
        );
      });

      test('handles null response', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('io.beamvm/beam_vm'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'call') {
              return null;
            }
            return true;
          },
        );

        final result = await platform.call('Module', 'func', []);
        expect(result, isNull);
      });
    });

    group('send', () {
      setUp(() async {
        await platform.initialize('/path');
        methodCalls.clear();
      });

      test('sends correct arguments to native', () async {
        await platform.send('MyProcess', {'type': 'ping'});

        expect(methodCalls.length, equals(1));
        expect(methodCalls.first.method, equals('send'));
        expect(methodCalls.first.arguments['processName'], equals('MyProcess'));
        expect(
          methodCalls.first.arguments['message'],
          equals(jsonEncode({'type': 'ping'})),
        );
      });

      test('throws when VM is not running', () async {
        final freshPlatform = MethodChannelBeamVm();

        expect(
          () => freshPlatform.send('Process', {}),
          throwsA(isA<BeamVmException>()),
        );
      });
    });

    group('shutdown', () {
      setUp(() async {
        await platform.initialize('/path');
        methodCalls.clear();
      });

      test('calls native shutdown method', () async {
        await platform.shutdown();

        expect(methodCalls.any((c) => c.method == 'shutdown'), isTrue);
      });

      test('updates status to uninitialized', () async {
        await platform.shutdown();

        expect(platform.status, equals(BeamVmStatus.uninitialized));
      });

      test('emits shuttingDown status', () async {
        final statuses = <BeamVmStatus>[];
        final subscription = platform.statusStream.listen(statuses.add);

        await platform.shutdown();
        await Future.delayed(Duration.zero);

        expect(statuses, contains(BeamVmStatus.shuttingDown));

        await subscription.cancel();
      });
    });

    group('otpVersion', () {
      test('returns version from native', () async {
        final version = await platform.otpVersion;
        expect(version, equals('28.3'));
      });

      test('returns unknown on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('io.beamvm/beam_vm'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getOtpVersion') {
              throw PlatformException(code: 'ERROR', message: 'Failed');
            }
            return null;
          },
        );

        final version = await platform.otpVersion;
        expect(version, equals('unknown'));
      });
    });

    group('onMessage', () {
      test('registers handler with native', () async {
        platform.onMessage('events', (_) {});

        await Future.delayed(Duration.zero);

        expect(
          methodCalls.any((c) => c.method == 'registerMessageHandler'),
          isTrue,
        );
      });

      test('returns cancellable subscription', () {
        final subscription = platform.onMessage('events', (_) {});

        expect(subscription, isNotNull);
        subscription.cancel();
      });
    });

    group('native callbacks', () {
      test('handles onStatusChange from native', () async {
        final statuses = <BeamVmStatus>[];
        platform.statusStream.listen(statuses.add);

        // Simulate native calling onStatusChange
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'io.beamvm/beam_vm',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onStatusChange', 'running'),
          ),
          (ByteData? data) {},
        );

        await Future.delayed(Duration.zero);

        expect(platform.status, equals(BeamVmStatus.running));
        expect(statuses, contains(BeamVmStatus.running));
      });

      test('handles onMessage from native', () async {
        final messages = <dynamic>[];
        platform.onMessage('events', messages.add);

        // Simulate native calling onMessage
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'io.beamvm/beam_vm',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall(
                'onMessage', {'tag': 'events', 'message': 'hello'}),
          ),
          (ByteData? data) {},
        );

        await Future.delayed(Duration.zero);

        expect(messages, contains('hello'));
      });

      test('dispatches to multiple callbacks for same tag', () async {
        final messages1 = <dynamic>[];
        final messages2 = <dynamic>[];

        platform.onMessage('events', messages1.add);
        platform.onMessage('events', messages2.add);

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'io.beamvm/beam_vm',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onMessage', {'tag': 'events', 'message': 'test'}),
          ),
          (ByteData? data) {},
        );

        await Future.delayed(Duration.zero);

        expect(messages1, contains('test'));
        expect(messages2, contains('test'));
      });
    });
  });
}
