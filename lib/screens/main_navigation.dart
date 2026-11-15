import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/pantry_controller.dart';
import '../theme/app_theme.dart';
import 'bookmark_screen.dart';
import 'home_screen.dart';
import 'scanner_ui_screen.dart';

/// Root shell of PantryKos: two tabs ("Kulkas Kos" and "Tersimpan") plus a
/// prominent center "Scan AI" action inside a floating glassmorphic dock.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final PantryController _controller = PantryController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _tabIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _tabIndex = index);
  }

  Future<void> _openScanner() async {
    HapticFeedback.mediumImpact();
    final scannedIds = await Navigator.of(context).push<Set<String>>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ScannerUiScreen(
              currentIngredientIds: _controller.activeIngredientIds,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (scannedIds == null || scannedIds.isEmpty || !mounted) return;

    _controller.addIngredients(scannedIds);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 112),
        backgroundColor: AppTheme.forestEmerald,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${scannedIds.length} bahan hasil AI Scan masuk Kulkas Virtual!',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = _tabIndex == 0
        ? HomeScreen(
            key: const ValueKey('tab_home'),
            controller: _controller,
            onOpenScanner: _openScanner,
          )
        : BookmarkScreen(
            key: const ValueKey('tab_bookmark'),
            controller: _controller,
            onGoToKulkas: () => _selectTab(0),
          );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldMintWhite,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: page,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 14),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _FloatingDock(
                  currentIndex: _tabIndex,
                  bookmarkCount: _controller.bookmarkedRecipeIds.length,
                  onSelectTab: _selectTab,
                  onScan: _openScanner,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating glassmorphic dock: Frosted White (#FFFFFF @ 92%) + blur + 1px #DCFCE7 border.
class _FloatingDock extends StatefulWidget {
  final int currentIndex;
  final int bookmarkCount;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onScan;

  const _FloatingDock({
    required this.currentIndex,
    required this.bookmarkCount,
    required this.onSelectTab,
    required this.onScan,
  });

  @override
  State<_FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<_FloatingDock>
    with SingleTickerProviderStateMixin {
  static const Color _dockSurface = AppTheme.pureWhite;
  static const Color _dockBorder = AppTheme.borderMint;
  static const Color _mintLeaf = AppTheme.mintLeaf;
  static const Color _botanicalGreen = AppTheme.botanicalGreen;

  late final AnimationController _glow;
  bool _scanPressed = false;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Glass dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 68,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: _dockSurface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _dockBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DockItem(
                          icon: Icons.kitchen_outlined,
                          activeIcon: Icons.kitchen_rounded,
                          label: 'Kulkas Kos',
                          selected: widget.currentIndex == 0,
                          onTap: () => widget.onSelectTab(0),
                        ),
                      ),
                      const SizedBox(width: 92),
                      Expanded(
                        child: _DockItem(
                          icon: Icons.bookmark_border_rounded,
                          activeIcon: Icons.bookmark_rounded,
                          label: 'Tersimpan',
                          badgeCount: widget.bookmarkCount,
                          selected: widget.currentIndex == 1,
                          onTap: () => widget.onSelectTab(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center "Scan AI" floating action button with cyan glow
          Positioned(
            bottom: 14,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _scanPressed = true),
              onTapUp: (_) => setState(() => _scanPressed = false),
              onTapCancel: () => setState(() => _scanPressed = false),
              onTap: widget.onScan,
              child: AnimatedBuilder(
                animation: _glow,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_glow.value);
                  return AnimatedScale(
                    scale: _scanPressed ? 0.92 : 1.0,
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutBack,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_botanicalGreen, _mintLeaf],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _mintLeaf.withValues(
                                  alpha: 0.28 + 0.18 * t,
                                ),
                                blurRadius: 18 + 10 * t,
                                spreadRadius: 1 + 2 * t,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Scan AI',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forestEmerald,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppTheme.forestEmerald;
    final color = selected ? activeColor : AppTheme.textSageGrey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.sageMint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? AppTheme.mintLeaf.withValues(alpha: 0.65)
                        : Colors.transparent,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    selected ? activeIcon : icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: color,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -3,
                  right: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.forestEmerald,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.pureWhite,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

