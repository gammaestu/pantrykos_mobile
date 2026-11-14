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

  /// Notifies listeners after a direct mutation of the shared sets.
  void notifyChanged() => notifyListeners();
}

