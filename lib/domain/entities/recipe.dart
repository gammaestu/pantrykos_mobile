/// Single preparation/cooking instruction inside a [Recipe].
class RecipeStep {
  final int stepNumber;
  final String instruction;
  final int? timerSeconds;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.timerSeconds,
  });

  RecipeStep copyWith({
    int? stepNumber,
    String? instruction,
    int? timerSeconds,
  }) {
    return RecipeStep(
      stepNumber: stepNumber ?? this.stepNumber,
      instruction: instruction ?? this.instruction,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeStep &&
        other.stepNumber == stepNumber &&
        other.instruction == instruction &&
        other.timerSeconds == timerSeconds;
  }

  @override
  int get hashCode => Object.hash(stepNumber, instruction, timerSeconds);
}

/// Pure domain entity representing an Indonesian anak-kos recipe.
class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int cookTimeMin;
  final int estimatedCost;
  final String toolType;
  final List<String> mainIngredients;
  final List<String> optionalSeasonings;
  final List<RecipeStep> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.cookTimeMin,
    required this.estimatedCost,
    required this.toolType,
    required this.mainIngredients,
    required this.optionalSeasonings,
    required this.steps,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? imageUrl,
    int? cookTimeMin,
    int? estimatedCost,
    String? toolType,
    List<String>? mainIngredients,
    List<String>? optionalSeasonings,
    List<RecipeStep>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      cookTimeMin: cookTimeMin ?? this.cookTimeMin,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      toolType: toolType ?? this.toolType,
      mainIngredients: mainIngredients ?? this.mainIngredients,
      optionalSeasonings: optionalSeasonings ?? this.optionalSeasonings,
      steps: steps ?? this.steps,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Recipe) return false;
    return other.id == id &&
        other.title == title &&
        other.imageUrl == imageUrl &&
        other.cookTimeMin == cookTimeMin &&
        other.estimatedCost == estimatedCost &&
        other.toolType == toolType &&
        _stringListEquals(other.mainIngredients, mainIngredients) &&
        _stringListEquals(other.optionalSeasonings, optionalSeasonings) &&
        _stepListEquals(other.steps, steps);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        imageUrl,
        cookTimeMin,
        estimatedCost,
        toolType,
        Object.hashAll(mainIngredients),
        Object.hashAll(optionalSeasonings),
        Object.hashAll(steps),
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

bool _stepListEquals(List<RecipeStep> a, List<RecipeStep> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
