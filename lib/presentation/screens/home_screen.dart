import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/ingredient.dart' as domain;
import '../mappers/pantry_ui_mapper.dart';
import '../models/ui_recipe_model.dart';
import '../providers/pantry_provider.dart';
import '../widgets/ai_settings_sheet.dart';
import '../widgets/animated_ingredient_chip.dart';
import '../widgets/async_state_widgets.dart';
import '../widgets/cooker_filter_header.dart';
import '../widgets/pantrykos_logo.dart';
import '../widgets/recipe_matcher_card.dart';
import 'recipe_detail_screen.dart';

/// Main Dashboard & Space-Saving "Kulkas Virtual" Home Screen for PantryKos.
/// Driven reactively by [pantryProvider] in the Clean Culinary Light Theme
/// (#F6FAF7, #FFFFFF, #14532D, #DCFCE7).
class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenScanner;

  const HomeScreen({
    super.key,
    required this.onOpenScanner,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PantryIngredient> _orderedDockIngredients(
    List<domain.Ingredient> masterIngredients,
    Set<String> activeIds,
  ) {
    final active = <PantryIngredient>[];
    final inactive = <PantryIngredient>[];
    for (final ing in masterIngredients) {
      final uiIng = PantryUiMapper.toUiIngredient(ing);
      if (activeIds.contains(ing.id)) {
        active.add(uiIng);
      } else {
        inactive.add(uiIng);
      }
    }
    return <PantryIngredient>[...active, ...inactive];
  }

  /// Opens the Draggable Glassmorphic Bottom Sheet for full ingredient management
  Future<void> _openManageIngredientsSheet() async {
    HapticFeedback.mediumImpact();
    var modalCategory = IngredientCategory.semua;
    var modalSearch = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, sheetRef, _) {
                final pantryState = sheetRef.watch(pantryProvider);
                final notifier = sheetRef.read(pantryProvider.notifier);
                final allUiIngredients = pantryState.masterIngredients
                    .map(PantryUiMapper.toUiIngredient)
                    .toList(growable: false);
                final activeIds = pantryState.activeIngredientIds;

                final filteredList = allUiIngredients.where((item) {
                  final matchesCat =
                      modalCategory == IngredientCategory.semua ||
                      item.category == modalCategory;
                  final query = modalSearch.trim().toLowerCase();
                  final matchesQuery =
                      query.isEmpty ||
                      item.name.toLowerCase().contains(query);
                  return matchesCat && matchesQuery;
                }).toList(growable: false);

                final allSelected =
                    allUiIngredients.isNotEmpty &&
                    activeIds.length >= allUiIngredients.length;

                return DraggableScrollableSheet(
                  initialChildSize: 0.72,
                  minChildSize: 0.50,
                  maxChildSize: 0.92,
                  expand: false,
                  builder: (context, scrollController) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite.withValues(alpha: 0.96),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            border: const Border(
                              top: BorderSide(
                                color: AppTheme.borderMint,
                                width: 1.2,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 42,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: AppTheme.borderSlateLight,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        const PantryKosLogoMark(size: 38),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Kelola Kulkas Virtual',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme
                                                      .textForestCharcoal,
                                                ),
                                              ),
                                              Text(
                                                '${activeIds.length} dari ${allUiIngredients.length} bahan tersedia di kos',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppTheme.textSageGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            HapticFeedback.selectionClick();
                                            if (allSelected) {
                                              notifier.resetPantry();
                                            } else {
                                              notifier.addDetectedIngredients(
                                                allUiIngredients
                                                    .map((e) => e.id)
                                                    .toList(growable: false),
                                              );
                                            }
                                          },
                                          child: Text(
                                            allSelected
                                                ? 'Kosongkan'
                                                : 'Pilih Semua',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.forestEmerald,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Search inside Bottom Sheet
                                    TextField(
                                      onChanged: (val) {
                                        setModalState(() => modalSearch = val);
                                      },
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppTheme.textForestCharcoal,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Cari bahan (misal: Telur, Sosis, Keju, Cabai)...',
                                        hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSageGrey,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          size: 19,
                                          color: AppTheme.forestEmerald,
                                        ),
                                        fillColor: AppTheme.scaffoldMintWhite,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Category Filter Tabs inside Sheet
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: IngredientCategory.values.map(
                                          (cat) {
                                            final selected =
                                                cat == modalCategory;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setModalState(
                                                    () => modalCategory = cat,
                                                  );
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 13,
                                                    vertical: 7,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: selected
                                                        ? AppTheme.forestEmerald
                                                        : AppTheme.pureWhite,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    border: Border.all(
                                                      color: selected
                                                          ? AppTheme
                                                                .forestEmerald
                                                          : AppTheme
                                                                .borderSlateLight,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        cat.icon,
                                                        size: 14,
                                                        color: selected
                                                            ? AppTheme.pureWhite
                                                            : AppTheme
                                                                  .textSageGrey,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        cat.label,
                                                        style: TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: selected
                                                              ? FontWeight.w700
                                                              : FontWeight.w600,
                                                          color: selected
                                                              ? AppTheme
                                                                    .pureWhite
                                                              : AppTheme
                                                                    .textForestCharcoal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(growable: false),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Divider(
                                height: 16,
                                color: AppTheme.borderNeutral,
                              ),

                              Expanded(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    8,
                                    20,
                                    24,
                                  ),
                                  child: Wrap(
                                    spacing: 9,
                                    runSpacing: 10,
                                    children: filteredList.map((ing) {
                                      final isSelected =
                                          activeIds.contains(ing.id);
                                      return AnimatedIngredientChip(
                                        key: ValueKey('modal_chip_${ing.id}'),
                                        ingredient: ing,
                                        isSelected: isSelected,
                                        onTap: () =>
                                            notifier.toggleIngredient(ing.id),
                                      );
                                    }).toList(growable: false),
                                  ),
                                ),
                              ),

                              // Bottom Done CTA
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 20),
                                decoration: const BoxDecoration(
                                  color: AppTheme.pureWhite,
                                  border: Border(
                                    top: BorderSide(
                                      color: AppTheme.borderNeutral,
                                    ),
                                  ),
                                ),
                                child: SafeArea(
                                  top: false,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: AppTheme.glowShadow(
                                          AppTheme.forestEmerald,
                                          alpha: 0.24,
                                        ),
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            Navigator.of(sheetCtx).pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 15,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.check_circle_rounded,
                                          size: 19,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          'Simpan Kulkas (${activeIds.length} Bahan Aktif)',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _openRecipeDetail(RecipeModel recipe, PantryState pantryState) {
    final notifier = ref.read(pantryProvider.notifier);
    final ingredientIcons = <String, String>{
      for (final ing in pantryState.masterIngredients) ing.id: ing.icon,
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          activeIngredientIds: pantryState.activeIngredientIds,
          initialBookmarked: pantryState.bookmarkedIds.contains(recipe.id),
          onBookmarkToggle: () => notifier.toggleBookmark(recipe.id),
          onTogglePantryIngredient: (ingredientId) =>
              notifier.addDetectedIngredients(<String>[ingredientId]),
          onConsumeIngredients: (usedIds) =>
              notifier.removeUsedIngredients(usedIds.toList(growable: false)),
          ingredientIcons: ingredientIcons,
        ),
      ),
    );
  }

  void _openServerInfoSheet() {
    showAiSettingsSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final pantryState = ref.watch(pantryProvider);
    final notifier = ref.read(pantryProvider.notifier);

    final ingredientById = <String, domain.Ingredient>{
      for (final ing in pantryState.masterIngredients) ing.id: ing,
    };

    final uiMatches = pantryState.matchedRecipes
        .map(
          (match) => PantryUiMapper.toUiMatchResult(
            match,
            ingredientById: ingredientById,
          ),
        )
        .toList(growable: false);

    final ready100Count = uiMatches
        .where((r) => r.tier == RecipeMatchTier.readyToCook)
        .length;
    final dockIngredients = _orderedDockIngredients(
      pantryState.masterIngredients,
      pantryState.activeIngredientIds,
    );
    final selectedTool = PantryUiMapper.toUiTool(
      pantryState.selectedToolFilter,
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldMintWhite,
      body: CustomScrollView(
        key: const PageStorageKey<String>('home_scroll'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          // A. Streamlined Collapsing SliverAppBar (Brand Lockup + Sleek Search Bar)
          SliverAppBar(
            expandedHeight: 132,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.scaffoldMintWhite,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 16,
            title: const PantryKosBrandLockup(),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  tooltip: 'Info Proyek & Server Status',
                  onPressed: _openServerInfoSheet,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.pureWhite,
                    foregroundColor: AppTheme.forestEmerald,
                    side: const BorderSide(color: AppTheme.borderMint),
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 62, 16, 8),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        onChanged: notifier.setSearchQuery,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppTheme.textForestCharcoal,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Cari resep "Mawut", "Omelet", atau bahan...',
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSageGrey,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: AppTheme.forestEmerald,
                          ),
                          suffixIcon: pantryState.searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    notifier.setSearchQuery('');
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 17,
                                    color: AppTheme.textSageGrey,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // B. Compact Pantry Dock (Max height: 110px, Single-Row Horizontal Chips)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 110),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.borderMint,
                          width: 1.2,
                        ),
                        boxShadow: AppTheme.softShadow(context),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.kitchen_rounded,
                                size: 15,
                                color: AppTheme.forestEmerald,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Isi Kulkasmu (${pantryState.activeIngredientIds.length} Bahan Aktif)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textForestCharcoal,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (pantryState.activeIngredientIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      notifier.resetPantry();
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sageMint,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.borderMint,
                                        ),
                                      ),
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.forestEmerald,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              InkWell(
                                onTap: _openManageIngredientsSheet,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '+ Kelola Bahan',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.forestEmerald,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          SizedBox(
                            height: 46,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: dockIngredients.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final ing = dockIngredients[index];
                                final isSelected = pantryState
                                    .activeIngredientIds
                                    .contains(ing.id);
                                return Center(
                                  child: AnimatedIngredientChip(
                                    key: ValueKey('dock_chip_${ing.id}'),
                                    ingredient: ing,
                                    isSelected: isSelected,
                                    compact: true,
                                    showRemoveIconWhenSelected: true,
                                    onTap: () =>
                                        notifier.toggleIngredient(ing.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // C. Ultra-Thin Tool Filter Strip (height: 38px chip row inside sticky header)
          SliverPersistentHeader(
            pinned: true,
            delegate: CookerFilterHeaderDelegate(
              selectedTool: selectedTool,
              matchingRecipeCount: uiMatches.length,
              readyNowCount: ready100Count,
              onToolSelected: (tool) {
                notifier.setToolFilter(tool.filterLabel);
              },
            ),
          ),

          // D. Loading Skeletons / Error Banner / Smart Recipe Matcher Cards
          if (pantryState.isLoading && uiMatches.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 136),
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, _) => const RecipeCardSkeleton(),
              ),
            )
          else if (pantryState.errorMessage != null && uiMatches.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                child: ErrorBannerWidget(
                  message: pantryState.errorMessage!,
                  onRetry: notifier.refreshCatalog,
                ),
              ),
            )
          else if (uiMatches.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: NoMatchingRecipeWidget(
                  onResetFilter: () {
                    _searchController.clear();
                    notifier.setToolFilter(CookingTool.semuaAlat.filterLabel);
                    notifier.setSearchQuery('');
                  },
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 136),
              sliver: SliverList.separated(
                itemCount: uiMatches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final match = uiMatches[index];
                  return RecipeMatcherCard(
                    key: ValueKey('card_${match.recipe.id}'),
                    matchResult: match,
                    animationIndex: index,
                    isBookmarked: pantryState.bookmarkedIds.contains(
                      match.recipe.id,
                    ),
                    onBookmarkToggle: () =>
                        notifier.toggleBookmark(match.recipe.id),
                    onTap: () => _openRecipeDetail(match.recipe, pantryState),
                    onQuickAddMissingIngredient: (missingId) =>
                        notifier.addDetectedIngredients(<String>[missingId]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
