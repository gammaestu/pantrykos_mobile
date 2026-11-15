import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Minimalist, luxury vector logo mark for PantryKos.
/// Fuses a geometric culinary bowl silhouette with a smart-pantry
/// leaf accent and an AI sparkle in the Midnight Navy & Sapphire-Cyan palette.
class PantryKosLogoMark extends StatelessWidget {
  final double size;
  final bool enableGlow;

  const PantryKosLogoMark({
    super.key,
    this.size = 36,
    this.enableGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.30;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.forestEmerald,
            AppTheme.botanicalGreen,
          ],
        ),
        border: Border.all(
          color: AppTheme.mintLeaf.withValues(alpha: 0.55),
          width: (size * 0.035).clamp(1.1, 2.0),
        ),
        boxShadow: enableGlow
            ? [
                BoxShadow(
                  color: AppTheme.mintLeaf.withValues(alpha: 0.25),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.02,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          size: Size.square(size),
          painter: _PantryKosVectorLogoPainter(),
        ),
      ),
    );
  }
}

/// Clean horizontal brand lockup: Vector Logo Mark + "PantryKos" wordmark.
class PantryKosBrandLockup extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showMark;

  const PantryKosBrandLockup({
    super.key,
    this.logoSize = 34,
    this.fontSize = 18.5,
    this.subtitle,
    this.onTap,
    this.showMark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMark) ...[
          PantryKosLogoMark(size: logoSize),
          const SizedBox(width: 10),
        ],
        Text(
          'Pantry',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppTheme.textForestCharcoal,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppTheme.forestEmerald,
              AppTheme.mintLeaf,
            ],
          ).createShader(bounds),
          child: Text(
            'Kos',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _PantryKosVectorLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle inner ambient radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          AppTheme.mintLeaf.withValues(alpha: 0.32),
          AppTheme.brightMint.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    final strokeW = (w * 0.072).clamp(1.8, 5.5);

    // 2. Geometric Culinary Bowl (Lower Hemisphere + Rim)
    final bowlRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.54),
      width: w * 0.56,
      height: h * 0.48,
    );

    final bowlFillPath = Path()
      ..addArc(bowlRect, 0, math.pi)
      ..close();
    final bowlFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.mintLeaf.withValues(alpha: 0.35),
          AppTheme.brightMint.withValues(alpha: 0.12),
        ],
      ).createShader(bowlRect);
    canvas.drawPath(bowlFillPath, bowlFillPaint);

    final bowlStrokePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.pureWhite,
          AppTheme.sageMint,
          AppTheme.brightMint,
        ],
      ).createShader(bowlRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bowlArcPath = Path()
      ..moveTo(w * 0.20, h * 0.54)
      ..lineTo(w * 0.80, h * 0.54)
      ..arcTo(bowlRect, 0, math.pi, false);
    canvas.drawPath(bowlArcPath, bowlStrokePaint);

    canvas.drawLine(
      Offset(w * 0.38, h * 0.83),
      Offset(w * 0.62, h * 0.83),
      bowlStrokePaint,
    );

    // 3. Neon Emerald Freshness Leaf
    final leafPath = Path()
      ..moveTo(w * 0.52, h * 0.50)
      ..quadraticBezierTo(w * 0.54, h * 0.28, w * 0.73, h * 0.25)
      ..quadraticBezierTo(w * 0.71, h * 0.45, w * 0.52, h * 0.50)
      ..close();

    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          AppTheme.brightMint,
          AppTheme.mintLeaf,
        ],
      ).createShader(Rect.fromLTWH(w * 0.50, h * 0.24, w * 0.26, h * 0.28))
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, leafPaint);

    // 4. Minimalist 4-Point AI Star Sparkle
    final starCenter = Offset(w * 0.35, h * 0.31);
    final starRadius = w * 0.13;
    final innerRadius = starRadius * 0.32;

    final starPath = Path()
      ..moveTo(starCenter.dx, starCenter.dy - starRadius)
      ..quadraticBezierTo(
        starCenter.dx + innerRadius,
        starCenter.dy - innerRadius,
        starCenter.dx + starRadius,
        starCenter.dy,
      )
      ..quadraticBezierTo(
        starCenter.dx + innerRadius,
        starCenter.dy + innerRadius,
        starCenter.dx,
        starCenter.dy + starRadius,
      )
      ..quadraticBezierTo(
        starCenter.dx - innerRadius,
        starCenter.dy + innerRadius,
        starCenter.dx - starRadius,
        starCenter.dy,
      )
      ..quadraticBezierTo(
        starCenter.dx - innerRadius,
        starCenter.dy - innerRadius,
        starCenter.dx,
        starCenter.dy - starRadius,
      )
      ..close();

    final starPaint = Paint()
      ..color = AppTheme.pureWhite
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
