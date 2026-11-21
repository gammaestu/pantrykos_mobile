import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../data/datasources/pantry_local_datasource.dart';
import '../../data/datasources/recipe_remote_datasource.dart';
import '../../data/repositories/pantry_repository_impl.dart';
import '../../data/services/ai_vision_service.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../../domain/usecases/recipe_matching_engine.dart';

/// Runtime API endpoint configuration provider.
final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig();
});

/// Configured `Dio` HTTP client with standard TLS and 8-second connect/receive timeouts.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      responseType: ResponseType.plain,
      headers: const <String, String>{
        'Accept': 'application/json',
      },
    ),
  );
});

/// `SharedPreferences` handle provider for local cache and persistence.
final sharedPreferencesProvider = Provider<Future<SharedPreferences>>((ref) {
  return SharedPreferences.getInstance();
});

/// Local data source provider (cached catalog + bundled asset fallback + user state).
final pantryLocalDataSourceProvider = Provider<PantryLocalDataSource>((ref) {
  return PantryLocalDataSourceImpl(
    prefsFuture: ref.watch(sharedPreferencesProvider),
  );
});

/// Remote data source provider powered by `Dio`.
final recipeRemoteDataSourceProvider = Provider<RecipeRemoteDataSource>((ref) {
  return RecipeRemoteDataSourceImpl(
    dio: ref.watch(dioProvider),
    apiConfig: ref.watch(apiConfigProvider),
  );
});

/// Hybrid offline-first [PantryRepository] provider.
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  return PantryRepositoryImpl(
    remoteDataSource: ref.watch(recipeRemoteDataSourceProvider),
    localDataSource: ref.watch(pantryLocalDataSourceProvider),
  );
});

/// Pure domain recipe matching & ranking use case provider.
final recipeMatchingEngineProvider = Provider<RecipeMatchingEngine>((ref) {
  return const RecipeMatchingEngine();
});

/// Gemini Flash Vision AI service provider with offline simulation support.
final aiVisionServiceProvider = Provider<AiVisionService>((ref) {
  return AiVisionService();
});
