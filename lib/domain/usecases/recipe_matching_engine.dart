import '../entities/ingredient.dart';
import '../entities/recipe.dart';
import '../entities/recipe_match_result.dart';

/// Pure business-logic use case that evaluates, filters, and ranks recipes
/// against the user's active Kulkas Virtual ingredients.
class RecipeMatchingEngine {
  const RecipeMatchingEngine();

  /// Evaluates [recipes] against [userPantryIds], maps missing IDs to human
  /// names using [masterIngredients], applies optional [toolType] and
  /// [searchQuery] filters, and sorts from 100% ready-to-cook ("Siap Masak")
  /// down to partial matches, then fewest missing items and fastest cook time.
  List<RecipeMatchResult> matchAndRank({
    required List<Recipe> recipes,
    required List<Ingredient> masterIngredients,
    required Iterable<String> userPantryIds,
    String? toolType,
    String searchQuery = '',
  }) {
    final ingredientById = <String, Ingredient>{
      for (final ingredient in masterIngredients) ingredient.id: ingredient,
    };
    final activePantrySet = userPantryIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final normalizedTool = toolType?.trim().toLowerCase() ?? '';
    final applyToolFilter =
        normalizedTool.isNotEmpty && normalizedTool != 'semua alat';
    final normalizedQuery = searchQuery.trim().toLowerCase();

    final results = <RecipeMatchResult>[];
    for (final recipe in recipes) {
      if (applyToolFilter &&
          recipe.toolType.trim().toLowerCase() != normalizedTool) {
        continue;
      }

      if (normalizedQuery.isNotEmpty &&
          !_matchesSearch(recipe, ingredientById, normalizedQuery)) {
        continue;
      }

      results.add(
        evaluateRecipe(
          recipe: recipe,
          ingredientById: ingredientById,
          activePantrySet: activePantrySet,
        ),
      );
    }

    results.sort(_compareMatchResults);
    return results;
  }

  /// Evaluates a single [recipe] against [activePantrySet].
  RecipeMatchResult evaluateRecipe({
    required Recipe recipe,
    required Map<String, Ingredient> ingredientById,
    required Set<String> activePantrySet,
  }) {
    final uniqueMainIds = <String>[];
    final seen = <String>{};
    for (final id in recipe.mainIngredients) {
      if (seen.add(id)) {
        uniqueMainIds.add(id);
      }
    }

    if (uniqueMainIds.isEmpty) {
      return RecipeMatchResult(
        recipe: recipe,
        matchPercentage: 100,
        matchedIngredientIds: const <String>[],
        missingIngredientNames: const <String>[],
      );
    }

    final matchedIds = <String>[];
    final missingNames = <String>[];

    for (final id in uniqueMainIds) {
      if (activePantrySet.contains(id)) {
        matchedIds.add(id);
      } else {
        missingNames.add(ingredientById[id]?.name ?? id);
      }
    }

    final percentage = ((matchedIds.length / uniqueMainIds.length) * 100)
        .round()
        .clamp(0, 100);

    return RecipeMatchResult(
      recipe: recipe,
      matchPercentage: percentage,
      matchedIngredientIds: List<String>.unmodifiable(matchedIds),
      missingIngredientNames: List<String>.unmodifiable(missingNames),
    );
  }

  bool _matchesSearch(
    Recipe recipe,
    Map<String, Ingredient> ingredientById,
    String query,
  ) {
    if (recipe.title.toLowerCase().contains(query) ||
        recipe.toolType.toLowerCase().contains(query)) {
      return true;
    }
    for (final seasoning in recipe.optionalSeasonings) {
      if (seasoning.toLowerCase().contains(query)) return true;
    }
    for (final id in recipe.mainIngredients) {
      final ingredient = ingredientById[id];
      if (ingredient != null && ingredient.matchesKeyword(query)) {
        return true;
      }
      if (id.toLowerCase().contains(query)) return true;
    }
    return false;
  }

  int _compareMatchResults(RecipeMatchResult a, RecipeMatchResult b) {
    // 1. 100% ready-to-cook ("Siap Masak") always ranks above partial matches.
    final aReady = a.isReadyToCook ? 0 : 1;
    final bReady = b.isReadyToCook ? 0 : 1;
    if (aReady != bReady) return aReady.compareTo(bReady);

    // 2. Fewer missing ingredients first.
    final missingCompare = a.missingCount.compareTo(b.missingCount);
    if (missingCompare != 0) return missingCompare;

    // 3. Higher match percentage first.
    final pctCompare = b.matchPercentage.compareTo(a.matchPercentage);
    if (pctCompare != 0) return pctCompare;

    // 4. Fastest cook time first.
    final timeCompare = a.recipe.cookTimeMin.compareTo(b.recipe.cookTimeMin);
    if (timeCompare != 0) return timeCompare;

    // 5. Lowest estimated cost as deterministic tie-breaker.
    return a.recipe.estimatedCost.compareTo(b.recipe.estimatedCost);
  }
}
