import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

/// Displays a high-resolution culinary image with a rich custom-painted
/// food illustration backdrop and multi-stop gradient scrim overlay.
/// Works seamlessly online and offline.
class RecipeHeroImage extends StatelessWidget {
  final RecipeModel recipe;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showBottomScrim;

  const RecipeHeroImage({
    super.key,
    required this.recipe,
    this.height,
    this.borderRadius,
    this.showBottomScrim = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Rich custom culinary art background (always visible immediately & offline)
        CustomPaint(
          painter: _CulinaryBackdropPainter(
            primary: recipe.primaryAccent,
            secondary: recipe.secondaryAccent,
            seed: recipe.id.hashCode,
          ),
        ),

        // 2. High-res network food photo with smooth fade-in
        Image.network(
          recipe.imageUrl,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Keep the rich culinary illustration visible when offline
            return const SizedBox.shrink();
          },
        ),

        // 3. Multi-stop gradient scrim overlay for crisp badge & title contrast
        if (showBottomScrim)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.72, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.38),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
      ],
    );

    final clipped = borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: content)
        : content;

    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: clipped);
    }
    return clipped;
  }
}

class _CulinaryBackdropPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final int seed;

  _CulinaryBackdropPainter({
    required this.primary,
    required this.secondary,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Warm dark culinary base gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(primary, const Color(0xFF0F291E), 0.35)!,
          Color.lerp(secondary, const Color(0xFF14532D), 0.55)!,
          const Color(0xFF0F291E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Ambient glowing culinary orbs
    final orbPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.55),
          primary.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.25, size.height * 0.3),
          radius: size.width * 0.5,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.3),
      size.width * 0.5,
      orbPaint1,
    );

    final orbPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondary.withValues(alpha: 0.45),
          secondary.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.78, size.height * 0.65),
          radius: size.width * 0.45,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.65),
      size.width * 0.45,
      orbPaint2,
    );

    // Stylized ceramic plate / bowl rings in the center
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final plateRadius = math.min(size.width, size.height) * 0.34;

    final plateFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, plateRadius, plateFill);

    final plateRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, plateRadius, plateRim);
    canvas.drawCircle(center, plateRadius * 0.76, plateRim);

    // Subtle garnish dots
    final rng = math.Random(seed);
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 10; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = rng.nextDouble() * plateRadius * 0.6;
      final pos = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );
      dotPaint.color = (i.isEven ? primary : secondary).withValues(alpha: 0.45);
      canvas.drawCircle(pos, 4.0 + rng.nextDouble() * 6.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CulinaryBackdropPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.seed != seed;
  }
}

