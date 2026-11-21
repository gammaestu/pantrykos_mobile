import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Smooth pulsing skeleton loader matching the proportions of `RecipeMatcherCard`.
/// Animates between [AppTheme.shimmerBase] (`#E8F3EC`) and
/// [AppTheme.scaffoldMintWhite] (`#F6FAF7`) inside a crisp Pure White card.
class RecipeCardSkeleton extends StatefulWidget {
  const RecipeCardSkeleton({super.key});

  @override
  State<RecipeCardSkeleton> createState() => _RecipeCardSkeletonState();
}

class _RecipeCardSkeletonState extends State<RecipeCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _colorAnimation = ColorTween(
      begin: AppTheme.shimmerBase,
      end: AppTheme.scaffoldMintWhite,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({
    double? width,
    required double height,
    double radius = 10,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _colorAnimation.value ?? AppTheme.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderNeutral),
            boxShadow: AppTheme.softShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail placeholder
              Container(
                height: 156,
                width: double.infinity,
                color: _colorAnimation.value ?? AppTheme.shimmerBase,
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 118, height: 26, radius: 999),
                    _box(width: 34, height: 34, radius: 999),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 220, height: 20, radius: 8),
                    const SizedBox(height: 8),
                    _box(width: 150, height: 14, radius: 7),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _box(width: 82, height: 28, radius: 10),
                        const SizedBox(width: 8),
                        _box(width: 96, height: 28, radius: 10),
                        const SizedBox(width: 8),
                        _box(width: 72, height: 28, radius: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Clean white/green error banner card with a Dark Green retry button.
class ErrorBannerWidget extends StatelessWidget {
  const ErrorBannerWidget({
    super.key,
    this.title = 'Koneksi Server Terkendala',
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Coba Lagi',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderMint, width: 1.2),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.softMintTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderMint),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: AppTheme.forestEmerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textForestCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppTheme.textSageGrey,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestEmerald,
                    foregroundColor: AppTheme.pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    retryLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty filter/search state card in Pure White with Light Green icon accent
/// and a "Reset Filter" CTA button.
class NoMatchingRecipeWidget extends StatelessWidget {
  const NoMatchingRecipeWidget({
    super.key,
    required this.onResetFilter,
  });

  final VoidCallback onResetFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderMint),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.sageMint,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.mintLeaf.withValues(alpha: 0.55),
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 30,
              color: AppTheme.forestEmerald,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada resep yang cocok dengan filter ini',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Coba pilih "Semua Alat" atau bersihkan kata kunci pencarianmu.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onResetFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.forestEmerald,
              foregroundColor: AppTheme.pureWhite,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Reset Filter',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
