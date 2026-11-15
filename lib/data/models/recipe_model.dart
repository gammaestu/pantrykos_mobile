import 'dart:convert';
import '../../domain/entities/recipe.dart';
import 'ingredient_model.dart';

/// Data transfer model extending domain [RecipeStep] with JSON serialization.
class RecipeStepModel extends RecipeStep {
  const RecipeStepModel({
    required super.stepNumber,
    required super.instruction,
    super.timerSeconds,
  });

  factory RecipeStepModel.fromJson(Map<String, dynamic> json) {
    final rawStepNumber = json['step_number'];
    final rawTimer = json['timer_seconds'];

    return RecipeStepModel(
      stepNumber: rawStepNumber is num
          ? rawStepNumber.toInt()
          : int.tryParse(rawStepNumber?.toString() ?? '') ?? 1,
      instruction: (json['instruction'] ?? '').toString(),
      timerSeconds: rawTimer is num
          ? rawTimer.toInt()
          : int.tryParse(rawTimer?.toString() ?? ''),
    );
  }

  factory RecipeStepModel.fromEntity(RecipeStep entity) {
    return RecipeStepModel(
      stepNumber: entity.stepNumber,
      instruction: entity.instruction,
      timerSeconds: entity.timerSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'step_number': stepNumber,
      'instruction': instruction,
      if (timerSeconds != null) 'timer_seconds': timerSeconds,
    };
  }
}

/// Data transfer model extending domain [Recipe] with JSON serialization.
class RecipeModel extends Recipe {
  const RecipeModel({
    required super.id,
    required super.title,
    required super.imageUrl,
    required super.cookTimeMin,
    required super.estimatedCost,
    required super.toolType,
    required super.mainIngredients,
    required super.optionalSeasonings,
    required super.steps,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final rawCookTime = json['cook_time_min'];
    final rawCost = json['estimated_cost'];
    final rawMain = json['main_ingredients'];
    final rawOptional = json['optional_seasonings'];
    final rawSteps = json['steps'];

    return RecipeModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      cookTimeMin: rawCookTime is num
          ? rawCookTime.toInt()
          : int.tryParse(rawCookTime?.toString() ?? '') ?? 10,
      estimatedCost: rawCost is num
          ? rawCost.toInt()
          : int.tryParse(rawCost?.toString() ?? '') ?? 10000,
      toolType: (json['tool_type'] ?? 'Teflon').toString(),
      mainIngredients: rawMain is List
          ? rawMain.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      optionalSeasonings: rawOptional is List
          ? rawOptional.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      steps: rawSteps is List
          ? rawSteps
              .whereType<Map<String, dynamic>>()
              .map(RecipeStepModel.fromJson)
              .toList(growable: false)
          : const <RecipeStepModel>[],
    );
  }

  factory RecipeModel.fromEntity(Recipe entity) {
    return RecipeModel(
      id: entity.id,
      title: entity.title,
      imageUrl: entity.imageUrl,
      cookTimeMin: entity.cookTimeMin,
      estimatedCost: entity.estimatedCost,
      toolType: entity.toolType,
      mainIngredients: List<String>.unmodifiable(entity.mainIngredients),
      optionalSeasonings: List<String>.unmodifiable(entity.optionalSeasonings),
      steps: entity.steps
          .map(RecipeStepModel.fromEntity)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'cook_time_min': cookTimeMin,
      'estimated_cost': estimatedCost,
      'tool_type': toolType,
      'main_ingredients': mainIngredients,
      'optional_seasonings': optionalSeasonings,
      'steps': steps
          .map((s) => RecipeStepModel.fromEntity(s).toJson())
          .toList(growable: false),
    };
  }
}

/// Parsed root catalog bundle containing ingredients, recipes, and raw JSON string.
class PantryCatalogBundle {
  final List<IngredientModel> ingredients;
  final List<RecipeModel> recipes;
  final String rawJson;

  const PantryCatalogBundle({
    required this.ingredients,
    required this.recipes,
    required this.rawJson,
  });

  /// Parses raw catalog JSON string into typed models.
  /// Throws [FormatException] if required root keys are missing or invalid.
  factory PantryCatalogBundle.fromRawJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Catalog JSON root must be a JSON object.');
    }

    final rawIngredients = decoded['ingredients'];
    final rawRecipes = decoded['recipes'];
    if (rawIngredients is! List || rawRecipes is! List) {
      throw const FormatException(
        'Catalog JSON must contain "ingredients" and "recipes" lists.',
      );
    }

    final ingredients = rawIngredients
        .whereType<Map<String, dynamic>>()
        .map(IngredientModel.fromJson)
        .toList(growable: false);
    final recipes = rawRecipes
        .whereType<Map<String, dynamic>>()
        .map(RecipeModel.fromJson)
        .toList(growable: false);

    return PantryCatalogBundle(
      ingredients: ingredients,
      recipes: recipes,
      rawJson: rawJson,
    );
  }
}
