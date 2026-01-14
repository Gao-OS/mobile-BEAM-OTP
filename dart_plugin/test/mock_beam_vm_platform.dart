import 'dart:async';
import 'package:beam_vm/beam_vm.dart';
import 'package:beam_vm/beam_vm_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Record of a call() invocation.
class CallRecord {
  final String module;
  final String function;
  final List<dynamic> args;

  CallRecord(this.module, this.function, this.args);
}

/// Record of a send() invocation.
class SendRecord {
  final String processName;
  final dynamic message;

  SendRecord(this.processName, this.message);
}

/// Record of an onMessage() registration.
class OnMessageRecord {
  final String tag;
  final void Function(dynamic) callback;

  OnMessageRecord(this.tag, this.callback);
}

/// Mock implementation of [BeamVmPlatform] for testing.
class MockBeamVmPlatform extends BeamVmPlatform with MockPlatformInterfaceMixin {
  // Configuration
  bool initializeResult = true;
  BeamVmException? initializeError;
  dynamic callResult;
  BeamVmException? callError;
  BeamVmException? sendError;
  String mockOtpVersion = '28';
  BeamVmStatus mockStatus = BeamVmStatus.uninitialized;

  // Call tracking
  final List<String> initializeCalls = [];
  final List<CallRecord> callCalls = [];
  final List<SendRecord> sendCalls = [];
  final List<OnMessageRecord> onMessageCalls = [];
  bool shutdownCalled = false;

  // Status stream
  final _statusController = StreamController<BeamVmStatus>.broadcast();

  @override
  Stream<BeamVmStatus> get statusStream => _statusController.stream;

  @override
  BeamVmStatus get status => mockStatus;

  void emitStatus(BeamVmStatus status) {
    mockStatus = status;
    _statusController.add(status);
  }

  @override
  Future<bool> initialize(String erlangPath) async {
    initializeCalls.add(erlangPath);

    if (initializeError != null) {
      throw initializeError!;
    }

    if (initializeResult) {
      mockStatus = BeamVmStatus.running;
    } else {
      mockStatus = BeamVmStatus.error;
    }

    return initializeResult;
  }

  @override
  Future<dynamic> call(String module, String function, List<dynamic> args) async {
    callCalls.add(CallRecord(module, function, args));

    if (callError != null) {
      throw callError!;
    }

    return callResult;
  }

  @override
  Future<void> send(String processName, dynamic message) async {
    sendCalls.add(SendRecord(processName, message));

    if (sendError != null) {
      throw sendError!;
    }
  }

  @override
  StreamSubscription<dynamic> onMessage(
    String tag,
    void Function(dynamic message) callback,
  ) {
    onMessageCalls.add(OnMessageRecord(tag, callback));

    final controller = StreamController<dynamic>();
    return controller.stream.listen((_) {});
  }

  @override
  Future<void> shutdown() async {
    shutdownCalled = true;
    mockStatus = BeamVmStatus.uninitialized;
  }

  @override
  Future<String> get otpVersion async => mockOtpVersion;

  /// Simulate receiving a message from native side.
  void simulateMessage(String tag, dynamic message) {
    for (final record in onMessageCalls) {
      if (record.tag == tag) {
        record.callback(message);
      }
    }
  }

  /// Reset all tracking state.
  void reset() {
    initializeCalls.clear();
    callCalls.clear();
    sendCalls.clear();
    onMessageCalls.clear();
    shutdownCalled = false;
    mockStatus = BeamVmStatus.uninitialized;
    initializeResult = true;
    initializeError = null;
    callResult = null;
    callError = null;
    sendError = null;
  }
}
