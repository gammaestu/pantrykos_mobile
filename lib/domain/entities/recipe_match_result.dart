import 'recipe.dart';

/// Pure domain value object representing how well a [Recipe] matches the
/// user's active Kulkas Virtual pantry ingredients.
class RecipeMatchResult {
  final Recipe recipe;
  final int matchPercentage;
  final List<String> matchedIngredientIds;
  final List<String> missingIngredientNames;

  const RecipeMatchResult({
    required this.recipe,
    required this.matchPercentage,
    required this.matchedIngredientIds,
    required this.missingIngredientNames,
  });

  bool get isReadyToCook =>
      missingIngredientNames.isEmpty && matchPercentage == 100;

  int get missingCount => missingIngredientNames.length;

  /// Human-readable Indonesian match badge summary:
  /// - `"100% Siap Masak"` when all main ingredients are present
  /// - `"Kurang 1 Bahan: Sawi"` when exactly 1 main ingredient is missing
  /// - `"Kurang N Bahan: ..."` when multiple ingredients are missing
  String get statusLabel {
    if (missingIngredientNames.isEmpty) {
      return '100% Siap Masak';
    }
    if (missingIngredientNames.length == 1) {
      return 'Kurang 1 Bahan: ${missingIngredientNames.first}';
    }
    final preview = missingIngredientNames.take(2).join(', ');
    if (missingIngredientNames.length <= 2) {
      return 'Kurang ${missingIngredientNames.length} Bahan: $preview';
    }
    return 'Kurang ${missingIngredientNames.length} Bahan: $preview, dll';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeMatchResult) return false;
    return other.recipe == recipe &&
        other.matchPercentage == matchPercentage &&
        _stringListEquals(other.matchedIngredientIds, matchedIngredientIds) &&
        _stringListEquals(other.missingIngredientNames, missingIngredientNames);
  }

  @override
  int get hashCode => Object.hash(
        recipe,
        matchPercentage,
        Object.hashAll(matchedIngredientIds),
        Object.hashAll(missingIngredientNames),
      );
}

bool _stringListEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
