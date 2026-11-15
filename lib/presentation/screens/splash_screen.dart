import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import '../../screens/main_navigation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pantrykos_logo.dart';

/// Multi-stage choreographed Splash & Loading Screen for PantryKos (2.8s).
///
/// Orchestrates 4 visual layers strictly in Dark Green (#14532D / #166534),
/// Light Green (#22C55E / #4ADE80 / #DCFCE7), and Crisp Mint-White (#F6FAF7 / #FFFFFF):
/// 1. Expanding sonar radar rings + `PathMetrics` AI scanner corner brackets.
/// 2. `elasticOut` Hero emblem + 4 orbiting glassmorphic ingredient pills converging
///    into the emblem at 1.6s beneath a vertical glowing AI laser sweep.
/// 3. `ShaderMask` diagonal light-glint title + `AnimatedSwitcher` status micro-copy
///    + rounded gradient progress pill.
/// 4. Custom `CircularRevealClipper` transition into [MainNavigation] at 2.8s.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _totalDuration = Duration(milliseconds: 2800);
  static const Duration _revealDuration = Duration(milliseconds: 650);

  late final AnimationController _masterController;
  late final AnimationController _sonarController;
  late final AnimationController _convergeController;
  late final AnimationController _shimmerController;

  late final Animation<double> _bracketDrawAnim;
  late final Animation<double> _emblemScaleAnim;
  late final Animation<double> _emblemFadeAnim;
  late final Animation<double> _laserSweepAnim;
  late final Animation<double> _titleFadeAnim;
  late final Animation<double> _progressAnim;

  late final Animation<double> _badgeShrinkAnim;
  late final Animation<double> _badgeFadeAnim;

  bool _showSecondMicroCopy = false;
  Timer? _convergeTimer;
  Timer? _microCopyTimer;
  Timer? _navigateTimer;

  static const List<String> _ingredientEmojis = ['🥚', '🍜', '🌭', '🍚'];

  @override
  void initState() {
    super.initState();

    // Master 2.8s timeline controller
    _masterController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // Repeating sonar radar & ingredient orbital phase
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Triggered at 1.6s: absorbs orbiting ingredient badges into center logo
    _convergeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    // Traveling diagonal ShaderMask light glint across "PantryKos"
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // 0ms -> 700ms (0.0 -> 0.25 of 2800ms): PathMetrics AI corner bracket draw
    _bracketDrawAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOutCubic),
    );

    // Spring emblem entrance (elasticOut scale + smooth fade)
    _emblemScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.05, 0.42, curve: Curves.elasticOut),
      ),
    );
    _emblemFadeAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.05, 0.22, curve: Curves.easeOut),
    );

    // 1.55s -> 2.35s (0.55 -> 0.84): Vertical AI laser scan sweep across logo
    _laserSweepAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.55, 0.84, curve: Curves.easeInOutSine),
    );

    // Title & bottom UI entrance
    _titleFadeAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.18, 0.44, curve: Curves.easeOut),
    );

    // Smooth 2.8s progress fill
    _progressAnim = CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.04, 0.96, curve: Curves.easeInOutCubic),
    );

    // Converge animations for the 4 ingredient badges
    _badgeShrinkAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _convergeController, curve: Curves.easeInBack),
    );
    _badgeFadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _convergeController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _masterController.forward();

    _microCopyTimer = Timer(const Duration(milliseconds: 1350), () {
      if (mounted) {
        setState(() => _showSecondMicroCopy = true);
      }
    });

    _convergeTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _convergeController.forward();
      }
    });

    _navigateTimer = Timer(_totalDuration, _navigateToMain);
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: _revealDuration,
        pageBuilder: (_, _, _) => const MainNavigation(),
        transitionsBuilder: (_, animation, _, child) {
          final revealFraction = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ).value;
          return ClipPath(
            clipper: CircularRevealClipper(fraction: revealFraction),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _convergeTimer?.cancel();
    _microCopyTimer?.cancel();
    _navigateTimer?.cancel();
    _masterController.dispose();
    _sonarController.dispose();
    _convergeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldMintWhite,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft concentric Pastel Mint (#DCFCE7) radial glow over #F6FAF7
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.08),
                radius: 0.9,
                colors: [
                  AppTheme.pureWhite,
                  AppTheme.sageMint,
                  AppTheme.scaffoldMintWhite,
                ],
                stops: [0.0, 0.38, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Layer 1 & Layer 2: Sonar Pulse, PathMetrics Brackets,
                // Spring Hero Emblem, Orbiting/Converging Badges & Laser Sweep
                SizedBox(
                  width: 248,
                  height: 248,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _masterController,
                      _sonarController,
                      _convergeController,
                    ]),
                    builder: (context, _) {
                      final orbitAngle = _sonarController.value * 2 * math.pi;
                      final convergeCurve = Curves.easeInCubic.transform(
                        _convergeController.value,
                      );
                      final showLaser =
                          _laserSweepAnim.value > 0.0 &&
                          _laserSweepAnim.value < 1.0;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Layer 1: Sonar rings + PathMetrics scanner brackets
                          CustomPaint(
                            size: const Size.square(248),
                            painter: _SonarAndScannerPainter(
                              sonarProgress: _sonarController.value,
                              bracketProgress: _bracketDrawAnim.value,
                            ),
                          ),

                          // Layer 2a: 4 Orbiting -> Converging Ingredient Badges
                          for (var i = 0; i < _ingredientEmojis.length; i++)
                            _buildOrbitingBadge(
                              index: i,
                              emoji: _ingredientEmojis[i],
                              orbitAngle: orbitAngle,
                              convergeFraction: convergeCurve,
                            ),

                          // Layer 2b: Elastic Hero Emblem + Vertical AI Laser Sweep
                          FadeTransition(
                            opacity: _emblemFadeAnim,
                            child: ScaleTransition(
                              scale: _emblemScaleAnim,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Hero(
                                    tag: 'pantrykos_logo',
                                    child: _SplashEmblemShell(),
                                  ),
                                  if (showLaser)
                                    _VerticalLaserSweepOverlay(
                                      progress: _laserSweepAnim.value,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Layer 3a: ShaderMask Shimmer Title "PantryKos"
                FadeTransition(
                  opacity: _titleFadeAnim,
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      final slide = _shimmerController.value * 2.2 - 0.6;
                      return ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: const [
                              AppTheme.forestEmerald,
                              AppTheme.forestEmerald,
                              AppTheme.brightMint,
                              AppTheme.forestEmerald,
                              AppTheme.forestEmerald,
                            ],
                            stops: [
                              0.0,
                              (slide - 0.22).clamp(0.0, 1.0),
                              slide.clamp(0.0, 1.0),
                              (slide + 0.22).clamp(0.0, 1.0),
                              1.0,
                            ],
                          ).createShader(bounds);
                        },
                        child: child,
                      );
                    },
                    child: const Text(
                      'PantryKos',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forestEmerald,
                        letterSpacing: -0.7,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Layer 3b: AnimatedSwitcher Status Micro-Copy
                FadeTransition(
                  opacity: _titleFadeAnim,
                  child: SizedBox(
                    height: 24,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offsetAnim = Tween<Offset>(
                          begin: const Offset(0, 0.35),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offsetAnim,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _showSecondMicroCopy
                            ? 'Menyiapkan Kulkas Virtual...'
                            : 'Memindai bahan anak kos...',
                        key: ValueKey<bool>(_showSecondMicroCopy),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSageGrey,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Layer 3c: Sleek Rounded Gradient Progress Pill
                Padding(
                  padding: const EdgeInsets.only(bottom: 38),
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (context, _) {
                      return Container(
                        width: 176,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.sageMint,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.mintLeaf.withValues(alpha: 0.25),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                            heightFactor: 1.0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.botanicalGreen,
                                    AppTheme.mintLeaf,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitingBadge({
    required int index,
    required String emoji,
    required double orbitAngle,
    required double convergeFraction,
  }) {
    final baseTheta = (index * math.pi / 2) + (math.pi / 4);
    final theta = baseTheta + orbitAngle;
    final radius = 92.0 * (1.0 - convergeFraction);
    final dx = math.cos(theta) * radius;
    final dy = math.sin(theta) * radius;

    // Fractional SlideTransition offset relative to the 42x42 badge box
    final slideAnim = AlwaysStoppedAnimation<Offset>(
      Offset(dx / 42.0, dy / 42.0),
    );

    return FadeTransition(
      opacity: _badgeFadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: ScaleTransition(
          scale: _badgeShrinkAnim,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderMint, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.forestEmerald.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 19)),
          ),
        ),
      ),
    );
  }
}

/// Center logo wrapper: loads `assets/images/logo_pantrykos.png` and falls back
/// seamlessly to our geometric vector emblem inside a #14532D rounded squircle.
class _SplashEmblemShell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Image.asset(
          'assets/images/logo_pantrykos.png',
          width: 96,
          height: 96,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) {
            return Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.forestEmerald,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.mintLeaf.withValues(alpha: 0.6),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mintLeaf.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const PantryKosLogoMark(size: 76, enableGlow: false),
            );
          },
        ),
      ),
    );
  }
}

/// Glowing vertical Light Green (#4ADE80) AI laser sweep across the center logo.
class _VerticalLaserSweepOverlay extends StatelessWidget {
  final double progress;

  const _VerticalLaserSweepOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    // Sweeps downward (0 -> 0.5) and gently back up (0.5 -> 1.0)
    final normalizedY =
        progress <= 0.5 ? (progress * 2.0) : (2.0 - progress * 2.0);
    final top = 6.0 + normalizedY * 78.0;

    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        children: [
          Positioned(
            left: 2,
            right: 2,
            top: top,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.brightMint,
                    AppTheme.pureWhite,
                    AppTheme.brightMint,
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brightMint.withValues(alpha: 0.85),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rendering Layer 1:
/// - Concentric expanding #22C55E sonar radar rings (opacity 0.25 -> 0.0)
/// - PathMetrics-animated 4 rounded AI scanner corner brackets (0ms -> 700ms)
class _SonarAndScannerPainter extends CustomPainter {
  final double sonarProgress;
  final double bracketProgress;

  const _SonarAndScannerPainter({
    required this.sonarProgress,
    required this.bracketProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Two staggered expanding sonar rings
    for (var ring = 0; ring < 2; ring++) {
      final phase = (sonarProgress + ring * 0.5) % 1.0;
      final radius = 48.0 + phase * 74.0;
      final opacity = (1.0 - phase) * 0.25;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppTheme.mintLeaf.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, ringPaint);
    }

    // 2. Progressively drawn AI scanner corner brackets using PathMetrics
    if (bracketProgress <= 0) return;

    const frameInset = 56.0;
    const arm = 22.0;
    const cornerR = 12.0;
    final left = center.dx - frameInset;
    final right = center.dx + frameInset;
    final top = center.dy - frameInset;
    final bottom = center.dy + frameInset;

    final brackets = <Path>[
      // Top-left
      Path()
        ..moveTo(left, top + arm)
        ..lineTo(left, top + cornerR)
        ..quadraticBezierTo(left, top, left + cornerR, top)
        ..lineTo(left + arm, top),
      // Top-right
      Path()
        ..moveTo(right - arm, top)
        ..lineTo(right - cornerR, top)
        ..quadraticBezierTo(right, top, right, top + cornerR)
        ..lineTo(right, top + arm),
      // Bottom-right
      Path()
        ..moveTo(right, bottom - arm)
        ..lineTo(right, bottom - cornerR)
        ..quadraticBezierTo(right, bottom, right - cornerR, bottom)
        ..lineTo(right - arm, bottom),
      // Bottom-left
      Path()
        ..moveTo(left + arm, bottom)
        ..lineTo(left + cornerR, bottom)
        ..quadraticBezierTo(left, bottom, left, bottom - cornerR)
        ..lineTo(left, bottom - arm),
    ];

    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.mintLeaf;

    for (final bracket in brackets) {
      for (final PathMetric metric in bracket.computeMetrics()) {
        final partial = metric.extractPath(0.0, metric.length * bracketProgress);
        canvas.drawPath(partial, bracketPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SonarAndScannerPainter oldDelegate) {
    return oldDelegate.sonarProgress != sonarProgress ||
        oldDelegate.bracketProgress != bracketProgress;
  }
}

/// Layer 4: Expands a circular clip outward from the exact center of the screen
/// to reveal [MainNavigation] smoothly.
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;

  const CircularRevealClipper({required this.fraction});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = center.distance;
    final currentRadius = (maxRadius * fraction).clamp(0.0, maxRadius);
    return Path()..addOval(Rect.fromCircle(center: center, radius: currentRadius));
  }

  @override
  bool shouldReclip(covariant CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}
