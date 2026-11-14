import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/mock_pantry_data.dart';
import '../theme/app_theme.dart';

/// Complete Smart Fridge AI Scanner UI for PantryKos.
/// Matches the Elegant Midnight Navy Dark Theme (#090D16 viewfinder,
/// #38BDF8 Sky Cyan corner brackets, #2563EB -> #38BDF8 sweeping laser line,
/// #131B2E 85% floating AI bounding-box pills, and sigma-16 Glassmorphic
/// Bottom Sheet with #131B2E surface and #23304E top border).
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
  static const Color _viewfinderNavy = Color(0xFF090D16);
  static const Color _skyCyan = Color(0xFF38BDF8);
  static const Color _sapphireStart = Color(0xFF2563EB);
  static const Color _darkSlateSurface = Color(0xFF131B2E);
  static const Color _sheetTopBorder = Color(0xFF23304E);

  late final AnimationController _laserController;
  late final AnimationController _pillScaleController;

  late final Set<String> _selectedIds;
  bool _isScanning = false;
  bool _flashOn = false;
  Timer? _rescanTimer;

  /// Primary 3 featured AI detections + optional bonus detections
  static const List<_AiBoundingDetection> _detections = [
    _AiBoundingDetection(
      ingredientId: 'telur',
      pillText: 'TELUR AYAM 98%',
      shortName: 'Telur Ayam',
      emoji: '🥚',
      confidence: 98,
      normalizedRect: Rect.fromLTWH(0.07, 0.16, 0.40, 0.22),
    ),
    _AiBoundingDetection(
      ingredientId: 'indomie_goreng',
      pillText: 'INDOMIE 99%',
      shortName: 'Indomie Goreng',
      emoji: '🍜',
      confidence: 99,
      normalizedRect: Rect.fromLTWH(0.51, 0.22, 0.42, 0.24),
    ),
    _AiBoundingDetection(
      ingredientId: 'sosis',
      pillText: 'SOSIS 94%',
      shortName: 'Sosis Sapi',
      emoji: '🌭',
      confidence: 94,
      normalizedRect: Rect.fromLTWH(0.12, 0.50, 0.40, 0.21),
    ),
    _AiBoundingDetection(
      ingredientId: 'keju',
      pillText: 'KEJU 96%',
      shortName: 'Keju Quick Melt',
      emoji: '🧀',
      confidence: 96,
      normalizedRect: Rect.fromLTWH(0.54, 0.56, 0.37, 0.19),
    ),
    _AiBoundingDetection(
      ingredientId: 'daun_bawang',
      pillText: 'DAUN BAWANG 92%',
      shortName: 'Daun Bawang',
      emoji: '🌿',
      confidence: 92,
      normalizedRect: Rect.fromLTWH(0.24, 0.75, 0.46, 0.16),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default 3 core detected ingredients selected ("Bahan Terdeteksi (3)")
    _selectedIds = {'telur', 'indomie_goreng', 'sosis'};

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pillScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _rescanTimer?.cancel();
    _laserController.dispose();
    _pillScaleController.dispose();
    super.dispose();
  }

  void _toggleDetection(String ingredientId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIds.contains(ingredientId)) {
        _selectedIds.remove(ingredientId);
      } else {
        _selectedIds.add(ingredientId);
      }
    });
  }

  void _triggerSimulatedRescan() {
    if (_isScanning) return;
    HapticFeedback.heavyImpact();

    setState(() => _isScanning = true);
    _pillScaleController.reverse();
    _laserController.duration = const Duration(milliseconds: 700);
    _laserController.repeat(reverse: true);

    _rescanTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _laserController.duration = const Duration(milliseconds: 2400);
      _laserController.repeat(reverse: true);
      setState(() {
        _isScanning = false;
        if (_selectedIds.isEmpty) {
          _selectedIds.addAll({'telur', 'indomie_goreng', 'sosis'});
        }
      });
      _pillScaleController.forward(from: 0.0);
    });
  }

  void _confirmAndReturn() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _viewfinderNavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Midnight Navy (#090D16) Simulated Viewfinder Background
          CustomPaint(
            painter: _MidnightViewfinderBackdropPainter(
              flashActive: _flashOn,
            ),
          ),

          // 2. Custom Scanner Overlay (Corner Brackets + Sweeping Laser + Floating AI Pills)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 78, 22, 240),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, _) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // CustomPainter: Rounded #38BDF8 Corner Brackets + Sweeping #2563EB->#38BDF8 Laser Line
                          CustomPaint(
                            painter: _ScannerBracketAndLaserPainter(
                              laserProgress: _laserController.value,
                              detections: _detections,
                              selectedIds: _selectedIds,
                              showBoxes: !_isScanning,
                            ),
                          ),

                          // 3. Simulated AI Bounding-Box Pills with Scale-In Animation
                          ...List.generate(_detections.length, (index) {
                            final item = _detections[index];
                            final isSelected = _selectedIds.contains(
                              item.ingredientId,
                            );
                            final left =
                                (item.normalizedRect.left *
                                        constraints.maxWidth)
                                    .clamp(8.0, constraints.maxWidth - 170.0);
                            final top =
                                (item.normalizedRect.top *
                                        constraints.maxHeight)
                                    .clamp(8.0, constraints.maxHeight - 48.0);

                            final intervalStart = (index * 0.12).clamp(
                              0.0,
                              0.6,
                            );
                            final curvedScale = CurvedAnimation(
                              parent: _pillScaleController,
                              curve: Interval(
                                intervalStart,
                                1.0,
                                curve: Curves.easeOutBack,
                              ),
                            );

                            return Positioned(
                              left: left,
                              top: top,
                              child: ScaleTransition(
                                scale: curvedScale,
                                child: GestureDetector(
                                  onTap: () =>
                                      _toggleDetection(item.ingredientId),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _darkSlateSurface.withValues(
                                        alpha: 0.85,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isSelected
                                            ? _skyCyan
                                            : _skyCyan.withValues(alpha: 0.45),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _skyCyan.withValues(
                                            alpha: isSelected ? 0.35 : 0.15,
                                          ),
                                          blurRadius: isSelected ? 14 : 8,
                                          spreadRadius: isSelected ? 1 : 0,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _skyCyan
                                                : AppTheme.mutedSteelSubtitle,
                                            shape: BoxShape.circle,
                                            boxShadow: isSelected
                                                ? [
                                                    const BoxShadow(
                                                      color: _skyCyan,
                                                      blurRadius: 6,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          item.pillText,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? AppTheme.iceWhiteTitle
                                                : AppTheme.mutedSteelSubtitle,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 13,
                                            color: _skyCyan,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

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
                                      color: _darkSlateSurface.withValues(
                                        alpha: 0.88,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: _skyCyan,
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
                                                  _skyCyan,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'AI Vision Memindai Kulkas...',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.iceWhiteTitle,
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
                        color: _darkSlateSurface.withValues(alpha: 0.78),
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
                              color: AppTheme.iceWhiteTitle,
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
                                color: AppTheme.iceWhiteTitle,
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
                                  ? AppTheme.amberAlmost
                                  : AppTheme.mutedSteelSubtitle,
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

          // 4. Glassmorphic Bottom Sheet (BackdropFilter sigma 16, #131B2E surface, #23304E top border)
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
                    color: _darkSlateSurface.withValues(alpha: 0.90),
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
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 28,
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
                              color: AppTheme.mutedSteelSubtitle.withValues(
                                alpha: 0.35,
                              ),
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
                                color: _skyCyan,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: _skyCyan, blurRadius: 8),
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
                                  color: AppTheme.iceWhiteTitle,
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
                                      color: _skyCyan,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pindai Ulang',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _skyCyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Compact Horizontal Toggleable Chips
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _detections.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final det = _detections[index];
                              final isSelected = _selectedIds.contains(
                                det.ingredientId,
                              );
                              final pantryItem =
                                  MockPantryData.findIngredientById(
                                    det.ingredientId,
                                  );

                              return GestureDetector(
                                onTap: () => _toggleDetection(det.ingredientId),
                                child: AnimatedScale(
                                  scale: isSelected ? 1.02 : 0.98,
                                  duration: const Duration(milliseconds: 180),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.activeChipSurface
                                          : _viewfinderNavy.withValues(
                                              alpha: 0.7,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isSelected
                                            ? _skyCyan
                                            : _sheetTopBorder,
                                        width: isSelected ? 1.4 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: _skyCyan.withValues(
                                                  alpha: 0.25,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          pantryItem?.emoji ?? det.emoji,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          det.shortName,
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
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _skyCyan.withValues(
                                                    alpha: 0.24,
                                                  )
                                                : _sheetTopBorder,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${det.confidence}%',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected
                                                  ? _skyCyan
                                                  : AppTheme.mutedSteelSubtitle,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.add_circle_outline_rounded,
                                          size: 15,
                                          color: isSelected
                                              ? _skyCyan
                                              : AppTheme.mutedSteelSubtitle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary Gradient CTA Button (#2563EB to #38BDF8) labeled "Masukkan ke Kulkas (+)"
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: _selectedIds.isEmpty
                                  ? null
                                  : const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [_sapphireStart, _skyCyan],
                                    ),
                              color: _selectedIds.isEmpty
                                  ? _sheetTopBorder
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _selectedIds.isEmpty
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: _sapphireStart.withValues(
                                          alpha: 0.42,
                                        ),
                                        blurRadius: 18,
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

class _AiBoundingDetection {
  final String ingredientId;
  final String pillText;
  final String shortName;
  final String emoji;
  final int confidence;
  final Rect normalizedRect;

  const _AiBoundingDetection({
    required this.ingredientId,
    required this.pillText,
    required this.shortName,
    required this.emoji,
    required this.confidence,
    required this.normalizedRect,
  });
}

/// CustomPainter drawing:
/// 1. Sleek rounded corner brackets in Sky Cyan (#38BDF8)
/// 2. Subtle bounding-box target frames in #38BDF8
/// 3. Animated horizontal laser scan line with a glowing Sapphire-to-Cyan
///    gradient (#2563EB to #38BDF8) sweeping smoothly up and down.
class _ScannerBracketAndLaserPainter extends CustomPainter {
  final double laserProgress;
  final List<_AiBoundingDetection> detections;
  final Set<String> selectedIds;
  final bool showBoxes;

  _ScannerBracketAndLaserPainter({
    required this.laserProgress,
    required this.detections,
    required this.selectedIds,
    required this.showBoxes,
  });

  static const Color _skyCyan = Color(0xFF38BDF8);
  static const Color _sapphireStart = Color(0xFF2563EB);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle HUD grid lines
    final gridPaint = Paint()
      ..color = _skyCyan.withValues(alpha: 0.06)
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

    // 2. Subtle AI target bounding boxes behind the floating pills
    if (showBoxes) {
      for (final det in detections) {
        final isSelected = selectedIds.contains(det.ingredientId);
        final rect = Rect.fromLTWH(
          det.normalizedRect.left * size.width,
          det.normalizedRect.top * size.height,
          det.normalizedRect.width * size.width,
          det.normalizedRect.height * size.height,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

        final fillPaint = Paint()
          ..color = _skyCyan.withValues(alpha: isSelected ? 0.08 : 0.03)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, fillPaint);

        final borderPaint = Paint()
          ..color = _skyCyan.withValues(alpha: isSelected ? 0.45 : 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.4 : 1.0;
        canvas.drawRRect(rrect, borderPaint);
      }
    }

    // 3. Animated Horizontal Laser Scan Line with Glowing Sapphire-to-Cyan Gradient (#2563EB to #38BDF8)
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
          _sapphireStart.withValues(alpha: 0.0),
          _skyCyan.withValues(alpha: 0.26),
          _sapphireStart.withValues(alpha: 0.0),
        ],
      ).createShader(glowAuraRect);
    canvas.drawRect(glowAuraRect, glowAuraPaint);

    // Core horizontal laser line with #2563EB -> #38BDF8 gradient
    final laserLinePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _sapphireStart,
          _skyCyan,
          _sapphireStart,
        ],
      ).createShader(lineRect)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(12, laserY),
      Offset(size.width - 12, laserY),
      laserLinePaint,
    );

    // 4. Sleek Rounded Corner Brackets in Sky Cyan (#38BDF8)
    final bracketGlowPaint = Paint()
      ..color = _skyCyan.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final bracketPaint = Paint()
      ..color = _skyCyan
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
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.showBoxes != showBoxes ||
        oldDelegate.selectedIds.length != selectedIds.length;
  }
}

/// Deep Midnight Navy (#090D16) camera viewfinder backdrop with subtle
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
          flashActive ? const Color(0xFF1A2947) : const Color(0xFF10192E),
          const Color(0xFF090D16),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Subtle horizontal fridge shelf lines
    final shelfPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.10)
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
