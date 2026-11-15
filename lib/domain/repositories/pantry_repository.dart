import '../entities/ingredient.dart';
import '../entities/recipe.dart';

/// Repository contract for PantryKos master catalog, recipes, and user state.
abstract class PantryRepository {
  /// Returns the master catalog of boarding-house ingredients.
  Future<List<Ingredient>> getMasterIngredients();

  /// Returns recipes; bypasses local cache when [forceRefresh] is true.
  Future<List<Recipe>> getRecipes({bool forceRefresh = false});

  /// Returns the currently active ingredient IDs in the user's Kulkas Virtual.
  Future<List<String>> getUserPantryIds();

  /// Persists the active ingredient IDs in the user's Kulkas Virtual.
  Future<void> saveUserPantryIds(List<String> ids);

  /// Returns the bookmarked recipe IDs.
  Future<List<String>> getBookmarkedIds();

  /// Toggles bookmark status for [recipeId].
  Future<void> toggleBookmark(String recipeId);
}
