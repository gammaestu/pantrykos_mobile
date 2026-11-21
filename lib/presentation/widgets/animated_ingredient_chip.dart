import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../models/ui_recipe_model.dart';

/// Custom interactive ingredient chip for "Kulkas Virtual".
/// Uses [AnimatedContainer], [AnimatedScale], and [HapticFeedback.lightImpact]
/// with Soft Pastel Sage (#DCFCE7) fill and Vibrant Mint (#22C55E) border when active.
class AnimatedIngredientChip extends StatefulWidget {
  final PantryIngredient ingredient;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;
  final bool showRemoveIconWhenSelected;

  const AnimatedIngredientChip({
    super.key,
    required this.ingredient,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.showRemoveIconWhenSelected = false,
  });

  @override
  State<AnimatedIngredientChip> createState() => _AnimatedIngredientChipState();
}

class _AnimatedIngredientChipState extends State<AnimatedIngredientChip> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;

    // Slight tactile bounce on press/selection
    final double targetScale = _isPressed ? 0.94 : (selected ? 1.01 : 1.0);

    // Soft Pastel Sage (#DCFCE7) when active, Mint-Tinted Off-White (#F6FAF7) when inactive
    final Color bgColor = selected
        ? AppTheme.sageMint
        : AppTheme.scaffoldMintWhite;

    // Vibrant Mint (#22C55E) border when active, delicate #E2E8F0 when inactive
    final Color borderColor = selected
        ? AppTheme.mintLeaf
        : AppTheme.borderNeutral;

    final Color textColor = selected
        ? AppTheme.forestEmerald
        : AppTheme.textForestCharcoal;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 11 : 13,
            vertical: widget.compact ? 6 : 9,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.4 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.mintLeaf.withValues(alpha: 0.18),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Icon
              Text(
                widget.ingredient.emoji,
                style: TextStyle(fontSize: widget.compact ? 14 : 15),
              ),
              const SizedBox(width: 6),
              // Ingredient Name
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: widget.compact ? 12.5 : 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.1,
                ),
                child: Text(widget.ingredient.name),
              ),
              const SizedBox(width: 6),
              // Animated Check / Remove 'x' / Add indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: selected
                    ? Container(
                        key: ValueKey(
                          widget.showRemoveIconWhenSelected
                              ? 'remove'
                              : 'checked',
                        ),
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: widget.showRemoveIconWhenSelected
                              ? AppTheme.forestEmerald.withValues(alpha: 0.14)
                              : AppTheme.forestEmerald,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.showRemoveIconWhenSelected
                              ? Icons.close_rounded
                              : Icons.check_rounded,
                          size: 11.5,
                          color: widget.showRemoveIconWhenSelected
                              ? AppTheme.forestEmerald
                              : AppTheme.pureWhite,
                        ),
                      )
                    : Container(
                        key: const ValueKey('unchecked'),
                        width: 17,
                        height: 17,
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.borderSlateLight,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 11.5,
                          color: AppTheme.textSageGrey,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
