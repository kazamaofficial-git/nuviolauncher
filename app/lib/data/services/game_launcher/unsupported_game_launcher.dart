import 'game_launcher.dart';

/// Used on platforms (Android in this beta) where launching is not available.
class UnsupportedGameLauncher implements GameLauncher {
  @override
  bool get isSupported => false;

  @override
  Stream<LaunchEvent> launch(LaunchRequest request) => Stream.value(
        LaunchEvent.failed('Game launching is not available on this platform yet.'),
      );

  @override
  Future<void> stop() async {}
}
