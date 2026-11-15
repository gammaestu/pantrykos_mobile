import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';
import 'food_illustration_widget.dart';

/// Smart Recipe Matcher Card styled in the Elegant Midnight Navy Dark Theme.
/// Features Hero food image, dynamic Match Badge (Neon Emerald #10B981 vs
/// Warm Amber #F59E0B), metadata chips, and an interactive heart-pop bookmark.
class RecipeMatcherCard extends StatefulWidget {
  final RecipeMatchResult matchResult;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;
  final ValueChanged<String>? onQuickAddMissingIngredient;
  final int animationIndex;

  const RecipeMatcherCard({
    super.key,
    required this.matchResult,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTap,
    this.onQuickAddMissingIngredient,
    this.animationIndex = 0,
  });

  @override
  State<RecipeMatcherCard> createState() => _RecipeMatcherCardState();
}

class _RecipeMatcherCardState extends State<RecipeMatcherCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  bool _isCardPressed = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.42)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.42, end: 0.88)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _triggerBookmark() {
    HapticFeedback.mediumImpact();
    _heartController.forward(from: 0.0);
    widget.onBookmarkToggle();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.matchResult.recipe;
    final tier = widget.matchResult.tier;

    // Semantic badge colors based on ingredient readiness
    final Color badgeBgColor;
    final Color badgeBorderColor;
    final Color badgeIconColor;
    final Color badgeTextColor;
    final IconData badgeIcon;

    switch (tier) {
      case RecipeMatchTier.readyToCook:
        badgeBgColor = AppTheme.readyPill;
        badgeBorderColor = AppTheme.readyBorder;
        badgeIconColor = AppTheme.readyText;
        badgeTextColor = AppTheme.readyText;
        badgeIcon = Icons.verified_rounded;
      case RecipeMatchTier.almostReady:
        badgeBgColor = AppTheme.almostPill;
        badgeBorderColor = AppTheme.almostBorder;
        badgeIconColor = AppTheme.almostText;
        badgeTextColor = AppTheme.almostText;
        badgeIcon = Icons.auto_awesome_rounded;
      case RecipeMatchTier.needsShopping:
        badgeBgColor = AppTheme.pureWhite.withValues(alpha: 0.94);
        badgeBorderColor = AppTheme.borderSlateLight;
        badgeIconColor = AppTheme.textSageGrey;
        badgeTextColor = AppTheme.textForestCharcoal;
        badgeIcon = Icons.shopping_basket_rounded;
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('${recipe.id}_${widget.matchResult.matchPercentage}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds: 340 + (widget.animationIndex.clamp(0, 6) * 50),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, (1.0 - animValue) * 18),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isCardPressed = true),
        onTapUp: (_) => setState(() => _isCardPressed = false),
        onTapCancel: () => setState(() => _isCardPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _isCardPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(
                color: tier == RecipeMatchTier.readyToCook
                    ? AppTheme.mintLeaf.withValues(alpha: 0.70)
                    : AppTheme.borderNeutral,
                width: tier == RecipeMatchTier.readyToCook ? 1.4 : 1.0,
              ),
              boxShadow: AppTheme.softShadow(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Visual Hero Section with Scrim, Match Badge & Heart Button
                SizedBox(
                  height: 176,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero Image + Scrim
                      Hero(
                        tag: 'recipe_hero_${recipe.id}',
                        child: RecipeHeroImage(
                          recipe: recipe,
                          showBottomScrim: true,
                        ),
                      ),

                      // Top bar: Dynamic Match Badge + Interactive Bookmark Button
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic Match Pill Badge
                            Flexible(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: badgeBorderColor,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      badgeIcon,
                                      size: 14,
                                      color: badgeIconColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        widget.matchResult.badgeText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: badgeTextColor,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Glassmorphic Heart Bookmark Button with Scale/Pop Animation
                            GestureDetector(
                              onTap: _triggerBookmark,
                              behavior: HitTestBehavior.opaque,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.pureWhite.withValues(
                                        alpha: 0.88,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.borderMint,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: ScaleTransition(
                                      scale: _heartScale,
                                      child: Icon(
                                        widget.isBookmarked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 19,
                                        color: widget.isBookmarked
                                            ? const Color(0xFFE11D48)
                                            : AppTheme.textForestCharcoal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Image Overlay: Title & Subtitle over Gradient Scrim
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.pureWhite,
                                letterSpacing: -0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recipe.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.pureWhite.withValues(
                                  alpha: 0.90,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Card Body: Metadata Chips + Pantry Match Progress Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadata Chips Row: Cooking Time, Tool Icon, Estimated Cost
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetadataChip(
                            icon: Icons.schedule_rounded,
                            label: recipe.formattedTime,
                            accentColor: AppTheme.forestEmerald,
                          ),
                          _MetadataChip(
                            icon: recipe.cookingTool.icon,
                            label: recipe.cookingTool.badgeLabel,
                            accentColor: AppTheme.botanicalGreen,
                          ),
                          _MetadataChip(
                            icon: Icons.payments_outlined,
                            label: recipe.formattedCost,
                            accentColor: AppTheme.laserGreenEnd,
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      // Ingredient Match Readiness Bar & Quick Action
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Kecocokan Bahan: ${widget.matchResult.matchedIngredients.length}/${recipe.ingredients.length}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textSageGrey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.matchResult.matchPercentage}%',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            tier == RecipeMatchTier.readyToCook
                                            ? AppTheme.forestEmerald
                                            : (tier ==
                                                      RecipeMatchTier
                                                          .almostReady
                                                  ? AppTheme.almostText
                                                  : AppTheme.textSageGrey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0.0,
                                      end: widget.matchResult.matchRatio,
                                    ),
                                    duration: const Duration(milliseconds: 420),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, ratio, _) {
                                      return LinearProgressIndicator(
                                        value: ratio,
                                        minHeight: 5.5,
                                        backgroundColor: AppTheme.shimmerBase,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              tier ==
                                                      RecipeMatchTier
                                                          .readyToCook
                                                  ? AppTheme.mintLeaf
                                                  : (tier ==
                                                            RecipeMatchTier
                                                                .almostReady
                                                        ? const Color(
                                                            0xFFD97706,
                                                          )
                                                        : AppTheme
                                                              .textSageGrey),
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.matchResult.missingIngredients.isNotEmpty &&
                              widget.onQuickAddMissingIngredient != null) ...[
                            const SizedBox(width: 10),
                            Tooltip(
                              message:
                                  'Tambahkan ${widget.matchResult.missingIngredients.first.displayName} ke Kulkas',
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onQuickAddMissingIngredient!(
                                    widget
                                        .matchResult
                                        .missingIngredients
                                        .first
                                        .ingredientId,
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.sageMint,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.mintLeaf,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add_task_rounded,
                                        size: 13,
                                        color: AppTheme.forestEmerald,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+${widget.matchResult.missingIngredients.first.displayName.split(' ').first}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.forestEmerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.softMintTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderMint, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: accentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textForestCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}
