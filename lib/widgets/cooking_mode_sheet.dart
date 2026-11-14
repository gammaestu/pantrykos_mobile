import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';

/// Full-screen Dark Navy (#090D16) Step-by-Step Cooking Mode Sheet.
/// Features a PageView, a #38BDF8 animated progress indicator bar,
/// large readable instructions in #131B2E cards with #23304E borders,
/// and a built-in interactive circular/pill countdown timer widget
/// (Start / Pause / Reset).
class CookingModeSheet extends StatefulWidget {
  final RecipeModel recipe;

  const CookingModeSheet({super.key, required this.recipe});

  @override
  State<CookingModeSheet> createState() => _CookingModeSheetState();
}

class _CookingModeSheetState extends State<CookingModeSheet> {
  // Exact Step 3 Midnight Navy Theme Palette
  static const Color _bgNavy = Color(0xFF090D16);
  static const Color _cardSlate = Color(0xFF131B2E);
  static const Color _borderSlate = Color(0xFF23304E);
  static const Color _skyCyan = Color(0xFF38BDF8);
  static const Color _sapphireBlue = Color(0xFF2563EB);
  static const Color _royalSurface = Color(0xFF1E3A8A);
  static const Color _softSkyText = Color(0xFF60A5FA);
  static const Color _emeraldReady = Color(0xFF10B981);
  static const Color _amberWarn = Color(0xFFF59E0B);
  static const Color _iceWhite = Color(0xFFF8FAFC);
  static const Color _mutedSteel = Color(0xFF94A3B8);

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
          backgroundColor: _cardSlate,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _borderSlate, width: 1.2),
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
                    color: _emeraldReady.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _emeraldReady.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🍲', style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Masakan Siap Disantap!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _iceWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selamat menikmati ${widget.recipe.title} hangat buatan sendiri. Hemat pengeluaran kos hari ini!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _mutedSteel,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_emeraldReady, _skyCyan],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(
                        Icons.celebration_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Selesai Masak',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
          height: MediaQuery.of(context).size.height * 0.93,
          decoration: const BoxDecoration(
            color: _bgNavy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: _borderSlate, width: 1.4),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // 1. Top Header + #38BDF8 Smooth Progress Indicator Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: _mutedSteel.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Tool Badge (#1E3A8A surface with #60A5FA text)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _royalSurface.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _softSkyText.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.recipe.cookingTool.icon,
                                    size: 14,
                                    color: _softSkyText,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      widget.recipe.cookingTool.badgeLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _softSkyText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Spacer(),
                          Text(
                            'Langkah ${_currentStepIndex + 1} / $totalSteps',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _iceWhite,
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _iceWhite,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: _cardSlate,
                              side: const BorderSide(color: _borderSlate),
                              padding: const EdgeInsets.all(7),
                              minimumSize: const Size(36, 36),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // #38BDF8 Animated Progress Indicator Bar
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
                              backgroundColor: _cardSlate,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                _skyCyan,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Step Selector Pills
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
                                  horizontal: 13,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isCurrent
                                      ? const LinearGradient(
                                          colors: [_sapphireBlue, _skyCyan],
                                        )
                                      : null,
                                  color: isCurrent
                                      ? null
                                      : (isDone
                                          ? _emeraldReady.withValues(
                                              alpha: 0.16,
                                            )
                                          : _cardSlate),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isCurrent
                                        ? _skyCyan
                                        : (isDone
                                            ? _emeraldReady
                                            : _borderSlate),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isDone && !isCurrent) ...[
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 13.5,
                                        color: _emeraldReady,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      'Tahap ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? _iceWhite
                                            : (isDone
                                                ? _emeraldReady
                                                : _mutedSteel),
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

                const Divider(height: 1, color: _borderSlate),

                // 2. Full-Screen Dark Navy PageView for Step-by-Step Instructions + Timer
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
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step Number Badge + Step Title
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_sapphireBlue, _skyCyan],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _skyCyan.withValues(alpha: 0.30),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${step.stepNumber}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    step.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _iceWhite,
                                      letterSpacing: -0.3,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Large Readable Instructions Card (#131B2E surface, #23304E border)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: _cardSlate,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _borderSlate,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.38),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.menu_book_rounded,
                                        size: 15,
                                        color: _skyCyan,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'INSTRUKSI MEMASAK',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: _skyCyan,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    step.instruction,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                      color: _iceWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Built-in Interactive Circular/Pill Countdown Timer Widget (Start/Pause/Reset)
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

                            // Tips Dapur Anak Kos Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _cardSlate,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _amberWarn.withValues(alpha: 0.45),
                                  width: 1.1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _amberWarn.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.tips_and_updates_rounded,
                                      size: 18,
                                      color: _amberWarn,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tips Anak Kos',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: _amberWarn,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          step.kosTip,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: _mutedSteel,
                                            height: 1.45,
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

                // 3. Bottom Step Navigation Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  decoration: const BoxDecoration(
                    color: _cardSlate,
                    border: Border(
                      top: BorderSide(color: _borderSlate, width: 1.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_currentStepIndex > 0) ...[
                        OutlinedButton.icon(
                          onPressed: () => _goToStep(_currentStepIndex - 1),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _iceWhite,
                            side: const BorderSide(color: _borderSlate),
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
                            gradient: LinearGradient(
                              colors: _currentStepIndex == totalSteps - 1
                                  ? const [_emeraldReady, _skyCyan]
                                  : const [_sapphireBlue, _skyCyan],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (_currentStepIndex == totalSteps - 1
                                        ? _emeraldReady
                                        : _sapphireBlue)
                                    .withValues(alpha: 0.38),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ],
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
                              color: Colors.white,
                            ),
                            label: Text(
                              _currentStepIndex == totalSteps - 1
                                  ? 'Selesai Masak!'
                                  : 'Langkah Berikutnya',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
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

/// Interactive Circular & Pill Countdown Timer Widget (Start / Pause / Reset)
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
  static const Color _bgNavy = Color(0xFF090D16);
  static const Color _cardSlate = Color(0xFF131B2E);
  static const Color _borderSlate = Color(0xFF23304E);
  static const Color _skyCyan = Color(0xFF38BDF8);
  static const Color _sapphireBlue = Color(0xFF2563EB);
  static const Color _emeraldReady = Color(0xFF10B981);
  static const Color _iceWhite = Color(0xFFF8FAFC);
  static const Color _mutedSteel = Color(0xFF94A3B8);

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

    final Color activeColor = _isFinished ? _emeraldReady : _skyCyan;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardSlate,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRunning || _isFinished ? activeColor : _borderSlate,
          width: _isRunning || _isFinished ? 1.5 : 1.0,
        ),
        boxShadow: _isRunning
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Circular Countdown Gauge
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: _CircularTimerPainter(
                progress: ratio,
                color: activeColor,
                trackColor: _borderSlate,
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
                        color: _iceWhite,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _isFinished
                          ? 'SELESAI'
                          : (_isRunning ? 'BERJALAN' : 'TIMER'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: activeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Pill Controls (Start / Pause / Reset / +30s)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 15, color: activeColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _iceWhite,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isFinished
                      ? 'Waktu selesai! Lanjut ke langkah berikutnya.'
                      : (_isRunning
                            ? 'Menghitung mundur waktu memasak...'
                            : 'Gunakan timer agar masakan matang pas.'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _mutedSteel,
                  ),
                ),
                const SizedBox(height: 12),

                // Pill Buttons: Start/Pause + Reset + +30s
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Start / Pause Pill Button
                    GestureDetector(
                      onTap: _toggleTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: _isFinished
                              ? const LinearGradient(
                                  colors: [_emeraldReady, _skyCyan],
                                )
                              : const LinearGradient(
                                  colors: [_sapphireBlue, _skyCyan],
                                ),
                          borderRadius: BorderRadius.circular(999),
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
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isFinished
                                  ? 'Ulangi'
                                  : (_isRunning ? 'Pause' : 'Start'),
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

                    // Reset Pill Button
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _bgNavy,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _borderSlate),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restart_alt_rounded,
                              size: 15,
                              color: _mutedSteel,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _iceWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // +30s Boost Pill
                    GestureDetector(
                      onTap: _addThirtySeconds,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _bgNavy,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _borderSlate),
                        ),
                        child: const Text(
                          '+30s',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _skyCyan,
                          ),
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
