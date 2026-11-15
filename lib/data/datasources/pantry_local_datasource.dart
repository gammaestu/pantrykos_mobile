import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';

/// Contract for local catalog caching, bundled asset fallback, and user state.
abstract class PantryLocalDataSource {
  Future<void> cacheCatalogJson(String rawJson);
  Future<String?> getCachedCatalogJson();
  Future<PantryCatalogBundle> loadCachedOrAssetCatalog();
  Future<PantryCatalogBundle> loadBundledAssetCatalog();

  Future<List<String>> getUserPantryIds();
  Future<void> saveUserPantryIds(List<String> ids);

  Future<List<String>> getBookmarkedIds();
  Future<void> saveBookmarkedIds(List<String> ids);
  Future<void> toggleBookmark(String recipeId);
}

/// Offline-first local storage powered by [SharedPreferences] and [AssetBundle].
class PantryLocalDataSourceImpl implements PantryLocalDataSource {
  PantryLocalDataSourceImpl({
    Future<SharedPreferences>? prefsFuture,
    AssetBundle? assetBundle,
  })  : _prefsFuture = prefsFuture ?? SharedPreferences.getInstance(),
        _assetBundle = assetBundle ?? rootBundle;

  static const String catalogJsonKey = 'cached_pantrykos_catalog_json';
  static const String catalogTimestampKey = 'cached_pantrykos_catalog_ts';
  static const String userPantryKey = 'user_pantry';
  static const String bookmarkedRecipesKey = 'bookmarked_recipes';
  static const String bundledAssetPath = 'assets/data/pantrykos_db.json';

  final Future<SharedPreferences> _prefsFuture;
  final AssetBundle _assetBundle;

  @override
  Future<void> cacheCatalogJson(String rawJson) async {
    final prefs = await _prefsFuture;
    await prefs.setString(catalogJsonKey, rawJson);
    await prefs.setString(
      catalogTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<String?> getCachedCatalogJson() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getString(catalogJsonKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw;
  }

  @override
  Future<PantryCatalogBundle> loadCachedOrAssetCatalog() async {
    final cachedRaw = await getCachedCatalogJson();
    if (cachedRaw != null) {
      try {
        return PantryCatalogBundle.fromRawJson(cachedRaw);
      } on FormatException {
        // Fall through cleanly to bundled asset if local cache was corrupted.
      }
    }
    return loadBundledAssetCatalog();
  }

  @override
  Future<PantryCatalogBundle> loadBundledAssetCatalog() async {
    final assetJson = await _assetBundle.loadString(bundledAssetPath);
    return PantryCatalogBundle.fromRawJson(assetJson);
  }

  @override
  Future<List<String>> getUserPantryIds() async {
    final prefs = await _prefsFuture;
    final stored = prefs.getStringList(userPantryKey);
    if (stored == null) return const <String>[];
    return List<String>.unmodifiable(stored);
  }

  @override
  Future<void> saveUserPantryIds(List<String> ids) async {
    final prefs = await _prefsFuture;
    final sanitized = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    await prefs.setStringList(userPantryKey, sanitized);
  }

  @override
  Future<List<String>> getBookmarkedIds() async {
    final prefs = await _prefsFuture;
    final stored = prefs.getStringList(bookmarkedRecipesKey);
    if (stored == null) return const <String>[];
    return List<String>.unmodifiable(stored);
  }

  @override
  Future<void> saveBookmarkedIds(List<String> ids) async {
    final prefs = await _prefsFuture;
    final sanitized = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    await prefs.setStringList(bookmarkedRecipesKey, sanitized);
  }

  @override
  Future<void> toggleBookmark(String recipeId) async {
    final trimmed = recipeId.trim();
    if (trimmed.isEmpty) return;

    final current = List<String>.from(await getBookmarkedIds());
    if (!current.remove(trimmed)) {
      current.add(trimmed);
    }
    await saveBookmarkedIds(current);
  }
}
