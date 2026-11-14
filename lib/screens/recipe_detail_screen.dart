import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_pantry_data.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';
import '../widgets/cooking_mode_sheet.dart';
import '../widgets/food_illustration_widget.dart';

/// Recipe Detail Screen styled in the Elegant Midnight Navy Dark Theme.
/// Features Hero transition, CustomScrollView, Interactive Ingredient Checklist
/// (custom animated checkbox + smooth strikethrough), and "Mulai Mode Masak"
/// sticky glassmorphic CTA with Sapphire-Cyan gradient.
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

    return Scaffold(
      backgroundColor: AppTheme.midnightNavyScaffold,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Collapsing SliverAppBar with Hero Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                automaticallyImplyLeading: false,
                backgroundColor: AppTheme.midnightNavyScaffold,
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
                            ? const Color(0xFFFB7185)
                            : AppTheme.iceWhiteTitle,
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
                      Hero(
                        tag: 'recipe_hero_${recipe.id}',
                        child: RecipeHeroImage(
                          recipe: recipe,
                          showBottomScrim: true,
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Match Status Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    matchResult.tier ==
                                        RecipeMatchTier.readyToCook
                                    ? AppTheme.emeraldReady
                                    : AppTheme.amberAlmost,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    matchResult.tier ==
                                            RecipeMatchTier.readyToCook
                                        ? Icons.verified_rounded
                                        : Icons.info_outline_rounded,
                                    size: 14,
                                    color:
                                        matchResult.tier ==
                                            RecipeMatchTier.readyToCook
                                        ? Colors.white
                                        : AppTheme.midnightNavyScaffold,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      matchResult.badgeText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            matchResult.tier ==
                                                RecipeMatchTier.readyToCook
                                            ? Colors.white
                                            : AppTheme.midnightNavyScaffold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              recipe.title,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.iceWhiteTitle,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Detail Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Metadata Grid (Time, Tool, Cost)
                      Row(
                        children: [
                          Expanded(
                            child: _MetricInfoTile(
                              icon: Icons.schedule_rounded,
                              label: 'Waktu',
                              value: recipe.formattedTime,
                              accent: AppTheme.glowingSkyBorder,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricInfoTile(
                              icon: recipe.cookingTool.icon,
                              label: 'Alat Kos',
                              value: recipe.cookingTool.badgeLabel,
                              accent: AppTheme.gradientCyanEnd,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricInfoTile(
                              icon: Icons.payments_outlined,
                              label: 'Estimasi',
                              value: recipe.formattedCost,
                              accent: AppTheme.emeraldReady,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Description
                      Text(
                        recipe.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      const SizedBox(height: 18),

                      // Anak-Kos Hack Pro Tip Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.activeChipSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.glowingSkyBorder,
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                color: Colors.white,
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
                                      color: AppTheme.glowingSkyBorder,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    recipe.kosHackTip,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.iceWhiteTitle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Interactive Ingredient Checklist Section Header
                      Row(
                        children: [
                          Text(
                            'Checklist Bahan Masak',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: checkedCount == totalIngredients
                                  ? AppTheme.emeraldReady.withValues(
                                      alpha: 0.16,
                                    )
                                  : AppTheme.activeChipSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: checkedCount == totalIngredients
                                    ? AppTheme.emeraldReady
                                    : AppTheme.glowingSkyBorder,
                              ),
                            ),
                            child: Text(
                              '$checkedCount/$totalIngredients Siap',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: checkedCount == totalIngredients
                                    ? AppTheme.emeraldReady
                                    : AppTheme.glowingSkyBorder,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ketuk bahan untuk mencentang persiapan sebelum mulai memasak.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),

                      // Interactive Ingredient Checklist Items
                      ...recipe.ingredients.map((item) {
                        final isChecked = _checkedPreparationIds.contains(
                          item.ingredientId,
                        );
                        final inPantry = _localPantryIds.contains(
                          item.ingredientId,
                        );
                        final pantryObj = MockPantryData.findIngredientById(
                          item.ingredientId,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _togglePrepChecklist(
                              item.ingredientId,
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: isChecked
                                    ? AppTheme.emeraldReady.withValues(
                                        alpha: 0.12,
                                      )
                                    : AppTheme.elevatedSlateSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isChecked
                                      ? AppTheme.emeraldReady.withValues(
                                          alpha: 0.6,
                                        )
                                      : AppTheme.slateBorder,
                                  width: isChecked ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Custom Animated Checkbox
                                  AnimatedScale(
                                    scale: isChecked ? 1.06 : 1.0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutBack,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? AppTheme.emeraldReady
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isChecked
                                              ? AppTheme.emeraldReady
                                              : AppTheme.mutedSteelSubtitle,
                                          width: 1.8,
                                        ),
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

                                  // Ingredient Name & Measure with Smooth Strikethrough
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
                                                ? AppTheme.mutedSteelSubtitle
                                                : AppTheme.iceWhiteTitle,
                                            decoration: isChecked
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            decorationColor:
                                                AppTheme.emeraldReady,
                                            decorationThickness: 2.0,
                                          ),
                                          child: Text(item.displayName),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.measure,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Pill: Ada di Kulkas vs Kurang (Tap to add)
                                  if (inPantry)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.emeraldReady.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Di Kulkas',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.emeraldReady,
                                        ),
                                      ),
                                    )
                                  else
                                    InkWell(
                                      onTap: () => _addMissingToFridge(
                                        item.ingredientId,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.activeChipSurface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.glowingSkyBorder,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_rounded,
                                              size: 12,
                                              color: AppTheme.glowingSkyBorder,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'Tambah ke Kulkas',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.iceWhiteTitle,
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
                        );
                      }),

                      const SizedBox(height: 24),

                      // Ringkasan Langkah Memasak
                      Row(
                        children: [
                          Text(
                            'Tahapan Memasak (${recipe.steps.length} Langkah)',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...recipe.steps.map((step) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.elevatedSlateSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.slateBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.activeChipSurface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.glowingSkyBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${step.stepNumber}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.iceWhiteTitle,
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
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
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
                                              color: AppTheme.amberAlmost
                                                  .withValues(alpha: 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.timer_outlined,
                                                  size: 12,
                                                  color: AppTheme.amberAlmost,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${step.timerSeconds} dtk',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.amberAlmost,
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
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

          // 3. Sticky Glassmorphic Bottom Bar with "Mulai Mode Masak" Button
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                  decoration: BoxDecoration(
                    color: AppTheme.midnightNavyScaffold.withValues(
                      alpha: 0.88,
                    ),
                    border: const Border(
                      top: BorderSide(color: AppTheme.slateBorder),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppTheme.glowShadow(
                            AppTheme.primarySapphire,
                            intensity: 0.38,
                          ),
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
                            'Mulai Mode Masak (Step-by-Step + Timer)',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
    this.iconColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.midnightNavyScaffold.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _MetricInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _MetricInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSlateSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slateBorder),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 5),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}
