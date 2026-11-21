import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../../core/network/gemini_http_client.dart';
import '../../domain/entities/detected_ingredient.dart';
import '../../domain/entities/ingredient.dart';
import '../models/gemini_interaction_models.dart';

/// Top-level helper for encoding image bytes on a background Dart isolate.
String encodeBase64InIsolate(Uint8List bytes) => base64Encode(bytes);

/// Semantic error categories produced by [AiVisionService].
enum AiVisionErrorType {
  emptyImage,
  missingApiKey,
  invalidApiKey,
  quotaExceeded,
  modelError,
  networkTimeout,
  networkUnavailable,
  invalidResponse,
}

/// Typed Indonesian exception thrown when AI ingredient scanning fails.
class AiVisionException implements Exception {
  const AiVisionException(
    this.message, {
    required this.type,
    this.cause,
  });

  final String message;
  final AiVisionErrorType type;
  final Object? cause;

  @override
  String toString() => 'AiVisionException(${type.name}): $message';
}

/// Callback signature abstracting raw Gemini Interactions execution for unit tests.
typedef GeminiVisionExecutor = Future<String?> Function({
  required String apiKey,
  required String model,
  required String thinkingLevel,
  required String systemInstruction,
  required String prompt,
  required Uint8List imageBytes,
  required String mimeType,
});

/// Callback signature abstracting DNS pre-flight checks for unit tests.
typedef DnsLookupExecutor = Future<List<InternetAddress>> Function(String host);

/// AI Computer Vision service powered by Google AI Studio's unified
/// **Gemini Interactions API** (`POST /v1beta/interactions`) with
/// `gemini-4-hydrogen` as the default model.
///
/// Uses non-persistent [Dio] HTTP connections (`Connection: close`,
/// `Accept-Encoding: identity`) and the `x-goog-api-key` header to prevent
/// Android Emulator keep-alive and gzip stream stalls.
class AiVisionService {
  AiVisionService({
    String? defaultApiKey,
    this.model = defaultModelName,
    this.thinkingLevel = defaultThinkingLevel,
    this.minConfidence = minConfidenceThreshold,
    this.simulationDelay = const Duration(milliseconds: 1200),
    this.connectTimeout = defaultConnectTimeout,
    this.receiveTimeout = defaultReceiveTimeout,
    this.dio,
    GeminiVisionExecutor? geminiExecutor,
    DnsLookupExecutor? dnsLookup,
  })  : _defaultApiKey = _sanitizeApiKey(defaultApiKey ?? _envGeminiApiKey),
        _customExecutor = geminiExecutor,
        _customDnsLookup = dnsLookup;

  static const String defaultModelName = ApiConfig.defaultGeminiModel;
  static const String defaultThinkingLevel = 'low';
  static const double minConfidenceThreshold = 0.70;
  static const int scanMaxOutputTokens = 2048;
  static const int pingMaxOutputTokens = 256;
  static const Duration defaultConnectTimeout =
      GeminiHttpClientFactory.defaultConnectTimeout;
  static const Duration defaultReceiveTimeout =
      GeminiHttpClientFactory.defaultReceiveTimeout;
  static const Duration defaultDnsLookupTimeout = Duration(seconds: 3);

  static const String _geminiHost = 'generativelanguage.googleapis.com';
  static const String _offlineEmulatorMessage =
      'Emulator tidak terhubung ke internet. Matikan lalu nyalakan ulang Wi-Fi di emulator.';

  static const String _strictSystemInstruction =
      'You are PantryKos Vision AI, a strict visual food-ingredient detector '
      'for Indonesian boarding-house (anak kos) fridges and kitchens. '
      'Only report food ingredients that are genuinely and clearly visible in '
      'the photo, mapped strictly to the allowed ingredient IDs provided by '
      'the user. Never guess or hallucinate ingredients. If no recognizable '
      'food is visible, return {"ingredients":[]}.';

  static const String _envGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  static const List<({String id, String fallbackName, double confidence})>
      _simulatedDefaults = [
    (id: 'telur', fallbackName: 'Telur Ayam', confidence: 0.98),
    (id: 'mie_instan', fallbackName: 'Mie Instan', confidence: 0.96),
    (id: 'sosis', fallbackName: 'Sosis', confidence: 0.93),
  ];

  final String _defaultApiKey;
  final String model;
  final String thinkingLevel;
  final double minConfidence;
  final Duration simulationDelay;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Dio? dio;
  final GeminiVisionExecutor? _customExecutor;
  final DnsLookupExecutor? _customDnsLookup;

  /// Strips all whitespace/newlines from pasted API keys (`AQ.` or `AIza...`).
  static String _sanitizeApiKey(String rawKey) =>
      rawKey.replaceAll(RegExp(r'\s+'), '');

  Dio _resolveDioClient() {
    return dio ??
        GeminiHttpClientFactory.create(
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        );
  }

  Future<void> _ensureGeminiReachable() async {
    final DnsLookupExecutor? lookupFn =
        _customDnsLookup ?? (dio == null ? InternetAddress.lookup : null);
    if (lookupFn == null) return;

    try {
      final addresses = await lookupFn(_geminiHost).timeout(
        defaultDnsLookupTimeout,
      );
      if (addresses.isEmpty) {
        throw const AiVisionException(
          _offlineEmulatorMessage,
          type: AiVisionErrorType.networkUnavailable,
        );
      }
    } on AiVisionException {
      rethrow;
    } catch (e) {
      throw AiVisionException(
        _offlineEmulatorMessage,
        type: AiVisionErrorType.networkUnavailable,
        cause: e,
      );
    }
  }

  /// Runs a 3-second pre-flight DNS/internet check and sends a lightweight
  /// Interactions API JSON ping to [model] using [apiKey] in the
  /// `'x-goog-api-key'` header, returning round-trip latency in milliseconds.
  Future<int> testConnection({
    String? apiKey,
    String? model,
    String? modelName,
  }) async {
    final cleanKey = _sanitizeApiKey(apiKey ?? '');
    final effectiveApiKey = cleanKey.isNotEmpty ? cleanKey : _defaultApiKey;

    if (effectiveApiKey.isEmpty) {
      throw const AiVisionException(
        'API Key belum diisi. Masukkan API Key Gemini terlebih dahulu.',
        type: AiVisionErrorType.missingApiKey,
      );
    }

    await _ensureGeminiReachable();

    final requestedModel = model ?? modelName;
    final effectiveModel =
        (requestedModel != null && requestedModel.trim().isNotEmpty)
            ? requestedModel.trim()
            : this.model;

    final client = _resolveDioClient();
    final request = GeminiInteractionRequest.connectionPing(
      model: effectiveModel,
      thinkingLevel: thinkingLevel,
      maxOutputTokens: pingMaxOutputTokens,
    );

    final stopwatch = Stopwatch()..start();
    try {
      final response = await client.post<dynamic>(
        ApiConfig.geminiInteractionsEndpoint,
        data: request.toJson(),
        options: GeminiHttpClientFactory.requestOptions(
          apiKey: effectiveApiKey,
          sendTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
        ),
      );
      stopwatch.stop();

      final parsed = _parseInteractionBody(response.data);
      if (parsed.isFailed) {
        throw AiVisionException(
          'Server AI menolak permintaan: ${parsed.errorMessage ?? parsed.status}',
          type: AiVisionErrorType.invalidResponse,
        );
      }
      return stopwatch.elapsedMilliseconds;
    } on AiVisionException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e, effectiveModel);
    } on SocketException catch (e) {
      throw AiVisionException(
        'SocketException: ${e.osError?.message ?? e.message}',
        type: AiVisionErrorType.networkUnavailable,
        cause: e,
      );
    } on HttpException catch (e) {
      throw AiVisionException(
        'HttpException: ${e.message}',
        type: AiVisionErrorType.networkUnavailable,
        cause: e,
      );
    } catch (e) {
      throw AiVisionException(
        'Tes koneksi gagal: $e',
        type: AiVisionErrorType.networkUnavailable,
        cause: e,
      );
    }
  }

  /// Primary method called by `ScannerUiScreen` to analyze [imageBytes].
  Future<List<DetectedIngredient>> analyzeImage({
    required Uint8List imageBytes,
    required List<Ingredient> masterIngredients,
    String? apiKey,
    String? modelName,
    bool useOfflineSimulation = false,
    String mimeType = 'image/jpeg',
    String? preEncodedBase64,
  }) {
    return detectIngredients(
      imageBytes: imageBytes,
      masterIngredients: masterIngredients,
      apiKey: apiKey,
      modelName: modelName,
      useOfflineSimulation: useOfflineSimulation,
      mimeType: mimeType,
      preEncodedBase64: preEncodedBase64,
    );
  }

  /// Analyzes [imageBytes] via the Gemini Interactions API and returns strictly
  /// validated, deduplicated [DetectedIngredient] items whose `id` exists in
  /// [masterIngredients] and whose `confidence >= 0.70`.
  ///
  /// Returns an empty list (`[]`) when no recognizable food is visible.
  /// Throws [AiVisionException] with exact diagnostics on error.
  Future<List<DetectedIngredient>> detectIngredients({
    required Uint8List imageBytes,
    required List<Ingredient> masterIngredients,
    String? apiKey,
    String? modelName,
    bool useOfflineSimulation = false,
    String mimeType = 'image/jpeg',
    String? preEncodedBase64,
  }) async {
    if (useOfflineSimulation) {
      return _runExplicitOfflineSimulation(masterIngredients);
    }

    if (imageBytes.isEmpty) {
      throw const AiVisionException(
        'Foto tidak terbaca atau kosong. Silakan ambil ulang foto bahan.',
        type: AiVisionErrorType.emptyImage,
      );
    }

    final cleanKey = _sanitizeApiKey(apiKey ?? '');
    final effectiveApiKey = cleanKey.isNotEmpty ? cleanKey : _defaultApiKey;

    if (effectiveApiKey.isEmpty) {
      throw const AiVisionException(
        'API Key belum diisi. Masukkan API Key di menu Pengaturan.',
        type: AiVisionErrorType.missingApiKey,
      );
    }

    final effectiveModel =
        (modelName != null && modelName.trim().isNotEmpty)
            ? modelName.trim()
            : model;
    final prompt = buildStrictVisionPrompt(masterIngredients);

    try {
      final String? rawText;
      if (_customExecutor != null) {
        rawText = await _customExecutor(
          apiKey: effectiveApiKey,
          model: effectiveModel,
          thinkingLevel: thinkingLevel,
          systemInstruction: _strictSystemInstruction,
          prompt: prompt,
          imageBytes: imageBytes,
          mimeType: mimeType,
        ).timeout(receiveTimeout);
      } else {
        final encodedImage =
            (preEncodedBase64 != null && preEncodedBase64.isNotEmpty)
                ? preEncodedBase64
                : await compute(encodeBase64InIsolate, imageBytes);
        rawText = await _executeInteractionViaDio(
          cleanKey: effectiveApiKey,
          model: effectiveModel,
          prompt: prompt,
          base64Image: encodedImage,
          mimeType: mimeType,
        );
      }

      return _parseAndFilterDetections(
        rawText: rawText,
        masterIngredients: masterIngredients,
      );
    } on AiVisionException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e, effectiveModel);
    } on TimeoutException catch (e) {
      throw AiVisionException(
        'Koneksi timeout (${receiveTimeout.inSeconds}d): ${e.message ?? 'Server AI tidak merespons tepat waktu.'}',
        type: AiVisionErrorType.networkTimeout,
        cause: e,
      );
    } on SocketException catch (e) {
      throw AiVisionException(
        'Koneksi jaringan gagal: ${e.osError?.message ?? e.message}',
        type: AiVisionErrorType.networkUnavailable,
        cause: e,
      );
    } on HttpException catch (e) {
      throw AiVisionException(
        'HttpException: ${e.message}',
        type: AiVisionErrorType.networkUnavailable,
        cause: e,
      );
    } catch (e) {
      throw AiVisionException(
        'Error AI Vision (${e.runtimeType}): $e',
        type: AiVisionErrorType.invalidResponse,
        cause: e,
      );
    }
  }

  /// Ultra-compact `id: aliases` prompt minimizing input tokens while detecting
  /// cluttered fridge shelves, door racks, plastic bags, and bottles accurately.
  String buildStrictVisionPrompt(List<Ingredient> masterIngredients) {
    final compactMap = masterIngredients
        .map((ing) {
          final aliases = ing.aliases.isEmpty
              ? ing.name
              : '${ing.name}, ${ing.aliases.join(', ')}';
          return '${ing.id}: $aliases';
        })
        .join('\n');

    return 'Detect all visible food ingredients across fridge shelves, door racks, bags & bottles.\n'
        'Allowed map (id: aliases):\n'
        '$compactMap\n'
        'Rules: Match only genuinely visible food to allowed IDs (confidence >= 0.70), deduplicated.\n'
        'If NO food is visible, return {"ingredients":[]}.\n'
        'Return ONLY JSON matching: {"ingredients":[{"id":"telur","name":"Telur Ayam","confidence":0.96}]}';
  }

  Future<String?> _executeInteractionViaDio({
    required String cleanKey,
    required String model,
    required String prompt,
    required String base64Image,
    required String mimeType,
  }) async {
    final client = _resolveDioClient();
    final request = GeminiInteractionRequest.visionScan(
      model: model,
      systemInstruction: _strictSystemInstruction,
      prompt: prompt,
      base64Image: base64Image,
      mimeType: mimeType,
      thinkingLevel: thinkingLevel,
      maxOutputTokens: scanMaxOutputTokens,
    );

    final response = await client.post<dynamic>(
      ApiConfig.geminiInteractionsEndpoint,
      data: request.toJson(),
      options: GeminiHttpClientFactory.requestOptions(
        apiKey: cleanKey,
        sendTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );

    final parsed = _parseInteractionBody(response.data);
    if (parsed.isFailed) {
      throw AiVisionException(
        'Analisis AI gagal: ${parsed.errorMessage ?? parsed.status}',
        type: AiVisionErrorType.invalidResponse,
      );
    }
    if (parsed.isIncomplete && parsed.outputText.trim().isEmpty) {
      throw const AiVisionException(
        'Respon AI terpotong sebelum selesai. Silakan coba pindai ulang.',
        type: AiVisionErrorType.invalidResponse,
      );
    }

    return parsed.outputText;
  }

  GeminiInteractionResponse _parseInteractionBody(dynamic rawData) {
    final Map<String, dynamic> body;
    if (rawData is Map<String, dynamic>) {
      body = rawData;
    } else if (rawData is Map) {
      body = rawData.cast<String, dynamic>();
    } else if (rawData is String && rawData.trim().isNotEmpty) {
      final decoded = jsonDecode(rawData);
      if (decoded is! Map) {
        throw const AiVisionException(
          'Format respon server AI tidak sesuai (bukan JSON object).',
          type: AiVisionErrorType.invalidResponse,
        );
      }
      body = decoded.cast<String, dynamic>();
    } else {
      throw const AiVisionException(
        'Respon server AI kosong.',
        type: AiVisionErrorType.invalidResponse,
      );
    }

    return GeminiInteractionResponse.fromJson(body);
  }

  AiVisionException _mapDioException(DioException e, String effectiveModel) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return AiVisionException(
          'Connect timeout (${connectTimeout.inSeconds}d): ${e.message ?? 'Gagal membuka koneksi ke server AI.'}',
          type: AiVisionErrorType.networkTimeout,
          cause: e,
        );
      case DioExceptionType.sendTimeout:
        return AiVisionException(
          'Send timeout (${connectTimeout.inSeconds}d): ${e.message ?? 'Gagal mengunggah gambar ke server AI.'}',
          type: AiVisionErrorType.networkTimeout,
          cause: e,
        );
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AiVisionException(
          'Receive timeout (${receiveTimeout.inSeconds}d): ${e.message ?? 'Server AI terlambat merespons.'}',
          type: AiVisionErrorType.networkTimeout,
          cause: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final serverMsg = _extractServerErrorMessage(e.response?.data);
        final lowerMsg = (serverMsg ?? '').toLowerCase();

        if (statusCode == 401 ||
            statusCode == 403 ||
            (statusCode == 400 && _looksLikeApiKeyError(lowerMsg))) {
          return AiVisionException(
            'API Key tidak valid ($statusCode)${serverMsg != null ? ': $serverMsg' : ''}',
            type: AiVisionErrorType.invalidApiKey,
            cause: e,
          );
        }

        if (statusCode == 429) {
          return AiVisionException(
            'Kuota API habis (429)${serverMsg != null ? ': $serverMsg' : ''}',
            type: AiVisionErrorType.quotaExceeded,
            cause: e,
          );
        }

        if (statusCode == 404 || _looksLikeModelError(lowerMsg)) {
          return AiVisionException(
            'Model "$effectiveModel" error ($statusCode)${serverMsg != null ? ': $serverMsg' : ''}',
            type: AiVisionErrorType.modelError,
            cause: e,
          );
        }

        return AiVisionException(
          'HTTP $statusCode: ${serverMsg ?? e.message ?? 'Permintaan ditolak server AI.'}',
          type: AiVisionErrorType.invalidResponse,
          cause: e,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final underlying = e.error;
        if (underlying is SocketException) {
          return AiVisionException(
            'SocketException: ${underlying.osError?.message ?? underlying.message}',
            type: AiVisionErrorType.networkUnavailable,
            cause: e,
          );
        }
        if (underlying is HttpException) {
          return AiVisionException(
            'HttpException: ${underlying.message}',
            type: AiVisionErrorType.networkUnavailable,
            cause: e,
          );
        }
        return AiVisionException(
          'Koneksi gagal: ${underlying ?? e.message ?? e.type.name}',
          type: AiVisionErrorType.networkUnavailable,
          cause: e,
        );
      case DioExceptionType.cancel:
        return AiVisionException(
          'Permintaan AI dibatalkan (${e.message ?? 'cancelled'}).',
          type: AiVisionErrorType.networkUnavailable,
          cause: e,
        );
      case DioExceptionType.badCertificate:
        return AiVisionException(
          'Sertifikat SSL tidak valid: ${e.message ?? e.error ?? ''}',
          type: AiVisionErrorType.networkUnavailable,
          cause: e,
        );
    }
  }

  static bool _looksLikeApiKeyError(String lowerMsg) {
    return lowerMsg.contains('api key') ||
        lowerMsg.contains('api_key') ||
        lowerMsg.contains('permission') ||
        lowerMsg.contains('unauthorized') ||
        lowerMsg.contains('unauthenticated') ||
        lowerMsg.contains('key expired');
  }

  static bool _looksLikeModelError(String lowerMsg) {
    return lowerMsg.contains('model') ||
        lowerMsg.contains('not found') ||
        lowerMsg.contains('no longer available') ||
        lowerMsg.contains('deprecated') ||
        lowerMsg.contains('unsupported') ||
        lowerMsg.contains('not supported');
  }

  static String? _extractServerErrorMessage(dynamic rawData) {
    try {
      dynamic decoded = rawData;
      if (decoded is String && decoded.trim().isNotEmpty) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is Map) {
        final errorObj = decoded['error'];
        if (errorObj is Map) {
          final msg = errorObj['message']?.toString().trim();
          final status = errorObj['status']?.toString().trim();
          if (msg != null && msg.isNotEmpty) {
            return status != null && status.isNotEmpty ? '$status: $msg' : msg;
          }
          if (status != null && status.isNotEmpty) return status;
        }
        final topMsg = decoded['message']?.toString().trim();
        if (topMsg != null && topMsg.isNotEmpty) return topMsg;
      }
    } catch (_) {
      if (rawData is String && rawData.trim().isNotEmpty) {
        return rawData.trim();
      }
    }
    return null;
  }

  Future<List<DetectedIngredient>> _runExplicitOfflineSimulation(
    List<Ingredient> masterIngredients,
  ) async {
    await Future<void>.delayed(simulationDelay);

    final byId = <String, Ingredient>{
      for (final ing in masterIngredients) ing.id: ing,
    };

    final results = <DetectedIngredient>[];
    for (final item in _simulatedDefaults) {
      final matched = byId[item.id];
      if (matched != null) {
        results.add(
          DetectedIngredient(
            ingredientId: matched.id,
            detectedName: matched.name,
            confidence: item.confidence,
            isMatchedToDatabase: true,
          ),
        );
      } else if (byId.isEmpty) {
        results.add(
          DetectedIngredient(
            ingredientId: item.id,
            detectedName: item.fallbackName,
            confidence: item.confidence,
            isMatchedToDatabase: false,
          ),
        );
      }
    }

    return List<DetectedIngredient>.unmodifiable(results);
  }

  List<DetectedIngredient> _parseAndFilterDetections({
    required String? rawText,
    required List<Ingredient> masterIngredients,
  }) {
    if (rawText == null || rawText.trim().isEmpty) {
      return const <DetectedIngredient>[];
    }

    final cleaned = _stripMarkdownFences(rawText);
    final dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } on FormatException catch (e) {
      throw AiVisionException(
        'Respon server AI tidak berformat JSON valid: ${e.message}',
        type: AiVisionErrorType.invalidResponse,
        cause: e,
      );
    }

    final List<dynamic> rawList;
    if (decoded is List<dynamic>) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final nested =
          decoded['ingredients'] ??
          decoded['detected_ingredients'] ??
          decoded['items'] ??
          decoded['results'];
      if (nested is List<dynamic>) {
        rawList = nested;
      } else {
        throw const AiVisionException(
          'Format respon JSON dari server AI tidak sesuai skema.',
          type: AiVisionErrorType.invalidResponse,
        );
      }
    } else {
      throw const AiVisionException(
        'Format respon JSON dari server AI tidak sesuai skema array.',
        type: AiVisionErrorType.invalidResponse,
      );
    }

    final byId = <String, Ingredient>{
      for (final ing in masterIngredients) ing.id.trim(): ing,
    };
    final byLowerId = <String, Ingredient>{
      for (final ing in masterIngredients) ing.id.trim().toLowerCase(): ing,
    };

    final dedupedById = <String, DetectedIngredient>{};

    for (final entry in rawList) {
      if (entry is! Map) continue;
      final id = (entry['id'] ?? entry['ingredient_id'] ?? '')
          .toString()
          .trim();
      if (id.isEmpty) continue;

      final master = byId[id] ?? byLowerId[id.toLowerCase()];
      if (master == null) {
        continue;
      }

      final rawConfidence = entry['confidence'];
      final parsedConfidence = rawConfidence is num
          ? rawConfidence.toDouble()
          : double.tryParse(rawConfidence?.toString() ?? '');
      if (parsedConfidence == null) continue;

      final clampedConfidence = parsedConfidence.clamp(0.0, 1.0).toDouble();
      if (clampedConfidence < minConfidence) {
        continue;
      }

      final rawName =
          (entry['name'] ?? entry['detected_name'] ?? master.name)
              .toString()
              .trim();

      final candidate = DetectedIngredient(
        ingredientId: master.id,
        detectedName: rawName.isEmpty ? master.name : rawName,
        confidence: clampedConfidence,
        isMatchedToDatabase: true,
      );

      final existing = dedupedById[master.id];
      if (existing == null || candidate.confidence > existing.confidence) {
        dedupedById[master.id] = candidate;
      }
    }

    if (dedupedById.isEmpty) {
      return const <DetectedIngredient>[];
    }

    final sorted = dedupedById.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return List<DetectedIngredient>.unmodifiable(sorted);
  }

  static String _stripMarkdownFences(String raw) {
    var trimmed = raw.trim();
    if (trimmed.startsWith('```')) {
      final firstNewline = trimmed.indexOf('\n');
      if (firstNewline != -1) {
        trimmed = trimmed.substring(firstNewline + 1);
      }
      if (trimmed.endsWith('```')) {
        trimmed = trimmed.substring(0, trimmed.length - 3);
      }
    }
    return trimmed.trim();
  }
}
