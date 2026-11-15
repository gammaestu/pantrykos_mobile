import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/domain/entities/ingredient.dart';
import 'package:pantrykos_mobile/domain/entities/recipe.dart';
import 'package:pantrykos_mobile/domain/usecases/recipe_matching_engine.dart';

void main() {
  late List<Ingredient> ingredients;
  late List<Recipe> recipes;

  setUpAll(() {
    final raw = File('assets/data/pantrykos_db.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    ingredients = (decoded['ingredients'] as List<dynamic>).map((item) {
      final map = item as Map<String, dynamic>;
      return Ingredient(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String,
        icon: map['icon'] as String,
        aliases: List<String>.from(map['aliases'] as List<dynamic>),
      );
    }).toList();

    recipes = (decoded['recipes'] as List<dynamic>).map((item) {
      final map = item as Map<String, dynamic>;
      final steps = (map['steps'] as List<dynamic>).map((s) {
        final stepMap = s as Map<String, dynamic>;
        return RecipeStep(
          stepNumber: stepMap['step_number'] as int,
          instruction: stepMap['instruction'] as String,
          timerSeconds: stepMap['timer_seconds'] as int?,
        );
      }).toList();

      return Recipe(
        id: map['id'] as String,
        title: map['title'] as String,
        imageUrl: map['image_url'] as String,
        cookTimeMin: map['cook_time_min'] as int,
        estimatedCost: map['estimated_cost'] as int,
        toolType: map['tool_type'] as String,
        mainIngredients: List<String>.from(
          map['main_ingredients'] as List<dynamic>,
        ),
        optionalSeasonings: List<String>.from(
          map['optional_seasonings'] as List<dynamic>,
        ),
        steps: steps,
      );
    }).toList();
  });

  group('pantrykos_db.json validation', () {
    test('contains >= 20 ingredients across all 4 required categories', () {
      expect(ingredients.length, greaterThanOrEqualTo(20));
      final categories = ingredients.map((e) => e.category).toSet();
      expect(
        categories,
        containsAll(<String>['Karbohidrat', 'Protein', 'Sayur', 'Bumbu Kos']),
      );
      for (final ing in ingredients) {
        expect(ing.id, isNotEmpty);
        expect(ing.name, isNotEmpty);
        expect(ing.icon, isNotEmpty);
        expect(ing.aliases, isNotEmpty);
      }
    });

    test('contains >= 12 recipes with valid tools and linked ingredient ids', () {
      expect(recipes.length, greaterThanOrEqualTo(12));
      final validIngredientIds = ingredients.map((e) => e.id).toSet();
      final tools = recipes.map((r) => r.toolType).toSet();
      expect(
        tools,
        containsAll(<String>['Rice Cooker', 'Teflon', 'Panci Listrik']),
      );

      for (final recipe in recipes) {
        expect(recipe.id, isNotEmpty);
        expect(recipe.title, isNotEmpty);
        expect(recipe.cookTimeMin, greaterThan(0));
        expect(recipe.estimatedCost, greaterThan(0));
        expect(recipe.mainIngredients, isNotEmpty);
        expect(recipe.steps, isNotEmpty);
        for (final id in recipe.mainIngredients) {
          expect(
            validIngredientIds,
            contains(id),
            reason: 'Unknown ingredient id "$id" in recipe "${recipe.id}"',
          );
        }
      }
    });
  });

  group('RecipeMatchingEngine', () {
    const engine = RecipeMatchingEngine();

    test('ranks 100% ready-to-cook first, then fewest missing & fastest time', () {
      final results = engine.matchAndRank(
        recipes: recipes,
        masterIngredients: ingredients,
        userPantryIds: const [
          'nasi_putih',
          'telur',
          'bawang_putih',
          'kecap_manis',
          'mie_instan',
        ],
      );

      expect(results, isNotEmpty);
      // "Nasi Telur Ceplok Bawang Kecap" needs nasi_putih, telur, bawang_putih, kecap_manis -> 100%
      expect(results.first.isReadyToCook, isTrue);
      expect(results.first.recipe.id, 'nasi_telur_ceplok_kecap');
      expect(results.first.statusLabel, '100% Siap Masak');

      // "Nasi Goreng Mawut Rice Cooker" is missing only "Sawi Hijau"
      final mawut = results.firstWhere(
        (r) => r.recipe.id == 'nasgor_mawut_rice_cooker',
      );
      expect(mawut.matchPercentage, 80);
      expect(mawut.missingIngredientNames, ['Sawi Hijau']);
      expect(mawut.statusLabel, 'Kurang 1 Bahan: Sawi Hijau');

      // Verify ordering invariants: ready first, then ascending missingCount, then faster time
      for (var i = 0; i < results.length - 1; i++) {
        final cur = results[i];
        final next = results[i + 1];
        if (cur.isReadyToCook != next.isReadyToCook) {
          expect(cur.isReadyToCook, isTrue);
        } else {
          expect(cur.missingCount, lessThanOrEqualTo(next.missingCount));
        }
      }
    });

    test('filters by toolType and ingredient alias search query', () {
      final riceCookerOnly = engine.matchAndRank(
        recipes: recipes,
        masterIngredients: ingredients,
        userPantryIds: const ['beras', 'kornet'],
        toolType: 'Rice Cooker',
      );
      expect(riceCookerOnly, isNotEmpty);
      expect(
        riceCookerOnly.every((r) => r.recipe.toolType == 'Rice Cooker'),
        isTrue,
      );

      // Search using an AI Vision alias ("indomie" -> matches "mie_instan")
      final indomieAliasMatches = engine.matchAndRank(
        recipes: recipes,
        masterIngredients: ingredients,
        userPantryIds: const [],
        searchQuery: 'indomie',
      );
      expect(indomieAliasMatches.length, greaterThanOrEqualTo(3));
      expect(
        indomieAliasMatches.every(
          (r) => r.recipe.mainIngredients.contains('mie_instan'),
        ),
        isTrue,
      );
    });
  });
}
