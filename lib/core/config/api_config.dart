/// Central runtime API configuration for PantryKos remote catalog & Gemini
/// REST API endpoints.
class ApiConfig {
  ApiConfig({String? initialRemoteJsonUrl})
      : _remoteJsonUrl = (initialRemoteJsonUrl != null &&
                initialRemoteJsonUrl.trim().isNotEmpty)
            ? initialRemoteJsonUrl.trim()
            : defaultRemoteJsonUrl;

  /// Default remote JSON catalog hosted on the PantryKos GitHub repository.
  static const String defaultRemoteJsonUrl ='';
      // 'https://raw.githubusercontent.com/gammaestu/pantrykos_mobile/main/assets/data/pantrykos_db.json'

  /// Default Laravel AI backend base URL (unused in standalone mobile mode).
  static const String defaultLaravelBaseUrl = 'http://192.168.1.2:8000/api';

  /// Official Google AI Studio REST API base URL.
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Legacy alias kept for backward compatibility if referenced elsewhere.
  static const String geminiInteractionsEndpoint = geminiBaseUrl;

  /// Builds the official `:generateContent` REST endpoint for [model].
  static String geminiGenerateContentUrl(String model) {
    final cleanModel = model.replaceFirst('models/', '').trim();
    return '$geminiBaseUrl/$cleanModel:generateContent';
  }

  /// Recommended fast, free/paid-tier multimodal default model verified in AI Studio.
  static const String defaultGeminiModel = 'gemini-3.5-flash-lite';

  /// Preset Gemini models surfaced in the Info & AI Settings sheet.
  static const List<String> supportedGeminiModels = <String>[
    defaultGeminiModel,
    'gemini-3.5-flash',
    'gemini-3.8-flash',
    'gemini-2.5-flash',
  ];

  /// Obsolete or invalid model identifiers automatically migrated on startup.
  static const Set<String> legacyGeminiModels = <String>{
    'gemini-4-hydrogen',
    'gemini-4-neon',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
  };

  /// Connect & receive timeout enforced across remote catalog Dio requests.
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 8);

  String _remoteJsonUrl;
  String _laravelBaseUrl = defaultLaravelBaseUrl;
  String _geminiModel = defaultGeminiModel;

  String get remoteJsonUrl => _remoteJsonUrl;
  String get laravelBaseUrl => _laravelBaseUrl;
  String get geminiModel => _geminiModel;

  /// Returns the `:generateContent` REST endpoint for the active model.
  String geminiInteractionsUrl() => geminiGenerateContentUrl(_geminiModel);

  /// Normalizes persisted model identifiers, migrating legacy/broken models
  /// to [defaultGeminiModel].
  static String normalizeGeminiModel(String? rawModel) {
    final trimmed = (rawModel ?? '').trim();
    if (trimmed.isEmpty || legacyGeminiModels.contains(trimmed.toLowerCase())) {
      return defaultGeminiModel;
    }
    return trimmed;
  }

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

  /// Updates [geminiModel] at runtime from the Info/Settings sheet.
  void updateGeminiModel(String model) {
    final trimmed = model.trim();
    if (trimmed.isEmpty) return;
    _geminiModel = trimmed;
  }

  /// Resets runtime URLs and model back to defaults.
  void resetToDefaults() {
    _remoteJsonUrl = defaultRemoteJsonUrl;
    _laravelBaseUrl = defaultLaravelBaseUrl;
    _geminiModel = defaultGeminiModel;
  }
}