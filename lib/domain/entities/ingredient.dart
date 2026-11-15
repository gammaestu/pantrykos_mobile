/// Pure domain entity representing a boarding-house kitchen ingredient.
class Ingredient {
  final String id;
  final String name;
  final String category;
  final String icon;
  final List<String> aliases;

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.aliases,
  });

  /// Returns true if [keyword] matches this ingredient's id, name, or aliases.
  bool matchesKeyword(String keyword) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (id.toLowerCase().contains(normalized) ||
        name.toLowerCase().contains(normalized)) {
      return true;
    }
    return aliases.any((alias) => alias.toLowerCase().contains(normalized));
  }

  Ingredient copyWith({
    String? id,
    String? name,
    String? category,
    String? icon,
    List<String>? aliases,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      aliases: aliases ?? this.aliases,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Ingredient) return false;
    return other.id == id &&
        other.name == name &&
        other.category == category &&
        other.icon == icon &&
        _listEquals(other.aliases, aliases);
  }

  @override
  int get hashCode =>
      Object.hash(id, name, category, icon, Object.hashAll(aliases));
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
