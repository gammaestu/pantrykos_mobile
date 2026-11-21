import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../data/datasources/pantry_local_datasource.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_match_result.dart';
import 'repository_providers.dart';

/// Immutable UI-facing application state for PantryKos.
class PantryState {
  final bool isLoading;
  final String? errorMessage;
  final List<Ingredient> masterIngredients;
  final List<Recipe> recipes;
  final Set<String> activeIngredientIds;
  final String selectedToolFilter;
  final String searchQuery;
  final Set<String> bookmarkedIds;
  final List<RecipeMatchResult> matchedRecipes;
  final String remoteJsonUrl;
  final String laravelBaseUrl;
  final bool useLiveLaravelAi;
  final String geminiApiKey;
  final String geminiModel;
  final bool useOfflineSimulation;

  const PantryState({
    this.isLoading = false,
    this.errorMessage,
    this.masterIngredients = const <Ingredient>[],
    this.recipes = const <Recipe>[],
    this.activeIngredientIds = const <String>{},
    this.selectedToolFilter = 'Semua Alat',
    this.searchQuery = '',
    this.bookmarkedIds = const <String>{},
    this.matchedRecipes = const <RecipeMatchResult>[],
    this.remoteJsonUrl = ApiConfig.defaultRemoteJsonUrl,
    this.laravelBaseUrl = ApiConfig.defaultLaravelBaseUrl,
    this.useLiveLaravelAi = true,
    this.geminiApiKey = '',
    this.geminiModel = ApiConfig.defaultGeminiModel,
    this.useOfflineSimulation = false,
  });

  PantryState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<Ingredient>? masterIngredients,
    List<Recipe>? recipes,
    Set<String>? activeIngredientIds,
    String? selectedToolFilter,
    String? searchQuery,
    Set<String>? bookmarkedIds,
    List<RecipeMatchResult>? matchedRecipes,
    String? remoteJsonUrl,
    String? laravelBaseUrl,
    bool? useLiveLaravelAi,
    String? geminiApiKey,
    String? geminiModel,
    bool? useOfflineSimulation,
  }) {
    return PantryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      masterIngredients: masterIngredients ?? this.masterIngredients,
      recipes: recipes ?? this.recipes,
      activeIngredientIds: activeIngredientIds ?? this.activeIngredientIds,
      selectedToolFilter: selectedToolFilter ?? this.selectedToolFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      matchedRecipes: matchedRecipes ?? this.matchedRecipes,
      remoteJsonUrl: remoteJsonUrl ?? this.remoteJsonUrl,
      laravelBaseUrl: laravelBaseUrl ?? this.laravelBaseUrl,
      useLiveLaravelAi: useLiveLaravelAi ?? this.useLiveLaravelAi,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiModel: geminiModel ?? this.geminiModel,
      useOfflineSimulation:
          useOfflineSimulation ?? this.useOfflineSimulation,
    );
  }
}

/// Reactive state manager connecting the pure domain [RecipeMatchingEngine]
/// and hybrid offline-first [PantryRepository] to all presentation screens.
class PantryNotifier extends Notifier<PantryState> {
  static const List<String> _starterPantryIds = <String>[
    'nasi_putih',
    'telur',
    'bawang_putih',
    'kecap_manis',
    'mie_instan',
  ];
  static const String _starterBookmarkId = 'nasgor_mawut_rice_cooker';
  static const String geminiApiKeyPrefKey = 'gemini_api_key';
  static const String geminiModelPrefKey = 'gemini_model';
  static const String offlineSimulationPrefKey = 'ai_offline_simulation';
  static const String remoteJsonUrlPrefKey = 'remote_json_url';
  static const String laravelBaseUrlPrefKey = 'laravel_base_url';

  @override
  PantryState build() {
    final config = ref.read(apiConfigProvider);
    Future.microtask(_initialize);
    return PantryState(
      isLoading: true,
      remoteJsonUrl: config.remoteJsonUrl,
      laravelBaseUrl: config.laravelBaseUrl,
      geminiModel: config.geminiModel,
    );
  }

  Future<void> _initialize() async {
    try {
      final repo = ref.read(pantryRepositoryProvider);
      final prefs = await ref.read(sharedPreferencesProvider);

      // Seed friendly starter fridge & bookmark only on first launch ever.
      if (!prefs.containsKey(PantryLocalDataSourceImpl.userPantryKey)) {
        await repo.saveUserPantryIds(_starterPantryIds);
      }
      if (!prefs.containsKey(PantryLocalDataSourceImpl.bookmarkedRecipesKey)) {
        await repo.toggleBookmark(_starterBookmarkId);
      }

      final ingredients = await repo.getMasterIngredients();
      final recipes = await repo.getRecipes();
      final pantryIds = await repo.getUserPantryIds();
      final bookmarks = await repo.getBookmarkedIds();

      final savedGeminiKey = (prefs.getString(geminiApiKeyPrefKey) ?? '')
          .replaceAll(RegExp(r'\s+'), '');
      final rawSavedModel = prefs.getString(geminiModelPrefKey);
      final normalizedGeminiModel = ApiConfig.normalizeGeminiModel(
        rawSavedModel,
      );
      final savedOfflineSim = prefs.getBool(offlineSimulationPrefKey) ?? false;
      final savedRemoteUrl = prefs.getString(remoteJsonUrlPrefKey);
      final savedLaravelUrl = prefs.getString(laravelBaseUrlPrefKey);

      final config = ref.read(apiConfigProvider);
      config.updateGeminiModel(normalizedGeminiModel);
      if (rawSavedModel != null &&
          rawSavedModel.trim() != normalizedGeminiModel) {
        await prefs.setString(geminiModelPrefKey, normalizedGeminiModel);
      }
      if (savedRemoteUrl != null && savedRemoteUrl.trim().isNotEmpty) {
        config.updateRemoteJsonUrl(savedRemoteUrl);
      }
      if (savedLaravelUrl != null && savedLaravelUrl.trim().isNotEmpty) {
        config.updateLaravelBaseUrl(savedLaravelUrl);
      }

      if (!ref.mounted) return;

      final activeSet = pantryIds.toSet();
      final bookmarkSet = bookmarks.toSet();

      state = state.copyWith(
        isLoading: false,
        clearError: true,
        masterIngredients: ingredients,
        recipes: recipes,
        activeIngredientIds: activeSet,
        bookmarkedIds: bookmarkSet,
        geminiApiKey: savedGeminiKey,
        geminiModel: config.geminiModel,
        useOfflineSimulation: savedOfflineSim,
        useLiveLaravelAi: !savedOfflineSim,
        remoteJsonUrl: config.remoteJsonUrl,
        laravelBaseUrl: config.laravelBaseUrl,
        matchedRecipes: _computeMatches(
          recipes: recipes,
          masterIngredients: ingredients,
          activeIds: activeSet,
          toolFilter: state.selectedToolFilter,
          searchQuery: state.searchQuery,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data kulkas & resep: $e',
      );
    }
  }

  List<RecipeMatchResult> _computeMatches({
    required List<Recipe> recipes,
    required List<Ingredient> masterIngredients,
    required Set<String> activeIds,
    required String toolFilter,
    required String searchQuery,
  }) {
    final engine = ref.read(recipeMatchingEngineProvider);
    return engine.matchAndRank(
      recipes: recipes,
      masterIngredients: masterIngredients,
      userPantryIds: activeIds,
      toolType: toolFilter,
      searchQuery: searchQuery,
    );
  }

  void _updatePantry(Set<String> nextActiveIds) {
    state = state.copyWith(
      activeIngredientIds: Set<String>.unmodifiable(nextActiveIds),
      matchedRecipes: _computeMatches(
        recipes: state.recipes,
        masterIngredients: state.masterIngredients,
        activeIds: nextActiveIds,
        toolFilter: state.selectedToolFilter,
        searchQuery: state.searchQuery,
      ),
    );
    ref
        .read(pantryRepositoryProvider)
        .saveUserPantryIds(nextActiveIds.toList(growable: false));
  }

  void toggleIngredient(String id) {
    final next = Set<String>.from(state.activeIngredientIds);
    if (!next.remove(id)) {
      next.add(id);
    }
    _updatePantry(next);
  }

  void addDetectedIngredients(List<String> ids) {
    if (ids.isEmpty) return;
    final next = Set<String>.from(state.activeIngredientIds)..addAll(ids);
    _updatePantry(next);
  }

  void removeUsedIngredients(List<String> ids) {
    if (ids.isEmpty) return;
    final next = Set<String>.from(state.activeIngredientIds)..removeAll(ids);
    _updatePantry(next);
  }

  void resetPantry() {
    if (state.activeIngredientIds.isEmpty) return;
    _updatePantry(<String>{});
  }

  void setToolFilter(String tool) {
    if (state.selectedToolFilter == tool) return;
    state = state.copyWith(
      selectedToolFilter: tool,
      matchedRecipes: _computeMatches(
        recipes: state.recipes,
        masterIngredients: state.masterIngredients,
        activeIds: state.activeIngredientIds,
        toolFilter: tool,
        searchQuery: state.searchQuery,
      ),
    );
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(
      searchQuery: query,
      matchedRecipes: _computeMatches(
        recipes: state.recipes,
        masterIngredients: state.masterIngredients,
        activeIds: state.activeIngredientIds,
        toolFilter: state.selectedToolFilter,
        searchQuery: query,
      ),
    );
  }

  void toggleBookmark(String recipeId) {
    final next = Set<String>.from(state.bookmarkedIds);
    if (!next.remove(recipeId)) {
      next.add(recipeId);
    }
    state = state.copyWith(
      bookmarkedIds: Set<String>.unmodifiable(next),
    );
    ref.read(pantryRepositoryProvider).toggleBookmark(recipeId);
  }

  Future<void> refreshCatalog() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(pantryRepositoryProvider);
      final recipes = await repo.getRecipes(forceRefresh: true);
      final ingredients = await repo.getMasterIngredients();
      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        clearError: true,
        masterIngredients: ingredients,
        recipes: recipes,
        matchedRecipes: _computeMatches(
          recipes: recipes,
          masterIngredients: ingredients,
          activeIds: state.activeIngredientIds,
          toolFilter: state.selectedToolFilter,
          searchQuery: state.searchQuery,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menyinkronkan katalog resep: $e',
      );
    }
  }

  Future<void> updateServerConfig({
    String? remoteUrl,
    String? baseUrl,
    bool? useLiveAi,
    String? geminiApiKey,
    String? geminiModel,
    bool? useOfflineSimulation,
  }) async {
    final config = ref.read(apiConfigProvider);
    if (remoteUrl != null) {
      config.updateRemoteJsonUrl(remoteUrl);
    }
    if (baseUrl != null) {
      config.updateLaravelBaseUrl(baseUrl);
    }
    if (geminiModel != null) {
      final trimmedModel = geminiModel.trim();
      config.updateGeminiModel(
        trimmedModel.isEmpty ? ApiConfig.defaultGeminiModel : trimmedModel,
      );
    }

    final resolvedOffline =
        useOfflineSimulation ??
        (useLiveAi != null ? !useLiveAi : state.useOfflineSimulation);
    final resolvedGeminiKey = geminiApiKey != null
        ? geminiApiKey.replaceAll(RegExp(r'\s+'), '')
        : state.geminiApiKey;

    state = state.copyWith(
      remoteJsonUrl: config.remoteJsonUrl,
      laravelBaseUrl: config.laravelBaseUrl,
      useLiveLaravelAi: !resolvedOffline,
      useOfflineSimulation: resolvedOffline,
      geminiApiKey: resolvedGeminiKey,
      geminiModel: config.geminiModel,
    );

    final prefs = await ref.read(sharedPreferencesProvider);
    await prefs.setString(geminiApiKeyPrefKey, resolvedGeminiKey);
    await prefs.setString(geminiModelPrefKey, config.geminiModel);
    await prefs.setBool(offlineSimulationPrefKey, resolvedOffline);
    await prefs.setString(remoteJsonUrlPrefKey, config.remoteJsonUrl);
    await prefs.setString(laravelBaseUrlPrefKey, config.laravelBaseUrl);
  }
}

/// Global Riverpod provider for PantryKos reactive pantry, filter & recipe state.
final pantryProvider = NotifierProvider<PantryNotifier, PantryState>(
  PantryNotifier.new,
);
