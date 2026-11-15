import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_pantry_data.dart';
import '../models/recipe_model.dart';
import '../state/pantry_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/food_illustration_widget.dart';
import 'recipe_detail_screen.dart';

enum _BookmarkFilter {
  semua('Semua', Icons.bookmarks_rounded),
  siapMasak('100% Siap Masak', Icons.verified_rounded),
  riceCooker('Rice Cooker', Icons.soup_kitchen_rounded);

  final String label;
  final IconData icon;
  const _BookmarkFilter(this.label, this.icon);
}

/// "Tersimpan" tab: ultra-compact header + single-line filter pills so saved
/// recipe cards are visible immediately. Supports swipe-to-remove and a
/// tap-to-unbookmark collapse animation (with undo), plus a custom dark
/// empty state.
class BookmarkScreen extends StatefulWidget {
  final PantryController controller;
  final VoidCallback onGoToKulkas;

  const BookmarkScreen({
    super.key,
    required this.controller,
    required this.onGoToKulkas,
  });

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  static const Color _bgNavy = AppTheme.scaffoldMintWhite;
  static const Color _cardSlate = AppTheme.pureWhite;
  static const Color _borderSlate = AppTheme.borderNeutral;

  _BookmarkFilter _filter = _BookmarkFilter.semua;

  PantryController get _c => widget.controller;

  void _openDetail(RecipeModel recipe) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          activeIngredientIds: _c.activeIngredientIds,
          initialBookmarked: _c.isBookmarked(recipe.id),
          onBookmarkToggle: () => _c.toggleBookmark(recipe.id),
          onTogglePantryIngredient: (id) => _c.addIngredients([id]),
        ),
      ),
    );
  }

  void _removeBookmark(RecipeModel recipe) {
    _c.toggleBookmark(recipe.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 112),
        backgroundColor: _cardSlate,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _borderSlate),
        ),
        content: Text(
          '"${recipe.title}" dihapus dari Tersimpan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textForestCharcoal,
          ),
        ),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: AppTheme.forestEmerald,
          onPressed: () => _c.toggleBookmark(recipe.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final saved =
            MockPantryData.recipes
                .where((r) => _c.isBookmarked(r.id))
                .map((r) => r.evaluateMatch(_c.activeIngredientIds))
                .toList()
              ..sort((a, b) => a.missingCount.compareTo(b.missingCount));

        final readyCount = saved
            .where((m) => m.tier == RecipeMatchTier.readyToCook)
            .length;

        final filtered = saved.where((m) {
          switch (_filter) {
            case _BookmarkFilter.semua:
              return true;
            case _BookmarkFilter.siapMasak:
              return m.tier == RecipeMatchTier.readyToCook;
            case _BookmarkFilter.riceCooker:
              return m.recipe.cookingTool == CookingTool.riceCooker;
          }
        }).toList();

        Widget content;
        if (saved.isEmpty) {
          content = _BookmarkEmptyState(
            key: const ValueKey('empty_all'),
            icon: Icons.bookmark_border_rounded,
            title: 'Belum Ada Resep Tersimpan',
            subtitle:
                'Ketuk ikon hati pada resep favoritmu agar mudah ditemukan lagi.',
            buttonLabel: 'Kembali ke Kulkas Virtual',
            onPressed: widget.onGoToKulkas,
          );
        } else if (filtered.isEmpty) {
          content = _BookmarkEmptyState(
            key: ValueKey('empty_${_filter.name}'),
            icon: Icons.filter_alt_off_rounded,
            title: 'Tidak Ada Resep di Filter Ini',
            subtitle: 'Coba pilih filter "Semua" untuk melihat seluruh resep.',
            buttonLabel: 'Tampilkan Semua',
            onPressed: () => setState(() => _filter = _BookmarkFilter.semua),
          );
        } else {
          content = ListView.builder(
            key: ValueKey('list_${_filter.name}'),
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 136),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final match = filtered[index];
              return _BookmarkTile(
                key: ValueKey('bm_${match.recipe.id}'),
                match: match,
                index: index,
                onOpen: () => _openDetail(match.recipe),
                onRemove: () => _removeBookmark(match.recipe),
              );
            },
          );
        }

        return Scaffold(
          backgroundColor: _bgNavy,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ultra-compact single-line header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resep Tersimpan',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textForestCharcoal,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${saved.length} resep • $readyCount siap masak',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSageGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _cardSlate,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderSlate),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                ),

                // Single-line filter pills (38px)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _BookmarkFilter.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _BookmarkFilter.values[i];
                      final selected = f == _filter;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _filter = f);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.forestEmerald
                                : _cardSlate,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.forestEmerald
                                  : AppTheme.borderSlateLight,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.forestEmerald
                                          .withValues(alpha: 0.20),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                f.icon,
                                size: 15,
                                color: selected
                                    ? AppTheme.pureWhite
                                    : AppTheme.textSageGrey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                f.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: selected
                                      ? AppTheme.pureWhite
                                      : AppTheme.textForestCharcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact horizontal saved-recipe card with staggered entrance, swipe to
/// remove ([Dismissible]) and a collapse/fade/slide exit on heart tap.
class _BookmarkTile extends StatefulWidget {
  final RecipeMatchResult match;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _BookmarkTile({
    super.key,
    required this.match,
    required this.index,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  State<_BookmarkTile> createState() => _BookmarkTileState();
}

class _BookmarkTileState extends State<_BookmarkTile>
    with TickerProviderStateMixin {
  static const Color _cardSlate = AppTheme.pureWhite;
  static const Color _borderSlate = AppTheme.borderNeutral;

  late final AnimationController _enter;
  late final AnimationController _exit;
  late final Animation<double> _enterCurve;
  late final Animation<double> _exitCurve;
  bool _removing = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    // Staggered entrance without timers: the controller runs for
    // (base + delay) and the curve only starts after the delay fraction.
    const baseMs = 380;
    final delayMs = widget.index.clamp(0, 6) * 55;
    _enter = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: baseMs + delayMs),
    );
    _enterCurve = CurvedAnimation(
      parent: _enter,
      curve: Interval(
        delayMs / (baseMs + delayMs),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _exitCurve = CurvedAnimation(parent: _exit, curve: Curves.easeInOutCubic);
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _animatedRemove() async {
    if (_removing) return;
    _removing = true;
    HapticFeedback.mediumImpact();
    await _exit.reverse();
    if (mounted) widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final recipe = match.recipe;
    final isReady = match.tier == RecipeMatchTier.readyToCook;
    final isAlmost = match.tier == RecipeMatchTier.almostReady;
    final badgeBg = isReady
        ? AppTheme.readyPill
        : (isAlmost ? AppTheme.almostPill : AppTheme.scaffoldMintWhite);
    final badgeBorder = isReady
        ? AppTheme.readyBorder
        : (isAlmost ? AppTheme.almostBorder : AppTheme.borderSlateLight);
    final badgeColor = isReady
        ? AppTheme.readyText
        : (isAlmost ? AppTheme.almostText : AppTheme.textSageGrey);
    final badgeText = isReady
        ? 'Siap Masak (100%)'
        : 'Kurang ${match.missingCount} Bahan';

    final enterCurve = _enterCurve;
    final exitCurve = _exitCurve;

    return FadeTransition(
      opacity: enterCurve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(enterCurve),
        child: SizeTransition(
          sizeFactor: exitCurve,
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: exitCurve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.35, 0),
                end: Offset.zero,
              ).animate(exitCurve),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey('dismiss_${recipe.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => widget.onRemove(),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFB7185).withValues(alpha: 0.05),
                          const Color(0xFFFB7185).withValues(alpha: 0.35),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_remove_rounded,
                          color: Color(0xFFE11D48),
                          size: 24,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Hapus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _pressed = true),
                    onTapUp: (_) => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onOpen();
                    },
                    child: AnimatedScale(
                      scale: _pressed ? 0.985 : 1.0,
                      duration: const Duration(milliseconds: 140),
                      child: Container(
                        height: 128,
                        decoration: BoxDecoration(
                          color: _cardSlate,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isReady
                                ? AppTheme.mintLeaf.withValues(alpha: 0.65)
                                : _borderSlate,
                            width: isReady ? 1.3 : 1.0,
                          ),
                          boxShadow: AppTheme.softShadow(context),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          children: [
                            // Thumbnail with Hero + tool badge
                            SizedBox(
                              width: 108,
                              height: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Hero(
                                    tag: 'recipe_hero_${recipe.id}',
                                    child: RecipeHeroImage(
                                      recipe: recipe,
                                      showBottomScrim: false,
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.55),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 6,
                                    right: 6,
                                    bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.pureWhite
                                            .withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.borderMint,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            recipe.cookingTool.icon,
                                            size: 11,
                                            color: AppTheme.forestEmerald,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              recipe.cookingTool.badgeLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.forestEmerald,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Info
                            Expanded(
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 34,
                                          ),
                                          child: Text(
                                            recipe.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textForestCharcoal,
                                              letterSpacing: -0.2,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: badgeBorder,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isReady
                                                    ? Icons.verified_rounded
                                                    : Icons
                                                          .auto_awesome_rounded,
                                                size: 12,
                                                color: badgeColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  badgeText,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                    color: badgeColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.schedule_rounded,
                                              size: 13,
                                              color: AppTheme.botanicalGreen,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              recipe.formattedTime,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textForestCharcoal,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.payments_outlined,
                                              size: 13,
                                              color: AppTheme.laserGreenEnd,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                recipe.formattedCost,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme
                                                      .textForestCharcoal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Unbookmark heart
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: _animatedRemove,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFB7185,
                                          ).withValues(alpha: 0.14),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.favorite_rounded,
                                          size: 17,
                                          color: Color(0xFFE11D48),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }
}

/// Custom dark empty state: glowing sapphire/cyan outline icon, concise text
/// and a secondary pill button.
class _BookmarkEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _BookmarkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  State<_BookmarkEmptyState> createState() => _BookmarkEmptyStateState();
}

class _BookmarkEmptyStateState extends State<_BookmarkEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_pulse.value);
                return Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.pureWhite,
                    border: Border.all(
                      color: Color.lerp(
                        AppTheme.botanicalGreen,
                        AppTheme.mintLeaf,
                        t,
                      )!,
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.mintLeaf
                            .withValues(alpha: 0.16 + 0.16 * t),
                        blurRadius: 24 + 14 * t,
                        spreadRadius: 1 + 2 * t,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.botanicalGreen, AppTheme.mintLeaf],
                    ).createShader(bounds),
                    child: Icon(widget.icon, size: 52, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textForestCharcoal,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSageGrey,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onPressed();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.sageMint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.mintLeaf),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.kitchen_rounded,
                      size: 16,
                      color: AppTheme.forestEmerald,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.buttonLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
