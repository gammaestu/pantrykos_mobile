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
            color: AppTheme.scaffoldMintWhite.withValues(alpha: 0.92),
            border: Border(
              bottom: BorderSide(
                color: overlapsContent
                    ? AppTheme.borderMint
                    : AppTheme.borderNeutral.withValues(alpha: 0.55),
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
                        color: isSelected
                            ? AppTheme.forestEmerald
                            : AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.forestEmerald
                              : AppTheme.borderSlateLight,
                          width: isSelected ? 1.3 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.forestEmerald.withValues(
                                    alpha: 0.20,
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
                                ? AppTheme.pureWhite
                                : AppTheme.textSageGrey,
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
                                  ? AppTheme.pureWhite
                                  : AppTheme.textForestCharcoal,
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
