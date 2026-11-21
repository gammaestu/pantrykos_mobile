import '../../core/theme/app_theme.dart';
import '../../domain/entities/ingredient.dart' as domain;
import '../../domain/entities/recipe.dart' as domain;
import '../../domain/entities/recipe_match_result.dart' as domain;
import '../models/ui_recipe_model.dart' as ui;

/// Presentation-layer mapper adapting pure domain entities from `lib/domain/`
/// into existing UI widget models (`lib/models/recipe_model.dart`) so every
/// lush card, detail view, and cooking timer works seamlessly with Riverpod.
class PantryUiMapper {
  PantryUiMapper._();

  static ui.IngredientCategory toUiCategory(String rawCategory) {
    switch (rawCategory.trim().toLowerCase()) {
      case 'karbohidrat':
        return ui.IngredientCategory.karbohidrat;
      case 'protein':
        return ui.IngredientCategory.protein;
      case 'sayur':
        return ui.IngredientCategory.sayur;
      default:
        return ui.IngredientCategory.bumbuKos;
    }
  }

  static ui.CookingTool toUiTool(String rawTool) {
    switch (rawTool.trim().toLowerCase()) {
      case 'rice cooker':
        return ui.CookingTool.riceCooker;
      case 'teflon':
        return ui.CookingTool.teflon;
      case 'panci listrik':
        return ui.CookingTool.panciListrik;
      default:
        return ui.CookingTool.semuaAlat;
    }
  }

  static ui.PantryIngredient toUiIngredient(domain.Ingredient item) {
    final stockHint = item.aliases.isNotEmpty
        ? 'Alias: ${item.aliases.take(2).join(', ')}'
        : item.category;
    return ui.PantryIngredient(
      id: item.id,
      name: item.name,
      emoji: item.icon,
      category: toUiCategory(item.category),
      stockHint: stockHint,
    );
  }

  static ui.RecipeModel toUiRecipe(
    domain.Recipe recipe, {
    required Map<String, domain.Ingredient> ingredientById,
  }) {
    final tool = toUiTool(recipe.toolType);
    final ingredients = <ui.RecipeIngredientItem>[
      for (final id in recipe.mainIngredients)
        ui.RecipeIngredientItem(
          ingredientId: id,
          displayName: ingredientById[id]?.name ?? id,
          measure: 'Secukupnya',
        ),
      for (final seasoning in recipe.optionalSeasonings)
        ui.RecipeIngredientItem(
          ingredientId: 'opt_${seasoning.toLowerCase().replaceAll(' ', '_')}',
          displayName: seasoning,
          measure: 'Opsional',
          isOptional: true,
        ),
    ];

    final steps = recipe.steps
        .map(
          (step) => ui.CookingStep(
            stepNumber: step.stepNumber,
            title: 'Langkah ${step.stepNumber}',
            instruction: step.instruction,
            kosTip:
                'Gunakan ${tool.badgeLabel} dengan api/mode stabil agar matang merata.',
            timerSeconds: step.timerSeconds,
            timerLabel: step.timerSeconds != null
                ? 'Timer Langkah ${step.stepNumber}'
                : null,
          ),
        )
        .toList(growable: false);

    return ui.RecipeModel(
      id: recipe.id,
      title: recipe.title,
      subtitle:
          '${tool.badgeLabel} • ${recipe.cookTimeMin} Menit • Hemat Anak Kos',
      description:
          'Resep praktis ${recipe.title} dimasak menggunakan ${tool.badgeLabel} dengan estimasi modal Rp ${_formatRupiah(recipe.estimatedCost)}.',
      imageUrl: recipe.imageUrl,
      primaryAccent: AppTheme.forestEmerald,
      secondaryAccent: AppTheme.mintLeaf,
      cookingTimeMinutes: recipe.cookTimeMin,
      cookingTool: tool,
      estimatedCostRupiah: recipe.estimatedCost,
      calories: 320 + (recipe.mainIngredients.length * 45),
      difficulty: recipe.cookTimeMin <= 12 ? 'Sangat Mudah' : 'Mudah',
      servings: '1-2 Porsi',
      kosHackTip: recipe.optionalSeasonings.isNotEmpty
          ? 'Tambahkan ${recipe.optionalSeasonings.first} untuk rasa lebih nikmat.'
          : 'Siapkan bahan terlebih dahulu agar masak makin cepat.',
      ingredients: ingredients,
      steps: steps,
    );
  }

  static ui.RecipeMatchResult toUiMatchResult(
    domain.RecipeMatchResult match, {
    required Map<String, domain.Ingredient> ingredientById,
  }) {
    final uiRecipe = toUiRecipe(match.recipe, ingredientById: ingredientById);
    final matchedSet = match.matchedIngredientIds.toSet();
    final mainItems = uiRecipe.ingredients.where((i) => !i.isOptional).toList();

    final matched = mainItems
        .where((i) => matchedSet.contains(i.ingredientId))
        .toList(growable: false);
    final missing = mainItems
        .where((i) => !matchedSet.contains(i.ingredientId))
        .toList(growable: false);

    return ui.RecipeMatchResult(
      recipe: uiRecipe,
      matchedIngredients: matched,
      missingIngredients: missing,
      matchRatio: (match.matchPercentage / 100.0).clamp(0.0, 1.0),
    );
  }

  static String _formatRupiah(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
