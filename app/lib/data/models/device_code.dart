/// A device-login challenge (Microsoft or Nuvio website).
class DeviceCode {
  const DeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresIn,
    required this.interval,
  });

  /// Opaque secret used for polling (never shown).
  final String deviceCode;

  /// Short code the user types/confirms in the browser.
  final String userCode;

  /// Page to open in the browser.
  final String verificationUrl;

  /// Lifetime in seconds.
  final int expiresIn;

  /// Minimum polling interval in seconds.
  final int interval;
}
