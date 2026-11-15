import '../../../core/constants/app_constants.dart';
import '../../models/instance.dart';
import '../../models/launch_auth.dart';
import '../../models/mc_version.dart';

/// Everything a launcher needs to start one instance.
class LaunchRequest {
  const LaunchRequest({
    required this.instance,
    required this.version,
    required this.auth,
    required this.gameRoot,
    this.javaPath,
    this.downloadThreads = AppConstants.freeDownloadThreads,
  });

  final Instance instance;
  final McVersion version;
  /// Credentials of the selected account (see AccountsController.prepareForLaunch).
  final LaunchAuth auth;

  /// Root folder holding `versions/`, `libraries/`, `assets/` and `instances/`.
  final String gameRoot;

  /// Custom Java executable, or null to auto-detect.
  final String? javaPath;

  /// Number of parallel download workers (higher with Nuvio Plus).
  final int downloadThreads;
}

enum LaunchPhase { preparing, downloading, launching, running, finished, failed }

/// A progress, log or state-change event emitted while launching.
class LaunchEvent {
  const LaunchEvent._(this.phase, this.message, {this.progress, this.isLog = false, this.exitCode});

  factory LaunchEvent.status(LaunchPhase phase, String message, {double? progress}) =>
      LaunchEvent._(phase, message, progress: progress);

  factory LaunchEvent.log(String line) =>
      LaunchEvent._(LaunchPhase.running, line, isLog: true);

  factory LaunchEvent.finished(int exitCode) => LaunchEvent._(
        LaunchPhase.finished,
        exitCode == 0 ? 'Game closed.' : 'Game exited with code $exitCode.',
        exitCode: exitCode,
      );

  factory LaunchEvent.failed(String message) => LaunchEvent._(LaunchPhase.failed, message);

  final LaunchPhase phase;
  final String message;

  /// 0..1 while downloading, otherwise null.
  final double? progress;
  final bool isLog;
  final int? exitCode;
}

/// A user-facing launch error.
class LaunchException implements Exception {
  const LaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Starts (and stops) the game for an instance.
abstract class GameLauncher {
  /// False on platforms where launching is not implemented yet.
  bool get isSupported;

  /// Emits events until the game has exited or the launch failed.
  Stream<LaunchEvent> launch(LaunchRequest request);

  /// Cancels the current launch or kills the running game.
  Future<void> stop();
}
