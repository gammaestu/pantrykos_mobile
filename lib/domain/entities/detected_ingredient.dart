/// Pure domain entity representing a single ingredient detected by AI Vision.
class DetectedIngredient {
  const DetectedIngredient({
    required this.ingredientId,
    required this.detectedName,
    required this.confidence,
    required this.isMatchedToDatabase,
  });

  /// Canonical database ingredient ID (e.g., `"telur"`, `"mie_instan"`).
  final String ingredientId;

  /// Human-readable Indonesian ingredient name reported by AI or database.
  final String detectedName;

  /// Detection confidence normalized within `[0.0, 1.0]`.
  final double confidence;

  /// Whether [ingredientId] matched a valid entry in `masterIngredients`.
  final bool isMatchedToDatabase;

  DetectedIngredient copyWith({
    String? ingredientId,
    String? detectedName,
    double? confidence,
    bool? isMatchedToDatabase,
  }) {
    return DetectedIngredient(
      ingredientId: ingredientId ?? this.ingredientId,
      detectedName: detectedName ?? this.detectedName,
      confidence: confidence ?? this.confidence,
      isMatchedToDatabase: isMatchedToDatabase ?? this.isMatchedToDatabase,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectedIngredient &&
        other.ingredientId == ingredientId &&
        other.detectedName == detectedName &&
        other.confidence == confidence &&
        other.isMatchedToDatabase == isMatchedToDatabase;
  }

  @override
  int get hashCode =>
      Object.hash(ingredientId, detectedName, confidence, isMatchedToDatabase);

  @override
  String toString() =>
      'DetectedIngredient(id: $ingredientId, name: $detectedName, '
      'confidence: ${confidence.toStringAsFixed(2)}, matched: $isMatchedToDatabase)';
}
