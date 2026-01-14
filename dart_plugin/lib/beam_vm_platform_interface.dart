import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'beam_vm_method_channel.dart';

/// Status of the BEAM VM.
enum BeamVmStatus {
  /// VM has not been initialized.
  uninitialized,

  /// VM is currently initializing.
  initializing,

  /// VM is running and ready to accept commands.
  running,

  /// VM encountered an error.
  error,

  /// VM is shutting down.
  shuttingDown,
}

/// Platform interface for BEAM VM operations.
///
/// Platform-specific implementations should extend this class.
abstract class BeamVmPlatform extends PlatformInterface {
  BeamVmPlatform() : super(token: _token);

  static final Object _token = Object();

  static BeamVmPlatform _instance = MethodChannelBeamVm();

  /// The default instance of [BeamVmPlatform] to use.
  static BeamVmPlatform get instance => _instance;

  /// Platform-specific implementations should set this to their own
  /// platform-specific class that extends [BeamVmPlatform].
  static set instance(BeamVmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of VM status changes.
  Stream<BeamVmStatus> get statusStream;

  /// Current VM status.
  BeamVmStatus get status;

  /// Initialize the BEAM VM.
  Future<bool> initialize(String erlangPath);

  /// Call an Erlang/Elixir function.
  Future<dynamic> call(String module, String function, List<dynamic> args);

  /// Send a message to a named process.
  Future<void> send(String processName, dynamic message);

  /// Register a message callback.
  StreamSubscription<dynamic> onMessage(
    String tag,
    void Function(dynamic message) callback,
  );

  /// Shutdown the VM.
  Future<void> shutdown();

  /// Get OTP version.
  Future<String> get otpVersion;
}
