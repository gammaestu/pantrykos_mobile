import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../datasources/pantry_local_datasource.dart';
import '../datasources/recipe_remote_datasource.dart';
import '../models/recipe_model.dart';

/// Hybrid Offline-First implementation of [PantryRepository].
///
/// Strategy:
/// - `forceRefresh: true` -> Fetch remote catalog via [RecipeRemoteDataSource],
///   cache raw JSON locally, and fall back gracefully to local cache / bundled
///   asset on network failure.
/// - `forceRefresh: false` -> Serve fast from in-memory or cached JSON; on a
///   cold first launch with no cache yet, try remote sync first and fall back
///   automatically to `assets/data/pantrykos_db.json`.
/// - User state (`user_pantry` and `bookmarked_recipes`) persists locally via
///   [PantryLocalDataSource] across app restarts without authentication.
class PantryRepositoryImpl implements PantryRepository {
  PantryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final RecipeRemoteDataSource remoteDataSource;
  final PantryLocalDataSource localDataSource;

  PantryCatalogBundle? _memoryCatalog;

  Future<PantryCatalogBundle> _resolveCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCatalog != null) {
      return _memoryCatalog!;
    }

    if (forceRefresh) {
      return _fetchRemoteWithOfflineFallback();
    }

    // Prefer already cached remote catalog when available for instant offline startup.
    final cachedRaw = await localDataSource.getCachedCatalogJson();
    if (cachedRaw != null) {
      try {
        final parsed = PantryCatalogBundle.fromRawJson(cachedRaw);
        _memoryCatalog = parsed;
        return parsed;
      } on FormatException {
        // Ignore corrupted cache and refresh from remote/asset below.
      }
    }

    // Cold first launch: try remote sync, auto-falling back to bundled asset.
    return _fetchRemoteWithOfflineFallback();
  }

  Future<PantryCatalogBundle> _fetchRemoteWithOfflineFallback() async {
    try {
      final remoteCatalog = await remoteDataSource.fetchCatalog();
      await localDataSource.cacheCatalogJson(remoteCatalog.rawJson);
      _memoryCatalog = remoteCatalog;
      return remoteCatalog;
    } catch (_) {
      final fallbackCatalog = await localDataSource.loadCachedOrAssetCatalog();
      _memoryCatalog = fallbackCatalog;
      return fallbackCatalog;
    }
  }

  @override
  Future<List<Ingredient>> getMasterIngredients() async {
    final catalog = await _resolveCatalog();
    return catalog.ingredients;
  }

  @override
  Future<List<Recipe>> getRecipes({bool forceRefresh = false}) async {
    final catalog = await _resolveCatalog(forceRefresh: forceRefresh);
    return catalog.recipes;
  }

  @override
  Future<List<String>> getUserPantryIds() {
    return localDataSource.getUserPantryIds();
  }

  @override
  Future<void> saveUserPantryIds(List<String> ids) {
    return localDataSource.saveUserPantryIds(ids);
  }

  @override
  Future<List<String>> getBookmarkedIds() {
    return localDataSource.getBookmarkedIds();
  }

  @override
  Future<void> toggleBookmark(String recipeId) {
    return localDataSource.toggleBookmark(recipeId);
  }
}
