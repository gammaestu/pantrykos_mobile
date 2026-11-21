import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/core/config/api_config.dart';
import 'package:pantrykos_mobile/data/models/recipe_model.dart';
import 'package:pantrykos_mobile/data/services/ai_vision_service.dart';
import 'package:pantrykos_mobile/domain/entities/ingredient.dart';

void main() {
  late List<Ingredient> masterIngredients;
  final sampleBytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]);

  setUpAll(() {
    final raw = File('assets/data/pantrykos_db.json').readAsStringSync();
    masterIngredients = PantryCatalogBundle.fromRawJson(raw).ingredients;
  });

  group('AiVisionService (Gemini Interactions API)', () {
    test(
      'uses gemini-4-hydrogen, Interactions API schema, low thinking, and filters <0.70 & unknown IDs',
      () async {
        String? capturedPrompt;
        String? capturedSystemInstruction;
        String? capturedKey;
        String? capturedModel;
        String? capturedThinkingLevel;

        final service = AiVisionService(
          simulationDelay: Duration.zero,
          geminiExecutor: ({
            required String apiKey,
            required String model,
            required String thinkingLevel,
            required String systemInstruction,
            required String prompt,
            required Uint8List imageBytes,
            required String mimeType,
          }) async {
            capturedKey = apiKey;
            capturedModel = model;
            capturedThinkingLevel = thinkingLevel;
            capturedSystemInstruction = systemInstruction;
            capturedPrompt = prompt;
            return jsonEncode(<String, dynamic>{
              'ingredients': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'telur',
                  'name': 'Telur Ayam Negeri',
                  'confidence': 0.91,
                },
                <String, dynamic>{
                  'id': 'telur',
                  'name': 'Telur Ayam',
                  'confidence': 0.98,
                },
                <String, dynamic>{
                  'id': 'mie_instan',
                  'name': 'Indomie Goreng',
                  'confidence': 0.82,
                },
                <String, dynamic>{
                  'id': 'sosis',
                  'name': 'Sosis (Tebakan Lemah)',
                  'confidence': 0.69, // Must be dropped (< 0.70)
                },
                <String, dynamic>{
                  'id': 'bahan_fiktif_tidak_ada',
                  'name': 'Caviar',
                  'confidence': 0.99, // Must be dropped (unknown DB ID)
                },
              ],
            });
          },
        );

        final detections = await service.analyzeImage(
          imageBytes: sampleBytes,
          masterIngredients: masterIngredients,
          apiKey: 'demo-gemini-key',
        );

        expect(capturedKey, 'demo-gemini-key');
        expect(AiVisionService.defaultModelName, 'gemini-4-hydrogen');
        expect(capturedModel, 'gemini-4-hydrogen');
        expect(capturedThinkingLevel, 'low');
        expect(capturedSystemInstruction, contains('Never guess or hallucinate'));
        expect(
          ApiConfig().geminiInteractionsUrl(),
          'https://generativelanguage.googleapis.com/v1beta/interactions',
        );
        expect(
          ApiConfig.normalizeGeminiModel('gemini-3.8-flash'),
          'gemini-4-hydrogen',
        );
        expect(service.connectTimeout, const Duration(seconds: 10));
        expect(service.receiveTimeout, const Duration(seconds: 30));
        expect(capturedPrompt, contains('Allowed map (id: aliases):'));
        expect(capturedPrompt, contains('{"ingredients":[{"id":"telur"'));
        expect(capturedPrompt, contains('indomie'));
        expect(detections.length, 2);
        expect(detections[0].ingredientId, 'telur');
        expect(detections[0].confidence, 0.98);
        expect(detections[1].ingredientId, 'mie_instan');
        expect(detections[1].confidence, 0.82);
        expect(detections.every((d) => d.isMatchedToDatabase), isTrue);
      },
    );

    test(
      'returns empty list when Interactions API returns empty ingredients or low-confidence guesses',
      () async {
        final serviceEmpty = AiVisionService(
          geminiExecutor: ({
            required String apiKey,
            required String model,
            required String thinkingLevel,
            required String systemInstruction,
            required String prompt,
            required Uint8List imageBytes,
            required String mimeType,
          }) async =>
              '{"ingredients":[]}',
        );

        final emptyResult = await serviceEmpty.analyzeImage(
          imageBytes: sampleBytes,
          masterIngredients: masterIngredients,
          apiKey: 'test-key',
        );
        expect(emptyResult, isEmpty);

        final serviceLowConfidence = AiVisionService(
          geminiExecutor: ({
            required String apiKey,
            required String model,
            required String thinkingLevel,
            required String systemInstruction,
            required String prompt,
            required Uint8List imageBytes,
            required String mimeType,
          }) async =>
              jsonEncode(<String, dynamic>{
                'ingredients': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 'telur',
                    'name': 'Telur Ayam',
                    'confidence': 0.55,
                  },
                ],
              }),
        );

        final filteredResult = await serviceLowConfidence.analyzeImage(
          imageBytes: sampleBytes,
          masterIngredients: masterIngredients,
          apiKey: 'test-key',
        );
        expect(filteredResult, isEmpty);
      },
    );

    test(
      'never silently falls back on missing API key, timeout, or network failure',
      () async {
        final serviceMissingKey = AiVisionService(defaultApiKey: '');

        await expectLater(
          () => serviceMissingKey.analyzeImage(
            imageBytes: sampleBytes,
            masterIngredients: masterIngredients,
          ),
          throwsA(
            isA<AiVisionException>()
                .having((e) => e.type, 'type', AiVisionErrorType.missingApiKey)
                .having(
                  (e) => e.message,
                  'message',
                  contains('API Key belum diisi'),
                ),
          ),
        );

        final serviceTimeout = AiVisionService(
          receiveTimeout: const Duration(milliseconds: 20),
          geminiExecutor: ({
            required String apiKey,
            required String model,
            required String thinkingLevel,
            required String systemInstruction,
            required String prompt,
            required Uint8List imageBytes,
            required String mimeType,
          }) async {
            await Future<void>.delayed(const Duration(milliseconds: 120));
            return '{"ingredients":[]}';
          },
        );

        await expectLater(
          () => serviceTimeout.analyzeImage(
            imageBytes: sampleBytes,
            masterIngredients: masterIngredients,
            apiKey: 'test-key',
          ),
          throwsA(
            isA<AiVisionException>()
                .having((e) => e.type, 'type', AiVisionErrorType.networkTimeout)
                .having((e) => e.message, 'message', contains('timeout')),
          ),
        );

        final serviceOffline = AiVisionService(
          geminiExecutor: ({
            required String apiKey,
            required String model,
            required String thinkingLevel,
            required String systemInstruction,
            required String prompt,
            required Uint8List imageBytes,
            required String mimeType,
          }) async {
            throw const SocketException('No internet');
          },
        );

        await expectLater(
          () => serviceOffline.analyzeImage(
            imageBytes: sampleBytes,
            masterIngredients: masterIngredients,
            apiKey: 'test-key',
          ),
          throwsA(
            isA<AiVisionException>().having(
              (e) => e.type,
              'type',
              AiVisionErrorType.networkUnavailable,
            ),
          ),
        );
      },
    );

    test(
      'explicitly runs offline simulation only when useOfflineSimulation is true',
      () async {
        final service = AiVisionService(
          simulationDelay: const Duration(milliseconds: 20),
        );

        final detections = await service.analyzeImage(
          imageBytes: sampleBytes,
          masterIngredients: masterIngredients,
          useOfflineSimulation: true,
        );

        expect(
          detections.map((d) => d.ingredientId),
          containsAllInOrder(<String>['telur', 'mie_instan', 'sosis']),
        );
        expect(detections.every((d) => d.isMatchedToDatabase), isTrue);
      },
    );

    test('supports runtime modelName override for future Gemini models', () async {
      String? capturedModel;
      final service = AiVisionService(
        geminiExecutor: ({
          required String apiKey,
          required String model,
          required String thinkingLevel,
          required String systemInstruction,
          required String prompt,
          required Uint8List imageBytes,
          required String mimeType,
        }) async {
          capturedModel = model;
          return '{"ingredients":[]}';
        },
      );

      await service.analyzeImage(
        imageBytes: sampleBytes,
        masterIngredients: masterIngredients,
        apiKey: 'demo-key',
        modelName: 'gemini-4-neon',
      );

      expect(capturedModel, 'gemini-4-neon');
    });

    test(
      'distinguishes Dio HTTP 400/403 API key errors, 429 quota, 404 model errors, and timeouts',
      () async {
        Dio createStubDio(
          Future<ResponseBody> Function(RequestOptions options) responder,
        ) {
          final dio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );
          dio.httpClientAdapter = _StubHttpClientAdapter(responder);
          return dio;
        }

        // HTTP 400 API key invalid
        final serviceBadKey = AiVisionService(
          dio: createStubDio((_) async {
            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{
                'error': <String, dynamic>{
                  'code': 400,
                  'message': 'API key not valid. Please pass a valid API key.',
                  'status': 'INVALID_ARGUMENT',
                },
              }),
              400,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/json'],
              },
            );
          }),
        );

        await expectLater(
          () => serviceBadKey.analyzeImage(
            imageBytes: sampleBytes,
            masterIngredients: masterIngredients,
            apiKey: 'wrong-key',
          ),
          throwsA(
            isA<AiVisionException>()
                .having((e) => e.type, 'type', AiVisionErrorType.invalidApiKey)
                .having(
                  (e) => e.message,
                  'message',
                  contains('API Key tidak valid (400)'),
                ),
          ),
        );

        // HTTP 429 quota exceeded
        final serviceQuota = AiVisionService(
          dio: createStubDio((_) async {
            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{
                'error': <String, dynamic>{
                  'code': 429,
                  'message': 'Quota exceeded for quota metric.',
                  'status': 'RESOURCE_EXHAUSTED',
                },
              }),
              429,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/json'],
              },
            );
          }),
        );

        await expectLater(
          () => serviceQuota.analyzeImage(
            imageBytes: sampleBytes,
            masterIngredients: masterIngredients,
            apiKey: 'demo-key',
          ),
          throwsA(
            isA<AiVisionException>()
                .having((e) => e.type, 'type', AiVisionErrorType.quotaExceeded)
                .having(
                  (e) => e.message,
                  'message',
                  contains('Kuota API habis (429)'),
                ),
          ),
        );

        // HTTP 404 model not found
        final serviceBadModel = AiVisionService(
          dio: createStubDio((_) async {
            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{
                'error': <String, dynamic>{
                  'code': 404,
                  'message':
                      'models/gemini-unknown is not found for API version v1beta.',
                  'status': 'NOT_FOUND',
                },
              }),
              404,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/json'],
              },
            );
          }),
        );

        await expectLater(
          () => serviceBadModel.analyzeImage(
            imageBytes: sampleBytes,
            masterIngredients: masterIngredients,
            apiKey: 'demo-key',
            modelName: 'gemini-unknown',
          ),
          throwsA(
            isA<AiVisionException>()
                .having((e) => e.type, 'type', AiVisionErrorType.modelError)
                .having((e) => e.message, 'message', contains('gemini-unknown')),
          ),
        );

        // Dio receiveTimeout
        final timeoutDio = Dio()
          ..httpClientAdapter = _StubHttpClientAdapter((options) async {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            );
          });
        final serviceReceiveTimeout = AiVisionService(dio: timeoutDio);

        await expectLater(
          () => serviceReceiveTimeout.analyzeImage(
            imageBytes: sampleBytes,
            masterIngredients: masterIngredients,
            apiKey: 'demo-key',
          ),
          throwsA(
            isA<AiVisionException>()
                .having((e) => e.type, 'type', AiVisionErrorType.networkTimeout)
                .having((e) => e.message, 'message', contains('30d')),
          ),
        );
      },
    );

    test(
      'posts to /v1beta/interactions with multimodal image input, response_format schema, ignores thought steps, and supports testConnection',
      () async {
        final capturedRequests = <RequestOptions>[];
        final dio = Dio()
          ..httpClientAdapter = _StubHttpClientAdapter((options) async {
            capturedRequests.add(options);
            final isPing = options.data['input'] is String;
            final modelOutputText = isPing
                ? '{"status":"ok"}'
                : '{"ingredients":[{"id":"telur","name":"Telur Ayam","confidence":0.95}]}';

            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{
                'id': 'v1_interaction_test_123',
                'status': 'completed',
                'model': 'gemini-4-hydrogen',
                'steps': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'type': 'thought',
                    'content': <Map<String, dynamic>>[
                      const <String, dynamic>{
                        'type': 'text',
                        'text': 'Ignore this internal thought text!',
                      },
                    ],
                  },
                  <String, dynamic>{
                    'type': 'model_output',
                    'content': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'type': 'text',
                        'text': modelOutputText,
                      },
                    ],
                  },
                ],
              }),
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/json'],
              },
            );
          });

        final service = AiVisionService(
          dio: dio,
          dnsLookup: (_) async => <InternetAddress>[
            InternetAddress('142.250.190.74'),
          ],
        );
        final detections = await service.analyzeImage(
          imageBytes: sampleBytes,
          masterIngredients: masterIngredients,
          apiKey: '  AQ.Ab8RN6-clean\nkey-123  ',
        );

        expect(detections.length, 1);
        expect(detections.first.ingredientId, 'telur');

        final scanOptions = capturedRequests[0];
        expect(
          scanOptions.uri.toString(),
          'https://generativelanguage.googleapis.com/v1beta/interactions',
        );
        expect(scanOptions.persistentConnection, isFalse);
        expect(scanOptions.receiveTimeout, const Duration(seconds: 30));
        expect(scanOptions.headers['Content-Type'], 'application/json');
        expect(scanOptions.headers['x-goog-api-key'], 'AQ.Ab8RN6-cleankey-123');
        expect(scanOptions.headers['Connection'], 'close');
        expect(scanOptions.headers['Accept-Encoding'], 'identity');

        final scanBody = scanOptions.data as Map<String, dynamic>;
        expect(scanBody['model'], 'gemini-4-hydrogen');
        expect(scanBody['system_instruction'], isA<String>());
        final inputList = scanBody['input'] as List<dynamic>;
        expect(inputList.length, 2);
        expect((inputList[0] as Map)['type'], 'text');
        expect((inputList[1] as Map)['type'], 'image');
        expect((inputList[1] as Map)['mime_type'], 'image/jpeg');
        expect((inputList[1] as Map)['data'], base64Encode(sampleBytes));

        final scanGenConfig =
            scanBody['generation_config'] as Map<String, dynamic>;
        expect(scanGenConfig['thinking_level'], 'low');
        expect(scanGenConfig['max_output_tokens'], 2048);
        expect(scanGenConfig.containsKey('temperature'), isFalse);

        final scanResponseFormat =
            scanBody['response_format'] as Map<String, dynamic>;
        expect(scanResponseFormat['type'], 'text');
        expect(scanResponseFormat['mime_type'], 'application/json');
        expect(scanResponseFormat['schema'], isA<Map<String, dynamic>>());

        final latencyMs = await service.testConnection(
          apiKey: ' AQ.Ab8RN6-clean key-123 ',
          model: 'gemini-4-hydrogen',
        );
        expect(latencyMs, greaterThanOrEqualTo(0));

        final pingOptions = capturedRequests[1];
        expect(
          pingOptions.uri.toString(),
          'https://generativelanguage.googleapis.com/v1beta/interactions',
        );
        expect(pingOptions.persistentConnection, isFalse);
        expect(pingOptions.receiveTimeout, const Duration(seconds: 30));
        expect(pingOptions.headers['Content-Type'], 'application/json');
        expect(pingOptions.headers['x-goog-api-key'], 'AQ.Ab8RN6-cleankey-123');
        expect(pingOptions.headers['Connection'], 'close');
        expect(pingOptions.headers['Accept-Encoding'], 'identity');

        final pingBody = pingOptions.data as Map<String, dynamic>;
        expect(pingBody['model'], 'gemini-4-hydrogen');
        expect(
          pingBody['input'],
          'Return ONLY this exact JSON: {"status":"ok"}',
        );
        final pingGenConfig =
            pingBody['generation_config'] as Map<String, dynamic>;
        expect(pingGenConfig['thinking_level'], 'low');
        expect(pingGenConfig['max_output_tokens'], 256);
        final pingResponseFormat =
            pingBody['response_format'] as Map<String, dynamic>;
        expect(pingResponseFormat['type'], 'text');
        expect(pingResponseFormat['mime_type'], 'application/json');
      },
    );

    test(
      'testConnection fails immediately with Wi-Fi restart hint when pre-flight DNS lookup fails',
      () async {
        var httpCalled = false;
        final dio = Dio()
          ..httpClientAdapter = _StubHttpClientAdapter((_) async {
            httpCalled = true;
            return ResponseBody.fromString('{}', 200);
          });

        final serviceOfflineDns = AiVisionService(
          dio: dio,
          dnsLookup: (_) async =>
              throw const SocketException('Failed host lookup'),
        );

        await expectLater(
          () => serviceOfflineDns.testConnection(apiKey: 'AQ.test-key'),
          throwsA(
            isA<AiVisionException>()
                .having(
                  (e) => e.type,
                  'type',
                  AiVisionErrorType.networkUnavailable,
                )
                .having(
                  (e) => e.message,
                  'message',
                  'Emulator tidak terhubung ke internet. Matikan lalu nyalakan ulang Wi-Fi di emulator.',
                ),
          ),
        );
        expect(httpCalled, isFalse);
      },
    );
  });
}

class _StubHttpClientAdapter implements HttpClientAdapter {
  _StubHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}
