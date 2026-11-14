import 'package:flutter/material.dart';

/// Categories for "Kulkas Virtual" ingredient filter tabs
enum IngredientCategory {
  semua('Semua', Icons.kitchen_rounded),
  karbohidrat('Karbohidrat', Icons.rice_bowl_rounded),
  protein('Protein', Icons.egg_alt_rounded),
  bumbuKos('Bumbu Kos', Icons.spa_rounded);

  final String label;
  final IconData icon;
  const IngredientCategory(this.label, this.icon);
}

/// Boarding-house cooking tools ("Alat Masak Anak Kos")
/// Ordered for the Ultra-Thin Tool Filter Strip:
/// "Semua Alat", "Rice Cooker", "Teflon", "Panci Listrik"
enum CookingTool {
  semuaAlat('Semua Alat', 'Semua Alat', Icons.restaurant_menu_rounded),
  riceCooker('Rice Cooker', 'Rice Cooker', Icons.soup_kitchen_rounded),
  teflon('Teflon', 'Teflon', Icons.local_fire_department_rounded),
  panciListrik('Panci Listrik', 'Panci Listrik', Icons.electric_bolt_rounded);

  final String filterLabel;
  final String badgeLabel;
  final IconData icon;
  const CookingTool(this.filterLabel, this.badgeLabel, this.icon);
}

/// Represents an ingredient chip in the user's "Kulkas Virtual"
class PantryIngredient {
  final String id;
  final String name;
  final String emoji;
  final IngredientCategory category;
  final String stockHint;

  const PantryIngredient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.stockHint,
  });
}

/// Represents a specific ingredient and quantity required by a recipe
class RecipeIngredientItem {
  final String ingredientId;
  final String displayName;
  final String measure;
  final bool isOptional;

  const RecipeIngredientItem({
    required this.ingredientId,
    required this.displayName,
    required this.measure,
    this.isOptional = false,
  });
}

/// Represents a single step in the Step-by-Step Cooking Mode
class CookingStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final String kosTip;
  final int? timerSeconds;
  final String? timerLabel;

  const CookingStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.kosTip,
    this.timerSeconds,
    this.timerLabel,
  });
}

/// Match tier for dynamic recipe cards
enum RecipeMatchTier {
  readyToCook, // 100% ingredients available
  almostReady, // Missing 1-2 ingredients
  needsShopping, // Missing >2 ingredients
}

/// Computed match result comparing a recipe against active Kulkas Virtual items
class RecipeMatchResult {
  final RecipeModel recipe;
  final List<RecipeIngredientItem> matchedIngredients;
  final List<RecipeIngredientItem> missingIngredients;
  final double matchRatio;

  const RecipeMatchResult({
    required this.recipe,
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.matchRatio,
  });

  int get matchPercentage => (matchRatio * 100).round();

  int get missingCount => missingIngredients.length;

  RecipeMatchTier get tier {
    if (missingIngredients.isEmpty) {
      return RecipeMatchTier.readyToCook;
    } else if (missingIngredients.length <= 2) {
      return RecipeMatchTier.almostReady;
    } else {
      return RecipeMatchTier.needsShopping;
    }
  }

  /// Dynamic badge text as specified in design requirements
  String get badgeText {
    if (missingIngredients.isEmpty) {
      return 'Siap Masak (100%)';
    }
    final missingNames = missingIngredients
        .take(2)
        .map((e) => e.displayName)
        .join(', ');
    if (missingIngredients.length <= 2) {
      return 'Kurang ${missingIngredients.length} Bahan (Kurang: $missingNames)';
    }
    return 'Kurang ${missingIngredients.length} Bahan (Kurang: $missingNames, dll)';
  }
}

/// Core Recipe data model for PantryKos
class RecipeModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final Color primaryAccent;
  final Color secondaryAccent;
  final int cookingTimeMinutes;
  final CookingTool cookingTool;
  final int estimatedCostRupiah;
  final int calories;
  final String difficulty;
  final String servings;
  final String kosHackTip;
  final List<RecipeIngredientItem> ingredients;
  final List<CookingStep> steps;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.cookingTimeMinutes,
    required this.cookingTool,
    required this.estimatedCostRupiah,
    required this.calories,
    required this.difficulty,
    required this.servings,
    required this.kosHackTip,
    required this.ingredients,
    required this.steps,
  });

  /// Formats Rupiah cleanly (e.g. 8000 -> "Rp 8.000")
  String get formattedCost {
    final digits = estimatedCostRupiah.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  String get formattedTime => '$cookingTimeMinutes Menit';

  /// Evaluates how well this recipe matches the user's active Kulkas Virtual
  RecipeMatchResult evaluateMatch(Set<String> activeIngredientIds) {
    final matched = <RecipeIngredientItem>[];
    final missing = <RecipeIngredientItem>[];

    for (final item in ingredients) {
      if (activeIngredientIds.contains(item.ingredientId)) {
        matched.add(item);
      } else {
        missing.add(item);
      }
    }

    final total = ingredients.isEmpty ? 1 : ingredients.length;
    final ratio = matched.length / total;

    return RecipeMatchResult(
      recipe: this,
      matchedIngredients: matched,
      missingIngredients: missing,
      matchRatio: ratio,
    );
  }
}

/// Represents a simulated AI-detected ingredient bounding box in the Scanner UI
class ScannedIngredientDetection {
  final String ingredientId;
  final String label;
  final int confidencePercent;
  final Rect normalizedBox; // 0.0 to 1.0 coordinates in viewfinder
  final String freshnessTag;

  const ScannedIngredientDetection({
    required this.ingredientId,
    required this.label,
    required this.confidencePercent,
    required this.normalizedBox,
    required this.freshnessTag,
  });
}
