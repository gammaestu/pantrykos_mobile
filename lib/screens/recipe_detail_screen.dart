import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_pantry_data.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';
import '../widgets/cooking_mode_sheet.dart';
import '../widgets/food_illustration_widget.dart';

/// Complete Recipe Detail Screen styled in the Fresh Culinary Green & White Theme
/// (#F6FAF7 background, #FFFFFF cards, #E2E8F0 subtle borders).
/// Features:
/// 1. Smooth Hero transition inside SliverAppBar with a bottom gradient scrim
///    blending seamlessly into #F6FAF7 + frosted white floating back/bookmark buttons.
/// 2. Compact Metadata Row (#0F291E title, "Estimasi Biaya: ~Rp ...", cooking time,
///    tool badge in #DCFCE7 surface with #14532D text, and semantic match badge).
/// 3. Interactive Ingredient Checklist with Light Green (#DCFCE7) row highlight,
///    Dark Green (#14532D) custom checkboxes, and smooth strikethrough text.
/// 4. "Mulai Mode Masak" Sticky Bottom Bar with a Dark Green (#14532D) CTA button.
class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;
  final Set<String> activeIngredientIds;
  final bool initialBookmarked;
  final VoidCallback onBookmarkToggle;
  final ValueChanged<String> onTogglePantryIngredient;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.activeIngredientIds,
    required this.initialBookmarked,
    required this.onBookmarkToggle,
    required this.onTogglePantryIngredient,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  // Exact Step 3 Midnight Navy Theme Palette
  static const Color _bgMintWhite = AppTheme.scaffoldMintWhite;
  static const Color _cardWhite = AppTheme.pureWhite;
  static const Color _borderNeutral = AppTheme.borderNeutral;
  static const Color _sageMint = AppTheme.sageMint;
  static const Color _forestPrimary = AppTheme.forestEmerald;
  static const Color _botanicalGreen = AppTheme.botanicalGreen;
  static const Color _mintLeaf = AppTheme.mintLeaf;
  static const Color _amberFlame = Color(0xFFD97706);
  static const Color _textPrimary = AppTheme.textForestCharcoal;
  static const Color _textSecondary = AppTheme.textSageGrey;

  late final Set<String> _checkedPreparationIds;
  late final Set<String> _localPantryIds;
  late bool _isBookmarked;

  @override
  void initState() {
    super.initState();
    _localPantryIds = Set<String>.from(widget.activeIngredientIds);
    // Pre-check ingredients that the user already has in their Kulkas Virtual
    _checkedPreparationIds = Set<String>.from(
      widget.recipe.ingredients
          .where((item) => _localPantryIds.contains(item.ingredientId))
          .map((item) => item.ingredientId),
    );
    _isBookmarked = widget.initialBookmarked;
  }

  void _togglePrepChecklist(String ingredientId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_checkedPreparationIds.contains(ingredientId)) {
        _checkedPreparationIds.remove(ingredientId);
      } else {
        _checkedPreparationIds.add(ingredientId);
      }
    });
  }

  void _addMissingToFridge(String ingredientId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _localPantryIds.add(ingredientId);
      _checkedPreparationIds.add(ingredientId);
    });
    widget.onTogglePantryIngredient(ingredientId);
  }

  void _openCookingMode() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookingModeSheet(recipe: widget.recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final matchResult = recipe.evaluateMatch(_localPantryIds);
    final checkedCount = _checkedPreparationIds.length;
    final totalIngredients = recipe.ingredients.length;
    final isReady100 = matchResult.tier == RecipeMatchTier.readyToCook;

    return Scaffold(
      backgroundColor: _bgMintWhite,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. SliverAppBar with Smooth Hero Transition & Seamless #F6FAF7 Scrim
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                automaticallyImplyLeading: false,
                backgroundColor: _bgMintWhite,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 68,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: _GlassCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: _GlassCircleButton(
                        icon: _isBookmarked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: _isBookmarked
                            ? const Color(0xFFE11D48)
                            : _textPrimary,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _isBookmarked = !_isBookmarked);
                          widget.onBookmarkToggle();
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero Image
                      Hero(
                        tag: 'recipe_hero_${recipe.id}',
                        child: RecipeHeroImage(
                          recipe: recipe,
                          showBottomScrim: false,
                        ),
                      ),

                      // Multi-stop bottom gradient scrim blending seamlessly into #F6FAF7
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.38, 0.76, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.16),
                              Colors.transparent,
                              _bgMintWhite.withValues(alpha: 0.76),
                              _bgMintWhite,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Recipe Detail Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2A. Semantic Match Badge + Required Tool Badge Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Semantic Match Badge (#DCFCE7 / #14532D or #FEF3C7 / #92400E)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5.5,
                            ),
                            decoration: BoxDecoration(
                              color: isReady100
                                  ? AppTheme.readyPill
                                  : AppTheme.almostPill,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isReady100
                                    ? AppTheme.readyBorder
                                    : AppTheme.almostBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isReady100
                                      ? Icons.verified_rounded
                                      : Icons.auto_awesome_rounded,
                                  size: 13.5,
                                  color: isReady100
                                      ? AppTheme.readyText
                                      : AppTheme.almostText,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  matchResult.badgeText,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isReady100
                                        ? AppTheme.readyText
                                        : AppTheme.almostText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Required Tool Badge (#DCFCE7 surface with #14532D text)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5.5,
                            ),
                            decoration: BoxDecoration(
                              color: _sageMint,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _mintLeaf.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  recipe.cookingTool.icon,
                                  size: 13.5,
                                  color: _forestPrimary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  recipe.cookingTool.badgeLabel,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: _forestPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 2B. Recipe Title in Deep Forest Charcoal (#0F291E)
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 2C. Compact Metadata Row ("Estimasi Biaya: ~Rp ...", Cooking Time, Calories)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: _cardWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderMint),
                          boxShadow: AppTheme.softShadow(context),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.payments_outlined,
                                        size: 16,
                                        color: _forestPrimary,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Estimasi Biaya: ~${recipe.formattedCost}',
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: _botanicalGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  recipe.formattedTime,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_outlined,
                                  size: 16,
                                  color: _amberFlame,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.calories} kkal',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Recipe Description
                      Text(
                        recipe.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. Interactive Ingredient Checklist Encapsulated in a Pure White Card
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Bahan-Bahan Masakan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: checkedCount == totalIngredients
                                  ? _sageMint
                                  : AppTheme.softMintTint,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: checkedCount == totalIngredients
                                    ? _mintLeaf
                                    : AppTheme.borderMint,
                              ),
                            ),
                            child: Text(
                              '$checkedCount/$totalIngredients Siap',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: _forestPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Encapsulated Pure White Card for Ingredient Rows
                      Container(
                        decoration: BoxDecoration(
                          color: _cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _borderNeutral,
                            width: 1.2,
                          ),
                          boxShadow: AppTheme.softShadow(context),
                        ),
                        child: Column(
                          children: List.generate(recipe.ingredients.length, (
                            index,
                          ) {
                            final item = recipe.ingredients[index];
                            final isChecked = _checkedPreparationIds.contains(
                              item.ingredientId,
                            );
                            final inPantry = _localPantryIds.contains(
                              item.ingredientId,
                            );
                            final pantryObj =
                                MockPantryData.findIngredientById(
                                  item.ingredientId,
                                );

                            return Column(
                              children: [
                                if (index > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                    color: _borderNeutral,
                                  ),
                                InkWell(
                                  onTap: () => _togglePrepChecklist(
                                    item.ingredientId,
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: index == 0
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    bottom:
                                        index == recipe.ingredients.length - 1
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    decoration: BoxDecoration(
                                      color: isChecked
                                          ? _sageMint
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.vertical(
                                        top: index == 0
                                            ? const Radius.circular(20)
                                            : Radius.zero,
                                        bottom:
                                            index ==
                                                recipe.ingredients.length - 1
                                            ? const Radius.circular(20)
                                            : Radius.zero,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        // Custom Dark Green (#14532D) Checkbox
                                        AnimatedScale(
                                          scale: isChecked ? 1.08 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOutBack,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isChecked
                                                  ? _forestPrimary
                                                  : _cardWhite,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isChecked
                                                    ? _forestPrimary
                                                    : AppTheme.borderSlateLight,
                                                width: 1.6,
                                              ),
                                              boxShadow: isChecked
                                                  ? [
                                                      BoxShadow(
                                                        color: _forestPrimary
                                                            .withValues(
                                                              alpha: 0.22,
                                                            ),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: isChecked
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          pantryObj?.emoji ?? '🥘',
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 10),

                                        // Ingredient Name + Measure with Smooth Strikethrough
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AnimatedDefaultTextStyle(
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isChecked
                                                      ? _textSecondary
                                                      : _textPrimary,
                                                  decoration: isChecked
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : TextDecoration.none,
                                                  decorationColor:
                                                      _forestPrimary,
                                                  decorationThickness: 2.0,
                                                ),
                                                child: Text(item.displayName),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.measure,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Fridge Status Pill or Quick Add Button
                                        if (inPantry)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isChecked
                                                  ? _cardWhite
                                                  : AppTheme.softMintTint,
                                              border: Border.all(
                                                color: _mintLeaf.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Ada di Kulkas',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: _forestPrimary,
                                              ),
                                            ),
                                          )
                                        else
                                          GestureDetector(
                                            onTap: () => _addMissingToFridge(
                                              item.ingredientId,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _sageMint,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _mintLeaf,
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.add_rounded,
                                                    size: 12,
                                                    color: _forestPrimary,
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    'Kulkas',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _forestPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Anak-Kos Pro Tip Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardWhite,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderMint),
                          boxShadow: AppTheme.softShadow(context),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: _sageMint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                color: _forestPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hack Anak Kos',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _forestPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    recipe.kosHackTip,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Preview of Cooking Steps
                      Text(
                        'Ringkasan Langkah (${recipe.steps.length} Tahap)',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...recipe.steps.map((step) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _cardWhite,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _borderNeutral),
                            boxShadow: AppTheme.softShadow(context),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _sageMint,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _mintLeaf.withValues(alpha: 0.55),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${step.stepNumber}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _forestPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            step.title,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (step.timerSeconds != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.softMintTint,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.borderMint,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.timer_outlined,
                                                  size: 12,
                                                  color: _forestPrimary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${step.timerSeconds} dtk',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: _forestPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      step.instruction,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 4. "Mulai Mode Masak" Sticky Bottom Bar with Dark Green CTA Button
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                  decoration: BoxDecoration(
                    color: _cardWhite.withValues(alpha: 0.92),
                    border: const Border(
                      top: BorderSide(color: AppTheme.borderMint, width: 1.2),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [_forestPrimary, _botanicalGreen],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _forestPrimary.withValues(alpha: 0.28),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _openCookingMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Mulai Mode Masak',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GlassCircleButton({
    required this.icon,
    this.iconColor = AppTheme.textForestCharcoal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.borderMint,
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }
}
