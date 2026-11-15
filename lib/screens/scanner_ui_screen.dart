import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Complete Smart Fridge AI Scanner UI for PantryKos.
/// Features a Botanical Viewfinder (#0A1F14 backdrop), Light-to-Dark Green
/// (#4ADE80 -> #16A34A) corner brackets & laser line, and a Frosted White (90%)
/// Glassmorphic Bottom Sheet (#DCFCE7 border) with a Dark Green (#14532D) CTA button.
class ScannerUiScreen extends StatefulWidget {
  final Set<String> currentIngredientIds;

  const ScannerUiScreen({
    super.key,
    required this.currentIngredientIds,
  });

  @override
  State<ScannerUiScreen> createState() => _ScannerUiScreenState();
}

class _ScannerUiScreenState extends State<ScannerUiScreen>
    with TickerProviderStateMixin {
  // Exact Palette Constants per Step 2 Spec
  static const Color _viewfinderBackdrop = Color(0xFF0A1F14);
  static const Color _mintAccent = AppTheme.mintLeaf;
  static const Color _forestPrimary = AppTheme.forestEmerald;
  static const Color _frostedSurface = AppTheme.pureWhite;
  static const Color _sheetTopBorder = AppTheme.borderMint;

  late final AnimationController _laserController;

  final Set<String> _selectedIds = {};
  bool _isScanning = false;
  bool _flashOn = false;
  Timer? _rescanTimer;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rescanTimer?.cancel();
    _laserController.dispose();
    super.dispose();
  }

  void _triggerSimulatedRescan() {
    if (_isScanning) return;
    HapticFeedback.heavyImpact();

    setState(() => _isScanning = true);
    _laserController.duration = const Duration(milliseconds: 700);
    _laserController.repeat(reverse: true);

    _rescanTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _laserController.duration = const Duration(milliseconds: 2400);
      _laserController.repeat(reverse: true);
      setState(() => _isScanning = false);
    });
  }

  void _confirmAndReturn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _viewfinderBackdrop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Botanical Forest Simulated Viewfinder Background
          CustomPaint(
            painter: _MidnightViewfinderBackdropPainter(
              flashActive: _flashOn,
            ),
          ),

          // 2. Custom Scanner Overlay (Corner Brackets + Sweeping Laser)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 78, 22, 240),
              child: AnimatedBuilder(
                animation: _laserController,
                builder: (context, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // CustomPainter: Rounded Green Corner Brackets + Sweeping #4ADE80->#16A34A Laser Line
                      CustomPaint(
                        painter: _ScannerBracketAndLaserPainter(
                          laserProgress: _laserController.value,
                        ),
                      ),

                      // Analyzing pulse indicator when re-scanning
                      if (_isScanning)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 14,
                                sigmaY: 14,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: _frostedSurface.withValues(
                                    alpha: 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: _mintAccent,
                                    width: 1.4,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _forestPrimary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'AI Vision Memindai Kulkas...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textForestCharcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 1B. Translucent Glassmorphic Top Bar ("Pindai Bahan di Kulkas")
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _sheetTopBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppTheme.textForestCharcoal,
                            ),
                            tooltip: 'Kembali',
                          ),
                          const Expanded(
                            child: Text(
                              'Pindai Bahan di Kulkas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textForestCharcoal,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() => _flashOn = !_flashOn);
                            },
                            icon: Icon(
                              _flashOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              size: 20,
                              color: _flashOn
                                  ? const Color(0xFFD97706)
                                  : AppTheme.textSageGrey,
                            ),
                            tooltip: 'Flash Kamera',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Glassmorphic Bottom Sheet (Frosted White surface, #DCFCE7 top border)
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: const Border(
                      top: BorderSide(
                        color: _sheetTopBorder,
                        width: 1.4,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag indicator pill
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.borderSlateLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header Row: "Bahan Terdeteksi (X)" + Re-scan trigger
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _mintAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: _mintAccent, blurRadius: 8),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bahan Terdeteksi (${_selectedIds.length})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textForestCharcoal,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: _triggerSimulatedRescan,
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 15,
                                      color: _forestPrimary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pindai Ulang',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _forestPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Clean Empty Scanner Hint
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldMintWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderMint),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.center_focus_weak_rounded,
                                size: 18,
                                color: _forestPrimary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Arahkan kamera ke bahan di kulkas untuk mulai memindai.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSageGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary Dark Green CTA Button (#14532D) labeled "Masukkan ke Kulkas (+)"
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _selectedIds.isEmpty
                                  ? AppTheme.borderNeutral
                                  : _forestPrimary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _selectedIds.isEmpty
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: _forestPrimary.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _selectedIds.isEmpty
                                  ? null
                                  : _confirmAndReturn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(
                                Icons.kitchen_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Masukkan ke Kulkas (+)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// CustomPainter drawing:
/// 1. Sleek rounded corner brackets in #4ADE80 -> #16A34A green gradient
/// 2. Animated horizontal laser scan line with a glowing Light-to-Dark Green
///    gradient (#4ADE80 to #16A34A) sweeping smoothly up and down.
class _ScannerBracketAndLaserPainter extends CustomPainter {
  final double laserProgress;

  _ScannerBracketAndLaserPainter({
    required this.laserProgress,
  });

  static const Color _brightMint = Color(0xFF4ADE80);
  static const Color _laserGreenEnd = Color(0xFF16A34A);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle HUD grid lines
    final gridPaint = Paint()
      ..color = _brightMint.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      gridPaint,
    );

    // 2. Animated Horizontal Laser Scan Line with Glowing Light-to-Dark Green Gradient (#4ADE80 to #16A34A)
    final laserY = (size.height * laserProgress).clamp(12.0, size.height - 12.0);
    final lineRect = Rect.fromLTWH(10, laserY - 1.5, size.width - 20, 3.0);

    // Soft vertical glow aura around the horizontal laser line
    final glowAuraRect = Rect.fromLTWH(
      10,
      (laserY - 32).clamp(0.0, size.height),
      size.width - 20,
      64,
    );
    final glowAuraPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _laserGreenEnd.withValues(alpha: 0.0),
          _brightMint.withValues(alpha: 0.28),
          _laserGreenEnd.withValues(alpha: 0.0),
        ],
      ).createShader(glowAuraRect);
    canvas.drawRect(glowAuraRect, glowAuraPaint);

    // Core horizontal laser line with #4ADE80 -> #16A34A gradient
    final laserLinePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _laserGreenEnd,
          _brightMint,
          _laserGreenEnd,
        ],
      ).createShader(lineRect)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(12, laserY),
      Offset(size.width - 12, laserY),
      laserLinePaint,
    );

    // 4. Sleek Rounded Corner Brackets with #4ADE80 to #16A34A Gradient
    final bracketGlowPaint = Paint()
      ..color = _brightMint.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final bracketPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_brightMint, _laserGreenEnd],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    const double len = 38.0;
    const double r = 20.0;

    final corners = <Path>[
      // Top-Left
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      // Top-Right
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, len),
      // Bottom-Left
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(len, size.height),
      // Bottom-Right
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - r,
        )
        ..lineTo(size.width, size.height - len),
    ];

    for (final path in corners) {
      canvas.drawPath(path, bracketGlowPaint);
      canvas.drawPath(path, bracketPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerBracketAndLaserPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress;
  }
}

/// Deep Botanical Forest (#0A1F14) camera viewfinder backdrop with subtle
/// fridge shelf depth cues.
class _MidnightViewfinderBackdropPainter extends CustomPainter {
  final bool flashActive;

  _MidnightViewfinderBackdropPainter({required this.flashActive});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.1,
        colors: [
          flashActive ? const Color(0xFF1C452C) : const Color(0xFF0F291E),
          const Color(0xFF07160E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Subtle horizontal fridge shelf lines
    final shelfPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.12)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(28, size.height * 0.34),
      Offset(size.width - 28, size.height * 0.34),
      shelfPaint,
    );
    canvas.drawLine(
      Offset(28, size.height * 0.58),
      Offset(size.width - 28, size.height * 0.58),
      shelfPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MidnightViewfinderBackdropPainter oldDelegate) {
    return oldDelegate.flashActive != flashActive;
  }
}
