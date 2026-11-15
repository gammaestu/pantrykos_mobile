import 'package:flutter/foundation.dart';
import '../data/mock_pantry_data.dart';

/// Lightweight shared state for the whole app (no backend yet).
/// Holds the active "Kulkas Virtual" ingredients and bookmarked recipes so
/// the Home, Bookmark and Scanner flows always stay in sync.
class PantryController extends ChangeNotifier {
  PantryController()
      : activeIngredientIds = Set<String>.from(
          MockPantryData.defaultActiveIngredientIds,
        ),
        bookmarkedRecipeIds = <String>{'nasgor_mawut_magiccom'};

  /// Active ingredient ids currently in the virtual fridge.
  /// Screens may mutate this set directly; call [notifyChanged] afterwards.
  final Set<String> activeIngredientIds;

  /// Bookmarked recipe ids.
  final Set<String> bookmarkedRecipeIds;

  /// Runtime Laravel API Base URL (configurable in Info Proyek & Server Status).
  String apiBaseUrl = 'http://10.0.2.2:8000/api';

  /// Whether AI scan & recipe calls target Live Laravel AI vs Offline Demo Simulation.
  bool useLiveLaravelAi = false;

  bool isBookmarked(String recipeId) => bookmarkedRecipeIds.contains(recipeId);

  void toggleBookmark(String recipeId) {
    if (!bookmarkedRecipeIds.remove(recipeId)) {
      bookmarkedRecipeIds.add(recipeId);
    }
    notifyListeners();
  }

  void addIngredients(Iterable<String> ids) {
    activeIngredientIds.addAll(ids);
    notifyListeners();
  }

  void removeIngredients(Iterable<String> ids) {
    activeIngredientIds.removeAll(ids);
    notifyListeners();
  }

  void clearIngredients() {
    if (activeIngredientIds.isEmpty) return;
    activeIngredientIds.clear();
    notifyListeners();
  }

  void updateServerConfig({
    required String baseUrl,
    required bool useLiveAi,
  }) {
    final trimmed = baseUrl.trim();
    if (trimmed.isNotEmpty) {
      apiBaseUrl = trimmed;
    }
    useLiveLaravelAi = useLiveAi;
    notifyListeners();
  }

  /// Notifies listeners after a direct mutation of the shared sets.
  void notifyChanged() => notifyListeners();
}

