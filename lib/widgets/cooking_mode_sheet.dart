import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';
import '../theme/app_theme.dart';

/// Immersive Step-by-Step Cooking Mode Sheet using [PageView],
/// smooth progress indicator bar, large readable instructions,
/// and a built-in interactive countdown timer widget for boiling/frying steps.
class CookingModeSheet extends StatefulWidget {
  final RecipeModel recipe;

  const CookingModeSheet({super.key, required this.recipe});

  @override
  State<CookingModeSheet> createState() => _CookingModeSheetState();
}

class _CookingModeSheetState extends State<CookingModeSheet> {
  late final PageController _pageController;
  int _currentStepIndex = 0;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    if (index < 0 || index >= widget.recipe.steps.length) return;
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _completeOrAdvance() {
    HapticFeedback.mediumImpact();
    setState(() {
      _completedSteps.add(_currentStepIndex);
    });
    if (_currentStepIndex < widget.recipe.steps.length - 1) {
      _goToStep(_currentStepIndex + 1);
    } else {
      _showFinishCelebration();
    }
  }

  void _showFinishCelebration() {
    HapticFeedback.heavyImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppTheme.elevatedSlateSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.slateBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldReady.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🍲', style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Masakan Siap Disantap!',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selamat menikmati ${widget.recipe.title} hangat buatan sendiri. Hemat uang jajan hari ini!',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldReady,
                    ),
                    icon: const Icon(Icons.celebration_rounded, size: 18),
                    label: const Text('Selesai Masak'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final totalSteps = steps.length;
    final progress = (totalSteps == 0)
        ? 1.0
        : (_currentStepIndex + 1) / totalSteps;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppTheme.midnightNavyScaffold,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: AppTheme.slateBorder,
                width: 1.2,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Top Drag Handle & Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.mutedSteelSubtitle.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.activeChipSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.glowingSkyBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.recipe.cookingTool.icon,
                                  size: 15,
                                  color: AppTheme.glowingSkyBorder,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Mode Masak • ${widget.recipe.cookingTool.badgeLabel}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.iceWhiteTitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Langkah ${_currentStepIndex + 1} dari $totalSteps',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.elevatedSlateSurface,
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Smooth Progress Indicator Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: progress),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor: AppTheme.elevatedSlateVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primarySapphire,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Interactive Step Selector Pills
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: totalSteps,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isCurrent = index == _currentStepIndex;
                            final isDone = _completedSteps.contains(index);
                            return GestureDetector(
                              onTap: () => _goToStep(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isCurrent
                                      ? AppTheme.primaryGradient
                                      : null,
                                  color: isCurrent
                                      ? null
                                      : (isDone
                                          ? AppTheme.emeraldReady.withValues(
                                              alpha: 0.16,
                                            )
                                          : AppTheme.elevatedSlateSurface),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isCurrent
                                        ? AppTheme.glowingSkyBorder
                                        : (isDone
                                            ? AppTheme.emeraldReady
                                            : AppTheme.slateBorder),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isDone && !isCurrent) ...[
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: AppTheme.emeraldReady,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      'Step ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? AppTheme.iceWhiteTitle
                                            : (isDone
                                                ? AppTheme.emeraldReady
                                                : AppTheme.mutedSteelSubtitle),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppTheme.slateBorder),

                // PageView for Step-by-Step Instructions + Built-in Timer
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalSteps,
                    onPageChanged: (idx) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentStepIndex = idx);
                    },
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Large Step Badge + Title
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: AppTheme.glowShadow(
                                      AppTheme.primarySapphire,
                                      intensity: 0.28,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${step.stepNumber}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontSize: 19.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Large Readable Instruction Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.elevatedSlateSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.slateBorder),
                                boxShadow: AppTheme.softShadow(context),
                              ),
                              child: Text(
                                step.instruction,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontSize: 17,
                                      height: 1.55,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Built-in Interactive Countdown Timer Widget (when step has timerSeconds)
                            if (step.timerSeconds != null) ...[
                              _InteractiveStepTimerWidget(
                                key: ValueKey('timer_${step.stepNumber}'),
                                initialSeconds: step.timerSeconds!,
                                label:
                                    step.timerLabel ??
                                    'Timer Langkah ${step.stepNumber}',
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Anak-Kos Pro Tip Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.amberAlmost.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppTheme.amberAlmost.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '💡',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tips Dapur Anak Kos',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.amberAlmost,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          step.kosTip,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.iceWhiteTitle,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation Controls
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  decoration: const BoxDecoration(
                    color: AppTheme.elevatedSlateSurface,
                    border: Border(
                      top: BorderSide(color: AppTheme.slateBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_currentStepIndex > 0) ...[
                        OutlinedButton.icon(
                          onPressed: () => _goToStep(_currentStepIndex - 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.iceWhiteTitle,
                            side: const BorderSide(color: AppTheme.slateBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                          ),
                          label: const Text('Sebelumnya'),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _currentStepIndex == totalSteps - 1
                                ? null
                                : AppTheme.primaryGradient,
                            color: _currentStepIndex == totalSteps - 1
                                ? AppTheme.emeraldReady
                                : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _completeOrAdvance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: Icon(
                              _currentStepIndex == totalSteps - 1
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                            label: Text(
                              _currentStepIndex == totalSteps - 1
                                  ? 'Selesai Masak!'
                                  : 'Langkah Berikutnya',
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
    );
  }
}

/// Interactive Countdown Timer Widget with Circular Ring, Play/Pause, Reset & +30s
class _InteractiveStepTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final String label;

  const _InteractiveStepTimerWidget({
    super.key,
    required this.initialSeconds,
    required this.label,
  });

  @override
  State<_InteractiveStepTimerWidget> createState() =>
      _InteractiveStepTimerWidgetState();
}

class _InteractiveStepTimerWidgetState
    extends State<_InteractiveStepTimerWidget> {
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isRunning = false;
  bool _isFinished = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialSeconds;
    _remainingSeconds = widget.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isFinished) {
      _resetTimer();
      return;
    }

    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_remainingSeconds > 1) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          HapticFeedback.heavyImpact();
          setState(() {
            _remainingSeconds = 0;
            _isRunning = false;
            _isFinished = true;
          });
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _totalSeconds = widget.initialSeconds;
      _remainingSeconds = widget.initialSeconds;
      _isRunning = false;
      _isFinished = false;
    });
  }

  void _addThirtySeconds() {
    HapticFeedback.lightImpact();
    setState(() {
      _totalSeconds += 30;
      _remainingSeconds += 30;
      _isFinished = false;
    });
  }

  String _formatMinSec(int totalSec) {
    final mins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _totalSeconds == 0
        ? 0.0
        : (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0);

    final Color activeColor = _isFinished
        ? AppTheme.emeraldReady
        : (_isRunning ? AppTheme.primarySapphire : AppTheme.amberAlmost);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSlateSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRunning || _isFinished
              ? activeColor
              : AppTheme.slateBorder,
          width: _isRunning || _isFinished ? 1.6 : 1.0,
        ),
        boxShadow: _isRunning
            ? AppTheme.glowShadow(activeColor, intensity: 0.22)
            : AppTheme.softShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular Custom-Painted Timer Ring
              SizedBox(
                width: 82,
                height: 82,
                child: CustomPaint(
                  painter: _CircularTimerPainter(
                    progress: ratio,
                    color: activeColor,
                    trackColor: AppTheme.elevatedSlateVariant,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMinSec(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.iceWhiteTitle,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          _isFinished
                              ? 'SELESAI!'
                              : (_isRunning ? 'AKTIF' : 'SIAP'),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: activeColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Timer Info & Controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: activeColor,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isFinished
                          ? 'Waktu habis! Saatnya lanjut ke tahap berikutnya.'
                          : (_isRunning
                                ? 'Timer sedang berjalan...'
                                : 'Ketuk Mulai untuk menghitung mundur.'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Play / Pause Button
                        InkWell(
                          onTap: _toggleTimer,
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isFinished
                                      ? Icons.replay_rounded
                                      : (_isRunning
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded),
                                  size: 17,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isFinished
                                      ? 'Ulangi'
                                      : (_isRunning ? 'Jeda' : 'Mulai Timer'),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // +30s Quick Add
                        InkWell(
                          onTap: _addThirtySeconds,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.elevatedSlateVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '+30 dtk',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.iceWhiteTitle,
                              ),
                            ),
                          ),
                        ),

                        // Reset
                        if (_remainingSeconds != widget.initialSeconds)
                          InkWell(
                            onTap: _resetTimer,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.elevatedSlateVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.restart_alt_rounded,
                                size: 16,
                                color: AppTheme.mutedSteelSubtitle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 8) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
