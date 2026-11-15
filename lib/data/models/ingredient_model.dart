import '../../domain/entities/ingredient.dart';

/// Data transfer model extending the pure domain [Ingredient] entity
/// with JSON serialization.
class IngredientModel extends Ingredient {
  const IngredientModel({
    required super.id,
    required super.name,
    required super.category,
    required super.icon,
    required super.aliases,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    final parsedAliases = rawAliases is List
        ? rawAliases.map((item) => item.toString()).toList(growable: false)
        : const <String>[];

    return IngredientModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'Bumbu Kos').toString(),
      icon: (json['icon'] ?? '🥬').toString(),
      aliases: parsedAliases,
    );
  }

  factory IngredientModel.fromEntity(Ingredient entity) {
    return IngredientModel(
      id: entity.id,
      name: entity.name,
      category: entity.category,
      icon: entity.icon,
      aliases: List<String>.unmodifiable(entity.aliases),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category,
      'icon': icon,
      'aliases': aliases,
    };
  }
}
