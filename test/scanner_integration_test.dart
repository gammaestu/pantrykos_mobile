import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/data/services/ai_vision_service.dart';
import 'package:pantrykos_mobile/domain/entities/detected_ingredient.dart';
import 'package:pantrykos_mobile/domain/entities/ingredient.dart';
import 'package:pantrykos_mobile/main.dart';
import 'package:pantrykos_mobile/presentation/providers/pantry_provider.dart';
import 'package:pantrykos_mobile/presentation/providers/repository_providers.dart';
import 'package:pantrykos_mobile/presentation/screens/scanner_ui_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineDioAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString('offline', 503);
  }
}

class _FakeAiVisionService extends AiVisionService {
  _FakeAiVisionService({this.detectionsToReturn = _defaultDetections})
      : super(simulationDelay: Duration.zero);

  static const List<DetectedIngredient> _defaultDetections =
      <DetectedIngredient>[
    DetectedIngredient(
      ingredientId: 'telur',
      detectedName: 'Telur Ayam',
      confidence: 0.98,
      isMatchedToDatabase: true,
    ),
    DetectedIngredient(
      ingredientId: 'sawi',
      detectedName: 'Sawi Hijau',
      confidence: 0.94,
      isMatchedToDatabase: true,
    ),
  ];

  List<DetectedIngredient> detectionsToReturn;
  bool called = false;
  int callCount = 0;
  bool? lastOfflineFlag;
  String? lastApiKey;
  String? lastModelName;
  String? lastMimeType;

  @override
  Future<int> testConnection({
    String? apiKey,
    String? model,
    String? modelName,
  }) async {
    lastApiKey = apiKey;
    lastModelName = model ?? modelName;
    return 42;
  }

  @override
  Future<List<DetectedIngredient>> detectIngredients({
    required Uint8List imageBytes,
    required List<Ingredient> masterIngredients,
    String? apiKey,
    bool useOfflineSimulation = false,
    String mimeType = 'image/jpeg',
    String? modelName,
    String? preEncodedBase64,
  }) async {
    called = true;
    callCount++;
    lastOfflineFlag = useOfflineSimulation;
    lastApiKey = apiKey;
    lastModelName = modelName;
    lastMimeType = mimeType;

    await Future<void>.delayed(const Duration(milliseconds: 120));
    return detectionsToReturn;
  }
}

void main() {
  // Valid 1x1 transparent PNG bytes so Image.memory decodes cleanly in widget tests.
  final validPngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  testWidgets(
    'ScannerUiScreen captures photo, displays processing pill, toggles chips, and syncs to pantryProvider',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(<String, Object>{
        PantryNotifier.geminiApiKeyPrefKey: 'saved-test-key',
      });

      final fakeAi = _FakeAiVisionService();
      final offlineDio = Dio()..httpClientAdapter = _OfflineDioAdapter();
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(offlineDio),
            aiVisionServiceProvider.overrideWithValue(fakeAi),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                ref.watch(pantryProvider);
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final selected =
                            await Navigator.of(context).push<Set<String>>(
                          MaterialPageRoute<Set<String>>(
                            builder: (_) => ScannerUiScreen(
                              imagePickerOverride: (_) async => validPngBytes,
                            ),
                          ),
                        );
                        if (selected != null &&
                            selected.isNotEmpty &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selected.length} bahan masuk Kulkas Virtual!',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Buka Scanner'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Let PantryNotifier initialize masterIngredients & prefs
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        capturedRef.read(pantryProvider).geminiApiKey,
        'saved-test-key',
      );
      expect(
        capturedRef.read(pantryProvider).useOfflineSimulation,
        isFalse,
      );
      expect(
        capturedRef.read(pantryProvider).activeIngredientIds,
        isNot(contains('sawi')),
      );

      // Open ScannerUiScreen
      await tester.tap(find.text('Buka Scanner'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('gemini-4-hydrogen Vision Siap'), findsOneWidget);

      // Pick photo from Gallery -> triggers AI processing state
      await tester.tap(find.text('Galeri').first);
      await tester.pump(const Duration(milliseconds: 30));

      expect(find.byType(Image), findsOneWidget);
      expect(
        find.text('AI sedang mengenali bahan makanan...'),
        findsOneWidget,
      );

      // Allow background compute() isolate to finish base64 encoding, then pump
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 350));

      expect(fakeAi.called, isTrue);
      expect(fakeAi.lastApiKey, 'saved-test-key');
      expect(fakeAi.lastModelName, 'gemini-4-hydrogen');
      expect(fakeAi.lastOfflineFlag, isFalse);

      // Floating badges + bottom sheet chips populated
      expect(find.text('98%'), findsOneWidget);
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('Telur Ayam (98%)'), findsOneWidget);
      expect(find.text('Sawi Hijau (94%)'), findsOneWidget);
      expect(find.text('Bahan Terdeteksi (2)'), findsOneWidget);

      // Toggle off Telur Ayam chip, leaving Sawi Hijau selected
      await tester.tap(find.text('Telur Ayam (98%)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Bahan Terdeteksi (1)'), findsOneWidget);

      // Tap "Masukkan ke Kulkas (+)" -> calls addDetectedIngredients & pops
      await tester.tap(find.text('Masukkan ke Kulkas (+)'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        capturedRef.read(pantryProvider).activeIngredientIds,
        contains('sawi'),
      );
      expect(
        find.text('1 bahan masuk Kulkas Virtual!'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ScannerUiScreen handles 0 Bahan Terdeteksi cleanly without dummy pills and disables CTA',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(<String, Object>{
        PantryNotifier.geminiApiKeyPrefKey: 'saved-test-key',
      });

      final emptyAi = _FakeAiVisionService(
        detectionsToReturn: const <DetectedIngredient>[],
      );
      final offlineDio = Dio()..httpClientAdapter = _OfflineDioAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(offlineDio),
            aiVisionServiceProvider.overrideWithValue(emptyAi),
          ],
          child: MaterialApp(
            home: ScannerUiScreen(
              imagePickerOverride: (_) async => validPngBytes,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Trigger Gallery pick on a non-food image
      await tester.tap(find.text('Galeri').first);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Bahan Terdeteksi (0)'), findsOneWidget);
      expect(find.text('Tidak Ada Bahan Terdeteksi'), findsOneWidget);
      expect(
        find.text(
          'Foto tidak menampilkan bahan makanan yang dikenali. Pastikan bahan terlihat jelas dan tidak buram.',
        ),
        findsOneWidget,
      );
      expect(find.text('Foto Ulang'), findsOneWidget);
      expect(find.text('Pilih Galeri'), findsOneWidget);
      expect(find.text('Telur Ayam'), findsNothing);
      expect(find.text('Mie Instan'), findsNothing);

      final submitBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Masukkan ke Kulkas (+)'),
      );
      expect(submitBtn.onPressed, isNull);
      expect(emptyAi.callCount, 1);
      expect(emptyAi.lastMimeType, 'image/png');

      // Tapping "Pindai" re-triggers AI analysis on the loaded image without re-picking
      await tester.tap(find.text('Pindai'));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 250));
      expect(emptyAi.callCount, 2);
    },
  );

  testWidgets(
    'Info Proyek & AI Status sheet saves Gemini API Key and Offline Simulation to SharedPreferences',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final offlineDio = Dio()..httpClientAdapter = _OfflineDioAdapter();
      final fakeAi = _FakeAiVisionService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(offlineDio),
            aiVisionServiceProvider.overrideWithValue(fakeAi),
          ],
          child: const PantryKosApp(),
        ),
      );

      // Advance past 2.8s splash + 650ms reveal
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(const Duration(milliseconds: 800));

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Info Proyek & AI Status'), findsOneWidget);
      expect(find.text('Live Gemini AI'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(
          TextField,
          'AQ... / AIzaSy... (opsional untuk mode simulasi)',
        ),
        'OldKeyToClear',
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Clear button ("Hapus") resets field cleanly before pasting new key
      await tester.tap(find.byTooltip('Hapus'));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(
        find.widgetWithText(
          TextField,
          'AQ... / AIzaSy... (opsional untuk mode simulasi)',
        ),
        'AQ.Ab8RN6TestKey123',
      );
      await tester.ensureVisible(find.text('gemini-3.5-flash-lite'));
      await tester.tap(find.text('gemini-3.5-flash-lite'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tapping model chip immediately persists to SharedPreferences
      final prefsAfterChip = await SharedPreferences.getInstance();
      expect(
        prefsAfterChip.getString(PantryNotifier.geminiModelPrefKey),
        'gemini-3.5-flash-lite',
      );

      await tester.ensureVisible(find.text('Tes Koneksi AI'));
      await tester.tap(find.text('Tes Koneksi AI'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('Terhubung (42 ms) • gemini-3.5-flash-lite'),
        findsOneWidget,
      );
      expect(fakeAi.lastApiKey, 'AQ.Ab8RN6TestKey123');
      expect(fakeAi.lastModelName, 'gemini-3.5-flash-lite');

      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Offline Demo Simulation'), findsOneWidget);

      await tester.ensureVisible(find.text('Simpan Konfigurasi'));
      await tester.tap(find.text('Simpan Konfigurasi'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 400));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(PantryNotifier.geminiApiKeyPrefKey),
        'AQ.Ab8RN6TestKey123',
      );
      expect(
        prefs.getString(PantryNotifier.geminiModelPrefKey),
        'gemini-3.5-flash-lite',
      );
      expect(
        prefs.getBool(PantryNotifier.offlineSimulationPrefKey),
        isTrue,
      );
    },
  );
}
