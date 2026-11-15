/// Central runtime API configuration for PantryKos remote catalog & AI endpoints.
/// Supports runtime URL overrides from the Info/Settings sheet.
class ApiConfig {
  ApiConfig({String? initialRemoteJsonUrl})
      : _remoteJsonUrl = (initialRemoteJsonUrl != null &&
                initialRemoteJsonUrl.trim().isNotEmpty)
            ? initialRemoteJsonUrl.trim()
            : defaultRemoteJsonUrl;

  /// Default remote JSON catalog hosted on the PantryKos GitHub repository.
  static const String defaultRemoteJsonUrl =
      'https://raw.githubusercontent.com/gammaestu/pantrykos_mobile/main/assets/data/pantrykos_db.json';

  /// Default Laravel AI backend base URL (Android emulator localhost).
  static const String defaultLaravelBaseUrl = 'http://10.0.2.2:8000/api';

  /// Connect & receive timeout enforced across Dio HTTP requests.
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 8);

  String _remoteJsonUrl;
  String _laravelBaseUrl = defaultLaravelBaseUrl;

  String get remoteJsonUrl => _remoteJsonUrl;
  String get laravelBaseUrl => _laravelBaseUrl;

  /// Updates [remoteJsonUrl] at runtime when a non-empty valid URL is provided.
  void updateRemoteJsonUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    _remoteJsonUrl = trimmed;
  }

  /// Updates [laravelBaseUrl] at runtime from the Info/Settings sheet.
  void updateLaravelBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    _laravelBaseUrl = trimmed;
  }

  /// Resets runtime URLs back to defaults.
  void resetToDefaults() {
    _remoteJsonUrl = defaultRemoteJsonUrl;
    _laravelBaseUrl = defaultLaravelBaseUrl;
  }
}
