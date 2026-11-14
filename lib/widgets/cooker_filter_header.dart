import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';

/// Ultra-Thin Sticky Tool Filter Strip (SliverPersistentHeaderDelegate).
/// Places the cooking tool filter ("Semua Alat", "Rice Cooker", "Teflon",
/// "Panci Listrik") in a compact single-line horizontal chip row (height: 38px)
/// right above the Recipe List.
class CookerFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final CookingTool selectedTool;
  final ValueChanged<CookingTool> onToolSelected;
  final int matchingRecipeCount;
  final int readyNowCount;

  CookerFilterHeaderDelegate({
    required this.selectedTool,
    required this.onToolSelected,
    required this.matchingRecipeCount,
    required this.readyNowCount,
  });

  @override
  double get minExtent => 52.0;

  @override
  double get maxExtent => 52.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: maxExtent,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppTheme.midnightNavyScaffold.withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(
                color: overlapsContent
                    ? AppTheme.slateBorder
                    : AppTheme.slateBorder.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: CookingTool.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tool = CookingTool.values[index];
                final isSelected = tool == selectedTool;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToolSelected(tool);
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.02 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected
                            ? null
                            : AppTheme.elevatedSlateSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.glowingSkyBorder
                              : AppTheme.slateBorder,
                          width: isSelected ? 1.3 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primarySapphire.withValues(
                                    alpha: 0.32,
                                  ),
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
                            tool.icon,
                            size: 15,
                            color: isSelected
                                ? AppTheme.iceWhiteTitle
                                : AppTheme.mutedSteelSubtitle,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tool.filterLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.iceWhiteTitle
                                  : AppTheme.mutedSteelSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CookerFilterHeaderDelegate oldDelegate) {
    return oldDelegate.selectedTool != selectedTool ||
        oldDelegate.matchingRecipeCount != matchingRecipeCount ||
        oldDelegate.readyNowCount != readyNowCount;
  }
}
