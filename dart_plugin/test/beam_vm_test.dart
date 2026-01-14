import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:beam_vm/beam_vm.dart';
import 'package:beam_vm/beam_vm_platform_interface.dart';

import 'mock_beam_vm_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBeamVmPlatform mockPlatform;
  late BeamVm beamVm;

  setUp(() {
    mockPlatform = MockBeamVmPlatform();
    BeamVmPlatform.instance = mockPlatform;
    beamVm = BeamVm();
  });

  group('BeamVm', () {
    test('is a singleton', () {
      final vm1 = BeamVm();
      final vm2 = BeamVm();
      expect(identical(vm1, vm2), isTrue);
    });

    test('initial status is uninitialized', () {
      expect(beamVm.status, equals(BeamVmStatus.uninitialized));
      expect(beamVm.isInitialized, isFalse);
    });

    group('initialize', () {
      test('returns true on success', () async {
        mockPlatform.initializeResult = true;

        final result = await beamVm.initialize('/path/to/erlang');

        expect(result, isTrue);
        expect(mockPlatform.initializeCalls, equals(['/path/to/erlang']));
      });

      test('returns false on failure', () async {
        mockPlatform.initializeResult = false;

        final result = await beamVm.initialize('/invalid/path');

        expect(result, isFalse);
      });

      test('throws BeamVmException on error', () async {
        mockPlatform.initializeError = BeamVmException(
          'Init failed',
          code: 'INIT_ERROR',
        );

        expect(
          () => beamVm.initialize('/path'),
          throwsA(isA<BeamVmException>()),
        );
      });
    });

    group('isInitialized', () {
      test('returns true when status is running', () {
        mockPlatform.mockStatus = BeamVmStatus.running;
        expect(beamVm.isInitialized, isTrue);
      });

      test('returns false when status is not running', () {
        mockPlatform.mockStatus = BeamVmStatus.uninitialized;
        expect(beamVm.isInitialized, isFalse);

        mockPlatform.mockStatus = BeamVmStatus.initializing;
        expect(beamVm.isInitialized, isFalse);

        mockPlatform.mockStatus = BeamVmStatus.error;
        expect(beamVm.isInitialized, isFalse);

        mockPlatform.mockStatus = BeamVmStatus.shuttingDown;
        expect(beamVm.isInitialized, isFalse);
      });
    });

    group('call', () {
      test('forwards call to platform', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;
        mockPlatform.callResult = 42;

        final result = await beamVm.call('Elixir.Math', 'add', [1, 2]);

        expect(result, equals(42));
        expect(mockPlatform.callCalls.length, equals(1));
        expect(mockPlatform.callCalls.first.module, equals('Elixir.Math'));
        expect(mockPlatform.callCalls.first.function, equals('add'));
        expect(mockPlatform.callCalls.first.args, equals([1, 2]));
      });

      test('returns complex results', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;
        mockPlatform.callResult = {'name': 'Alice', 'age': 30};

        final result = await beamVm.call('Elixir.User', 'get', [1]);

        expect(result, isA<Map>());
        expect(result['name'], equals('Alice'));
        expect(result['age'], equals(30));
      });
    });

    group('send', () {
      test('forwards send to platform', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;

        await beamVm.send('MyProcess', {'type': 'ping'});

        expect(mockPlatform.sendCalls.length, equals(1));
        expect(mockPlatform.sendCalls.first.processName, equals('MyProcess'));
        expect(mockPlatform.sendCalls.first.message, equals({'type': 'ping'}));
      });
    });

    group('onMessage', () {
      test('registers callback and returns subscription', () {
        final messages = <dynamic>[];
        final subscription = beamVm.onMessage('events', messages.add);

        expect(subscription, isA<StreamSubscription>());
        expect(mockPlatform.onMessageCalls.length, equals(1));
        expect(mockPlatform.onMessageCalls.first.tag, equals('events'));

        subscription.cancel();
      });
    });

    group('shutdown', () {
      test('calls platform shutdown', () async {
        mockPlatform.mockStatus = BeamVmStatus.running;

        await beamVm.shutdown();

        expect(mockPlatform.shutdownCalled, isTrue);
      });
    });

    group('otpVersion', () {
      test('returns version from platform', () async {
        mockPlatform.mockOtpVersion = '28.3';

        final version = await beamVm.otpVersion;

        expect(version, equals('28.3'));
      });
    });

    group('statusStream', () {
      test('emits status changes', () async {
        final statuses = <BeamVmStatus>[];
        final subscription = beamVm.statusStream.listen(statuses.add);

        mockPlatform.emitStatus(BeamVmStatus.initializing);
        mockPlatform.emitStatus(BeamVmStatus.running);

        await Future.delayed(Duration.zero);

        expect(statuses, contains(BeamVmStatus.initializing));
        expect(statuses, contains(BeamVmStatus.running));

        await subscription.cancel();
      });
    });
  });

  group('BeamVmException', () {
    test('toString includes message', () {
      final exception = BeamVmException('Test error');
      expect(exception.toString(), equals('BeamVmException: Test error'));
    });

    test('toString includes code when present', () {
      final exception = BeamVmException('Test error', code: 'ERR_001');
      expect(
        exception.toString(),
        equals('BeamVmException: Test error (ERR_001)'),
      );
    });

    test('stores details', () {
      final exception = BeamVmException(
        'Test error',
        code: 'ERR_001',
        details: {'key': 'value'},
      );
      expect(exception.details, equals({'key': 'value'}));
    });
  });
}
