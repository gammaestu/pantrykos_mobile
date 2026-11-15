import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/core/config/api_config.dart';
import 'package:pantrykos_mobile/data/datasources/pantry_local_datasource.dart';
import 'package:pantrykos_mobile/data/datasources/recipe_remote_datasource.dart';
import 'package:pantrykos_mobile/data/models/ingredient_model.dart';
import 'package:pantrykos_mobile/data/models/recipe_model.dart';
import 'package:pantrykos_mobile/data/repositories/pantry_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHttpAdapter implements HttpClientAdapter {
  _FakeHttpAdapter({
    required this.onFetch,
  });

  final ResponseBody Function(RequestOptions options) onFetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onFetch(options);
  }
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.assetContents);

  final String assetContents;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(assetContents));
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return assetContents;
  }
}

void main() {
  late String bundledJson;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    bundledJson = File('assets/data/pantrykos_db.json').readAsStringSync();
  });

  group('ApiConfig & Data Models', () {
    test('supports runtime remoteJsonUrl override and reset', () {
      final config = ApiConfig();
      expect(config.remoteJsonUrl, ApiConfig.defaultRemoteJsonUrl);

      config.updateRemoteJsonUrl('  https://example.com/custom.json  ');
      expect(config.remoteJsonUrl, 'https://example.com/custom.json');

      config.updateRemoteJsonUrl('   ');
      expect(config.remoteJsonUrl, 'https://example.com/custom.json');

      config.resetToDefaults();
      expect(config.remoteJsonUrl, ApiConfig.defaultRemoteJsonUrl);
    });

    test('IngredientModel & RecipeModel round-trip toJson/fromJson', () {
      const ing = IngredientModel(
        id: 'mie_instan',
        name: 'Mie Instan',
        category: 'Karbohidrat',
        icon: '🍜',
        aliases: ['indomie', 'mie goreng'],
      );
      expect(IngredientModel.fromJson(ing.toJson()), ing);

      const recipe = RecipeModel(
        id: 'r1',
        title: 'Nasi Telur',
        imageUrl: 'assets/images/r1.jpg',
        cookTimeMin: 5,
        estimatedCost: 8000,
        toolType: 'Teflon',
        mainIngredients: ['nasi_putih', 'telur'],
        optionalSeasonings: ['Garam'],
        steps: [
          RecipeStepModel(
            stepNumber: 1,
            instruction: 'Ceplok telur.',
            timerSeconds: 90,
          ),
        ],
      );
      expect(RecipeModel.fromJson(recipe.toJson()), recipe);
    });
  });

  group('PantryRepositoryImpl offline-first & persistence', () {
    test('fetches remote catalog, caches JSON, and serves offline thereafter', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final config = ApiConfig();
      var remoteCalls = 0;

      final remotePayload = jsonEncode(<String, dynamic>{
        'ingredients': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'telur',
            'name': 'Telur Ayam Remote',
            'category': 'Protein',
            'icon': '🥚',
            'aliases': <String>['telor'],
          },
        ],
        'recipes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'remote_recipe',
            'title': 'Telur Orak Remote',
            'image_url': 'remote.jpg',
            'cook_time_min': 4,
            'estimated_cost': 5000,
            'tool_type': 'Teflon',
            'main_ingredients': <String>['telur'],
            'optional_seasonings': <String>['Garam'],
            'steps': <Map<String, dynamic>>[
              <String, dynamic>{
                'step_number': 1,
                'instruction': 'Aduk telur.',
              },
            ],
          },
        ],
      });

      final dio = Dio(
        BaseOptions(
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        ),
      )..httpClientAdapter = _FakeHttpAdapter(
          onFetch: (options) {
            remoteCalls++;
            expect(options.connectTimeout, const Duration(seconds: 8));
            expect(options.receiveTimeout, const Duration(seconds: 8));
            return ResponseBody.fromString(
              remotePayload,
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>[Headers.jsonContentType],
              },
            );
          },
        );

      final remote = RecipeRemoteDataSourceImpl(dio: dio, apiConfig: config);
      final local = PantryLocalDataSourceImpl(
        assetBundle: _FakeAssetBundle(bundledJson),
      );
      final repo = PantryRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final recipes = await repo.getRecipes();
      expect(remoteCalls, 1);
      expect(recipes.single.id, 'remote_recipe');

      // New repository instance with failing remote still reads cached remote JSON
      final offlineDio = Dio()
        ..httpClientAdapter = _FakeHttpAdapter(
          onFetch: (_) => ResponseBody.fromString('error', 503),
        );
      final offlineRepo = PantryRepositoryImpl(
        remoteDataSource: RecipeRemoteDataSourceImpl(
          dio: offlineDio,
          apiConfig: config,
        ),
        localDataSource: local,
      );
      final cachedRecipes = await offlineRepo.getRecipes(forceRefresh: true);
      expect(cachedRecipes.single.id, 'remote_recipe');
    });

    test('falls back to bundled assets/data/pantrykos_db.json when offline on first launch', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final failingDio = Dio()
        ..httpClientAdapter = _FakeHttpAdapter(
          onFetch: (_) => ResponseBody.fromString('offline', 500),
        );

      final repo = PantryRepositoryImpl(
        remoteDataSource: RecipeRemoteDataSourceImpl(dio: failingDio),
        localDataSource: PantryLocalDataSourceImpl(
          assetBundle: _FakeAssetBundle(bundledJson),
        ),
      );

      final ingredients = await repo.getMasterIngredients();
      final recipes = await repo.getRecipes();

      expect(ingredients.length, greaterThanOrEqualTo(20));
      expect(recipes.length, greaterThanOrEqualTo(12));
    });

    test('persists user_pantry and bookmarked_recipes locally without login', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final local = PantryLocalDataSourceImpl(
        assetBundle: _FakeAssetBundle(bundledJson),
      );
      final repo = PantryRepositoryImpl(
        remoteDataSource: RecipeRemoteDataSourceImpl(),
        localDataSource: local,
      );

      await repo.saveUserPantryIds(['telur', 'mie_instan', 'telur']);
      expect(await repo.getUserPantryIds(), ['telur', 'mie_instan']);

      await repo.toggleBookmark('nasi_telur_ceplok_kecap');
      expect(await repo.getBookmarkedIds(), ['nasi_telur_ceplok_kecap']);

      await repo.toggleBookmark('nasi_telur_ceplok_kecap');
      expect(await repo.getBookmarkedIds(), isEmpty);
    });
  });
}
