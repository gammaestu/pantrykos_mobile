import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/data/datasources/pantry_local_datasource.dart';
import 'package:pantrykos_mobile/presentation/providers/pantry_provider.dart';
import 'package:pantrykos_mobile/presentation/providers/repository_providers.dart';
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

class _AssetBundleStub extends CachingAssetBundle {
  _AssetBundleStub(this.rawJson);

  final String rawJson;

  @override
  Future<ByteData> load(String key) async {
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(rawJson)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => rawJson;
}

void main() {
  late String dbJson;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dbJson = File('assets/data/pantrykos_db.json').readAsStringSync();
  });

  test('PantryNotifier initializes, mutates pantry, filters, and bookmarks reactively', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final offlineDio = Dio()..httpClientAdapter = _OfflineDioAdapter();

    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(offlineDio),
        pantryLocalDataSourceProvider.overrideWithValue(
          PantryLocalDataSourceImpl(
            assetBundle: _AssetBundleStub(dbJson),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final loadedCompleter = Completer<void>();
    final sub = container.listen<PantryState>(
      pantryProvider,
      (_, next) {
        if (!next.isLoading && !loadedCompleter.isCompleted) {
          loadedCompleter.complete();
        }
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);

    // Initial state starts loading (triggers RecipeCardSkeleton in HomeScreen)
    final initial = container.read(pantryProvider);
    expect(initial.isLoading, isTrue);

    // Deterministically wait for async initialization microtask
    await loadedCompleter.future.timeout(const Duration(seconds: 5));

    final loaded = container.read(pantryProvider);
    expect(loaded.isLoading, isFalse);
    expect(loaded.errorMessage, isNull);
    expect(loaded.masterIngredients.length, greaterThanOrEqualTo(20));
    expect(loaded.recipes.length, greaterThanOrEqualTo(12));
    expect(loaded.activeIngredientIds, contains('telur'));
    expect(loaded.bookmarkedIds, contains('nasgor_mawut_rice_cooker'));

    final notifier = container.read(pantryProvider.notifier);

    // Toggle ingredient off & back on
    notifier.toggleIngredient('telur');
    expect(container.read(pantryProvider).activeIngredientIds, isNot(contains('telur')));

    notifier.addDetectedIngredients(const ['telur', 'sawi']);
    expect(container.read(pantryProvider).activeIngredientIds, containsAll(['telur', 'sawi']));

    // Remove used ingredients (from CookingModeSheet completion)
    notifier.removeUsedIngredients(const ['sawi']);
    expect(container.read(pantryProvider).activeIngredientIds, isNot(contains('sawi')));

    // Tool filter & search query
    notifier.setToolFilter('Rice Cooker');
    expect(
      container
          .read(pantryProvider)
          .matchedRecipes
          .every((m) => m.recipe.toolType == 'Rice Cooker'),
      isTrue,
    );

    notifier.setSearchQuery('Kornet');
    expect(
      container.read(pantryProvider).matchedRecipes.single.recipe.id,
      'nasi_liwet_kornet_magic_com',
    );

    // Toggle bookmark & reset pantry
    notifier.toggleBookmark('nasi_liwet_kornet_magic_com');
    expect(
      container.read(pantryProvider).bookmarkedIds,
      contains('nasi_liwet_kornet_magic_com'),
    );

    notifier.resetPantry();
    expect(container.read(pantryProvider).activeIngredientIds, isEmpty);

    await notifier.refreshCatalog();
    expect(container.read(pantryProvider).isLoading, isFalse);
    expect(container.read(pantryProvider).recipes.length, greaterThanOrEqualTo(12));
  });

  test('PantryNotifier auto-migrates legacy gemini-3.8-flash preference to gemini-4-hydrogen', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PantryNotifier.geminiModelPrefKey: 'gemini-3.8-flash',
    });
    final offlineDio = Dio()..httpClientAdapter = _OfflineDioAdapter();

    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(offlineDio),
        pantryLocalDataSourceProvider.overrideWithValue(
          PantryLocalDataSourceImpl(
            assetBundle: _AssetBundleStub(dbJson),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final loadedCompleter = Completer<void>();
    final sub = container.listen<PantryState>(
      pantryProvider,
      (_, next) {
        if (!next.isLoading && !loadedCompleter.isCompleted) {
          loadedCompleter.complete();
        }
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);

    await loadedCompleter.future.timeout(const Duration(seconds: 5));

    expect(container.read(pantryProvider).geminiModel, 'gemini-4-hydrogen');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(PantryNotifier.geminiModelPrefKey),
      'gemini-4-hydrogen',
    );
  });
}
