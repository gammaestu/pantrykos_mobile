import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_pantry_data.dart';
import '../models/recipe_model.dart';
import '../state/pantry_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_ingredient_chip.dart';
import '../widgets/async_state_widgets.dart';
import '../widgets/cooker_filter_header.dart';
import '../widgets/pantrykos_logo.dart';
import '../widgets/recipe_matcher_card.dart';
import 'recipe_detail_screen.dart';

/// Main Dashboard & Space-Saving "Kulkas Virtual" Home Screen for PantryKos.
/// Designed with the Clean Culinary Light Theme (#F6FAF7, #FFFFFF, #14532D, #DCFCE7)
/// and an "Above-the-Fold" layout so Recipe Matcher Cards are immediately visible.
class HomeScreen extends StatefulWidget {
  final PantryController controller;
  final VoidCallback onOpenScanner;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.onOpenScanner,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String> get _activeIngredientIds => widget.controller.activeIngredientIds;
  Set<String> get _bookmarkedRecipeIds =>
      widget.controller.bookmarkedRecipeIds;
  CookingTool _selectedTool = CookingTool.semuaAlat;
  String _searchQuery = '';

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

  /// Every local mutation of the shared pantry/bookmark sets goes through
  /// setState, so we also notify the controller to keep the Bookmark tab and
  /// the navigation badge in sync.
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    widget.controller.notifyChanged();
  }

  void _toggleIngredient(String id) {
    setState(() {
      if (_activeIngredientIds.contains(id)) {
        _activeIngredientIds.remove(id);
      } else {
        _activeIngredientIds.add(id);
      }
    });
  }

  void _toggleBookmark(String recipeId) {
    setState(() {
      if (_bookmarkedRecipeIds.contains(recipeId)) {
        _bookmarkedRecipeIds.remove(recipeId);
      } else {
        _bookmarkedRecipeIds.add(recipeId);
      }
    });
  }

  /// Orders active ingredients first in the Compact Pantry Dock so users
  /// can immediately see and toggle their active fridge items, followed by
  /// popular inactive staples.
  List<PantryIngredient> get _dockOrderedIngredients {
    final active = <PantryIngredient>[];
    final inactive = <PantryIngredient>[];
    for (final ing in MockPantryData.allIngredients) {
      if (_activeIngredientIds.contains(ing.id)) {
        active.add(ing);
      } else {
        inactive.add(ing);
      }
    }
    return [...active, ...inactive];
  }

  /// Opens the Draggable Glassmorphic Bottom Sheet for full ingredient management
  Future<void> _openManageIngredientsSheet() async {
    HapticFeedback.mediumImpact();
    IngredientCategory modalCategory = IngredientCategory.semua;
    String modalSearch = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredList = MockPantryData.allIngredients.where((item) {
              final matchesCat =
                  modalCategory == IngredientCategory.semua ||
                  item.category == modalCategory;
              final matchesQuery =
                  modalSearch.trim().isEmpty ||
                  item.name.toLowerCase().contains(
                    modalSearch.trim().toLowerCase(),
                  );
              return matchesCat && matchesQuery;
            }).toList();

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
                          // Drag Handle & Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 42,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: AppTheme.borderSlateLight,
                                      borderRadius: BorderRadius.circular(999),
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
                                              color: AppTheme.textForestCharcoal,
                                            ),
                                          ),
                                          Text(
                                            '${_activeIngredientIds.length} dari ${MockPantryData.allIngredients.length} bahan tersedia di kos',
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
                                        setState(() {
                                          if (_activeIngredientIds.length ==
                                              MockPantryData
                                                  .allIngredients
                                                  .length) {
                                            _activeIngredientIds
                                              ..clear()
                                              ..addAll(
                                                MockPantryData
                                                    .defaultActiveIngredientIds,
                                              );
                                          } else {
                                            for (final item
                                                in MockPantryData
                                                    .allIngredients) {
                                              _activeIngredientIds.add(item.id);
                                            }
                                          }
                                        });
                                        setModalState(() {});
                                      },
                                      child: Text(
                                        _activeIngredientIds.length ==
                                                MockPantryData
                                                    .allIngredients
                                                    .length
                                            ? 'Reset Default'
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
                                    children: IngredientCategory.values.map((
                                      cat,
                                    ) {
                                      final selected = cat == modalCategory;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setModalState(
                                              () => modalCategory = cat,
                                            );
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 13,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? AppTheme.forestEmerald
                                                  : AppTheme.pureWhite,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: selected
                                                    ? AppTheme.forestEmerald
                                                    : AppTheme.borderSlateLight,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  cat.icon,
                                                  size: 14,
                                                  color: selected
                                                      ? AppTheme.pureWhite
                                                      : AppTheme.textSageGrey,
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
                                                        ? AppTheme.pureWhite
                                                        : AppTheme
                                                              .textForestCharcoal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(
                            height: 16,
                            color: AppTheme.borderNeutral,
                          ),

                          // Scrollable Ingredient Chips Grid/Wrap
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
                                  final isSelected = _activeIngredientIds
                                      .contains(ing.id);
                                  return AnimatedIngredientChip(
                                    key: ValueKey('modal_chip_${ing.id}'),
                                    ingredient: ing,
                                    isSelected: isSelected,
                                    onTap: () {
                                      _toggleIngredient(ing.id);
                                      setModalState(() {});
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                          // Bottom Done CTA
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            decoration: const BoxDecoration(
                              color: AppTheme.pureWhite,
                              border: Border(
                                top: BorderSide(color: AppTheme.borderNeutral),
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
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      'Simpan Kulkas (${_activeIngredientIds.length} Bahan Aktif)',
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
  }

  void _openRecipeDetail(RecipeModel recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          activeIngredientIds: _activeIngredientIds,
          initialBookmarked: _bookmarkedRecipeIds.contains(recipe.id),
          onBookmarkToggle: () => _toggleBookmark(recipe.id),
          onTogglePantryIngredient: (ingredientId) {
            setState(() {
              _activeIngredientIds.add(ingredientId);
            });
            widget.controller.notifyChanged();
          },
          onConsumeIngredients: (usedIds) {
            setState(() {
              _activeIngredientIds.removeAll(usedIds);
            });
            widget.controller.notifyChanged();
          },
        ),
      ),
    );
  }

  void _openServerInfoSheet() {
    HapticFeedback.selectionClick();
    final urlController = TextEditingController(
      text: widget.controller.apiBaseUrl,
    );
    var useLiveAi = widget.controller.useLiveLaravelAi;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: const Border(
                    top: BorderSide(color: AppTheme.borderMint, width: 1.5),
                  ),
                  boxShadow: AppTheme.softShadow(ctx),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.borderSlateLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.sageMint,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.mintLeaf),
                              ),
                              child: const Icon(
                                Icons.dns_rounded,
                                size: 20,
                                color: AppTheme.forestEmerald,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Info Proyek & Server Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textForestCharcoal,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'PantryKos • Smart Culinary Kos Assistant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSageGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.softMintTint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderMint),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tim Pengembang',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.forestEmerald,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '• Erlan Agam Putra\n• Gamma Estu Mahardika\n• Muhammad Fazli Nurfahmi',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textForestCharcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Laravel API Base URL',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textForestCharcoal,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: urlController,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textForestCharcoal,
                          ),
                          decoration: InputDecoration(
                            hintText: 'http://10.0.2.2:8000/api',
                            prefixIcon: const Icon(
                              Icons.link_rounded,
                              size: 18,
                              color: AppTheme.forestEmerald,
                            ),
                            filled: true,
                            fillColor: AppTheme.scaffoldMintWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.borderMint,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.borderMint,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.forestEmerald,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldMintWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderMint),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      useLiveAi
                                          ? 'Live Laravel AI'
                                          : 'Offline Demo Simulation',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textForestCharcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      useLiveAi
                                          ? 'Terhubung ke backend Laravel & Gemini Vision'
                                          : 'Simulasi data lokal instan tanpa internet',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textSageGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: useLiveAi,
                                activeThumbColor: AppTheme.pureWhite,
                                activeTrackColor: AppTheme.forestEmerald,
                                inactiveThumbColor: AppTheme.forestEmerald,
                                inactiveTrackColor: AppTheme.sageMint,
                                onChanged: (val) {
                                  setModalState(() => useLiveAi = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              widget.controller.updateServerConfig(
                                baseUrl: urlController.text,
                                useLiveAi: useLiveAi,
                              );
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppTheme.forestEmerald,
                                  content: Text(
                                    useLiveAi
                                        ? 'Mode Live Laravel AI aktif (${widget.controller.apiBaseUrl})'
                                        : 'Mode Offline Demo Simulation aktif',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.forestEmerald,
                              foregroundColor: AppTheme.pureWhite,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              'Simpan Konfigurasi',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<RecipeMatchResult> get _evaluatedAndSortedRecipes {
    final query = _searchQuery.trim().toLowerCase();

    final results = <RecipeMatchResult>[];
    for (final recipe in MockPantryData.recipes) {
      // Filter by cooking tool
      if (_selectedTool != CookingTool.semuaAlat &&
          recipe.cookingTool != _selectedTool) {
        continue;
      }

      // Filter by search query (title, subtitle, or ingredient names)
      if (query.isNotEmpty) {
        final inTitle = recipe.title.toLowerCase().contains(query);
        final inSubtitle = recipe.subtitle.toLowerCase().contains(query);
        final inIngredients = recipe.ingredients.any(
          (i) => i.displayName.toLowerCase().contains(query),
        );
        if (!inTitle && !inSubtitle && !inIngredients) {
          continue;
        }
      }

      results.add(recipe.evaluateMatch(_activeIngredientIds));
    }

    // Dynamically sort recipes:
    // 1. Fewest missing ingredients first (0 missing -> 100% Siap Masak at top)
    // 2. Highest match ratio
    // 3. Lowest estimated cost
    results.sort((a, b) {
      final missingCompare = a.missingCount.compareTo(b.missingCount);
      if (missingCompare != 0) return missingCompare;
      final ratioCompare = b.matchRatio.compareTo(a.matchRatio);
      if (ratioCompare != 0) return ratioCompare;
      return a.recipe.estimatedCostRupiah.compareTo(
        b.recipe.estimatedCostRupiah,
      );
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final matchedRecipes = _evaluatedAndSortedRecipes;
    final ready100Count = matchedRecipes
        .where((r) => r.tier == RecipeMatchTier.readyToCook)
        .length;
    final dockIngredients = _dockOrderedIngredients;

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
                        onChanged: (val) => setState(() => _searchQuery = val),
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
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
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
                          // Dock Header Row: "Isi Kulkasmu (X Bahan Aktif)" + "+ Kelola Bahan"
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
                                  'Isi Kulkasmu (${_activeIngredientIds.length} Bahan Aktif)',
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
                              if (_activeIngredientIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _activeIngredientIds.clear();
                                      });
                                      widget.controller.notifyChanged();
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

                          // Single-row horizontal ListView.separated (height: 46px)
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
                                final isSelected = _activeIngredientIds
                                    .contains(ing.id);
                                return Center(
                                  child: AnimatedIngredientChip(
                                    key: ValueKey('dock_chip_${ing.id}'),
                                    ingredient: ing,
                                    isSelected: isSelected,
                                    compact: true,
                                    showRemoveIconWhenSelected: true,
                                    onTap: () => _toggleIngredient(ing.id),
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
              selectedTool: _selectedTool,
              matchingRecipeCount: matchedRecipes.length,
              readyNowCount: ready100Count,
              onToolSelected: (tool) {
                setState(() => _selectedTool = tool);
              },
            ),
          ),

          // D. Smart Recipe Matcher Cards List (Immediately Visible Above-the-Fold)
          if (matchedRecipes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: NoMatchingRecipeWidget(
                  onResetFilter: () {
                    setState(() {
                      _selectedTool = CookingTool.semuaAlat;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 136),
              sliver: SliverList.separated(
                itemCount: matchedRecipes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final match = matchedRecipes[index];
                  return RecipeMatcherCard(
                    key: ValueKey('card_${match.recipe.id}'),
                    matchResult: match,
                    animationIndex: index,
                    isBookmarked: _bookmarkedRecipeIds.contains(
                      match.recipe.id,
                    ),
                    onBookmarkToggle: () => _toggleBookmark(match.recipe.id),
                    onTap: () => _openRecipeDetail(match.recipe),
                    onQuickAddMissingIngredient: (missingId) {
                      setState(() {
                        _activeIngredientIds.add(missingId);
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
