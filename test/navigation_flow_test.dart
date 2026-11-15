import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pantrykos_mobile/main.dart';
import 'package:pantrykos_mobile/models/recipe_model.dart';
import 'package:pantrykos_mobile/widgets/async_state_widgets.dart';
import 'package:pantrykos_mobile/widgets/cooking_mode_sheet.dart';

/// Smoke test that walks through every major flow at phone size and fails on
/// any layout overflow or framework exception.
void main() {
  testWidgets('Full navigation flow has no layout/runtime exceptions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Route/animation tickers start on the first frame after a push, so pump
    // twice (infinite animations rule out pumpAndSettle).
    Future<void> settle([int ms = 700]) async {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(Duration(milliseconds: ms));
    }

    await tester.pumpWidget(const PantryKosApp());
    await settle(900);
    expect(find.text('PantryKos'), findsOneWidget);
    expect(find.text('Memindai bahan anak kos...'), findsOneWidget);

    await settle(600);
    expect(find.text('Menyiapkan Kulkas Virtual...'), findsOneWidget);

    // Advance past 2.8s splash hold + 650ms CircularReveal transition into MainNavigation
    await settle(1400);
    await settle(750);
    expect(find.text('Kulkas Kos'), findsOneWidget);

    // Manage ingredients sheet
    await tester.tap(find.text('+ Kelola Bahan'));
    await settle(900);
    expect(find.text('Kelola Kulkas Virtual'), findsOneWidget);
    await tester.tap(find.textContaining('Simpan Kulkas'));
    await settle(900);

    // Recipe detail + cooking mode
    await tester.tap(find.text('Nasi Telur Ceplok Bawang Putih Kecap'));
    await settle(900);
    expect(find.text('Mulai Mode Masak'), findsOneWidget);
    await tester.tap(find.text('Mulai Mode Masak'));
    await settle(900);
    expect(find.textContaining('Langkah 1 /'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await settle(900);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await settle(900);

    // Bookmark tab -> remove -> empty state -> back to home
    await tester.tap(find.text('Tersimpan'));
    await settle();
    expect(find.text('Resep Tersimpan'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_rounded).last);
    await settle(600);
    expect(find.text('Belum Ada Resep Tersimpan'), findsOneWidget);
    await tester.tap(find.text('Kembali ke Kulkas Virtual'));
    await settle();
    expect(find.text('+ Kelola Bahan'), findsOneWidget);

    // Scanner
    await tester.tap(find.text('Scan AI'));
    await settle(900);
    expect(find.text('Pindai Bahan di Kulkas'), findsOneWidget);
    expect(find.text('Masukkan ke Kulkas (+)'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await settle(900);
    expect(find.text('Kulkas Kos'), findsOneWidget);

    // Quick Reset in Horizontal Pantry Dock
    expect(find.text('Reset'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await settle();
    expect(find.text('Isi Kulkasmu (0 Bahan Aktif)'), findsOneWidget);

    // Clear lingering Bookmark undo SnackBar before testing Home search filter
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).first),
    ).clearSnackBars();
    await settle();

    // Empty search -> NoMatchingRecipeWidget -> Reset Filter
    await tester.enterText(
      find.byType(TextField).first,
      'ResepTidakAdaXYZ123',
    );
    await settle();
    expect(find.byType(NoMatchingRecipeWidget), findsOneWidget);
    await tester.tap(find.text('Reset Filter'));
    await settle();
    expect(find.byType(NoMatchingRecipeWidget), findsNothing);

    // Info Proyek & Server Status Bottom Sheet
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await settle(900);
    expect(find.text('Info Proyek & Server Status'), findsOneWidget);
    expect(find.textContaining('Erlan Agam Putra'), findsOneWidget);
    expect(find.textContaining('Gamma Estu Mahardika'), findsOneWidget);
    expect(find.textContaining('Muhammad Fazli Nurfahmi'), findsOneWidget);
    expect(find.text('Offline Demo Simulation'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await settle();
    expect(find.text('Live Laravel AI'), findsOneWidget);
    await tester.tap(find.text('Simpan Konfigurasi'));
    await settle(900);

    // Back press on Home opens exit confirmation dialog; "Batal" keeps user inside app
    await tester.binding.handlePopRoute();
    await settle(500);
    expect(find.text('Keluar dari PantryKos?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await settle(500);
    expect(find.text('Keluar dari PantryKos?'), findsNothing);
    expect(find.text('Kulkas Kos'), findsOneWidget);
  });

  testWidgets('Async state widgets & CookingModeSheet fridge-update dialog', (
    WidgetTester tester,
  ) async {
    var retried = false;
    var removedUsed = false;

    const sampleRecipe = RecipeModel(
      id: 'test_recipe',
      title: 'Telur Ceplok Uji',
      subtitle: 'Cepat & Hemat',
      description: 'Telur ceplok praktis anak kos.',
      imageUrl: '',
      primaryAccent: Color(0xFF14532D),
      secondaryAccent: Color(0xFF22C55E),
      cookingTimeMinutes: 5,
      cookingTool: CookingTool.teflon,
      estimatedCostRupiah: 5000,
      calories: 210,
      difficulty: 'Mudah',
      servings: '1 Porsi',
      kosHackTip: 'Gunakan api kecil agar tidak gosong.',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '1 butir',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Masak Telur',
          instruction: 'Goreng telur hingga matang.',
          kosTip: 'Tutup teflon sebentar agar matang merata.',
          timerSeconds: 30,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const RecipeCardSkeleton(),
                const SizedBox(height: 12),
                ErrorBannerWidget(
                  message: 'Gagal memuat data resep.',
                  onRetry: () => retried = true,
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: ctx,
                        isScrollControlled: true,
                        builder: (_) => CookingModeSheet(
                          recipe: sampleRecipe,
                          onRemoveUsedIngredients: () => removedUsed = true,
                        ),
                      );
                    },
                    child: const Text('Buka Masak'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(RecipeCardSkeleton), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    expect(retried, isTrue);

    await tester.tap(find.text('Buka Masak'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Selesai Memasak'), findsOneWidget);
    await tester.tap(find.text('Selesai Memasak'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Ya, Perbarui Kulkas'), findsOneWidget);
    expect(find.text('Tetap Simpan Stok'), findsOneWidget);
    await tester.tap(find.text('Ya, Perbarui Kulkas'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(removedUsed, isTrue);
  });
}
