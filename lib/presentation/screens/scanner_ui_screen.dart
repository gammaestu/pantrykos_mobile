import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../data/services/ai_vision_service.dart';
import '../../domain/entities/detected_ingredient.dart';
import '../../domain/entities/ingredient.dart';
import '../providers/pantry_provider.dart';
import '../providers/repository_providers.dart';

/// Complete Smart Fridge AI Scanner UI for PantryKos.
/// Connects `image_picker`, [AiVisionService], and [pantryProvider] inside our
/// Dark Green (`#14532D` / `#16A34A`), Light Green (`#4ADE80` / `#DCFCE7`),
/// and Frosted White (`#FFFFFF` 92%) culinary visual system.
class ScannerUiScreen extends ConsumerStatefulWidget {
  final Set<String> currentIngredientIds;

  /// Optional test seam returning picked/captured image bytes without invoking
  /// native camera/gallery platform channels.
  final Future<Uint8List?> Function(ImageSource source)? imagePickerOverride;

  const ScannerUiScreen({
    super.key,
    this.currentIngredientIds = const <String>{},
    this.imagePickerOverride,
  });

  @override
  ConsumerState<ScannerUiScreen> createState() => _ScannerUiScreenState();
}

class _ScannerUiScreenState extends ConsumerState<ScannerUiScreen>
    with TickerProviderStateMixin {
  static const Color _viewfinderBackdrop = Color(0xFF0A1F14);
  static const Color _mintAccent = AppTheme.mintLeaf;
  static const Color _forestPrimary = AppTheme.forestEmerald;
  static const Color _frostedSurface = AppTheme.pureWhite;
  static const Color _sheetTopBorder = AppTheme.borderMint;

  /// Minimal valid 1x1 JPEG header used only when running an offline demo
  /// simulation without a hardware camera/gallery image selected yet.
  static final Uint8List _demoPlaceholderBytes = Uint8List.fromList(const <int>[
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
  ]);

  late final AnimationController _laserController;
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _capturedImageBytes;
  List<DetectedIngredient> _detections = const <DetectedIngredient>[];
  final Set<String> _selectedIds = <String>{};
  bool _isScanning = false;
  bool _hasScannedCurrentImage = false;
  bool _flashOn = false;
  String? _errorMessage;

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
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _captureOrPickImage(ImageSource source) async {
    if (_isScanning) return;
    HapticFeedback.selectionClick();

    // Clear previous detection state immediately before opening camera/gallery.
    setState(() {
      _detections = const <DetectedIngredient>[];
      _selectedIds.clear();
      _errorMessage = null;
      _hasScannedCurrentImage = false;
    });

    Uint8List? bytes;
    try {
      if (widget.imagePickerOverride != null) {
        bytes = await widget.imagePickerOverride!(source);
      } else {
        final picked = await _imagePicker.pickImage(
          source: source,
          maxWidth: 640,
          maxHeight: 640,
          imageQuality: 70,
        );
        if (picked != null) {
          bytes = await picked.readAsBytes();
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Gagal mengakses ${source == ImageSource.camera ? 'kamera' : 'galeri'}: '
            '${e.message ?? 'Periksa izin perangkat Anda.'}';
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal membaca foto: $e';
      });
      return;
    }

    if (bytes == null || bytes.isEmpty || !mounted) return;

    setState(() {
      _capturedImageBytes = bytes;
      _errorMessage = null;
      _detections = const <DetectedIngredient>[];
      _selectedIds.clear();
      _hasScannedCurrentImage = false;
    });

    await _analyzeBytes(bytes);
  }

  Future<void> _runRescan() async {
    if (_isScanning) return;
    HapticFeedback.heavyImpact();

    final pantryState = ref.read(pantryProvider);
    if (_capturedImageBytes == null && !pantryState.useOfflineSimulation) {
      await _captureOrPickImage(ImageSource.camera);
      return;
    }

    await _analyzeBytes(_capturedImageBytes ?? _demoPlaceholderBytes);
  }

  Future<void> _analyzeBytes(Uint8List bytes) async {
    final pantryState = ref.read(pantryProvider);
    final aiService = ref.read(aiVisionServiceProvider);

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _detections = const <DetectedIngredient>[];
      _selectedIds.clear();
      _hasScannedCurrentImage = false;
    });
    _laserController.duration = const Duration(milliseconds: 700);
    _laserController.repeat(reverse: true);

    try {
      final encodedBase64 = await compute(encodeBase64InIsolate, bytes);
      final results = await aiService.analyzeImage(
        imageBytes: bytes,
        masterIngredients: pantryState.masterIngredients,
        apiKey: pantryState.geminiApiKey,
        modelName: pantryState.geminiModel,
        useOfflineSimulation: pantryState.useOfflineSimulation,
        mimeType: _inferImageMimeType(bytes),
        preEncodedBase64: encodedBase64,
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _detections = results;
        _selectedIds
          ..clear()
          ..addAll(results.map((item) => item.ingredientId));
        _isScanning = false;
        _hasScannedCurrentImage = true;
        _errorMessage = null;
      });
    } on AiVisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _hasScannedCurrentImage = false;
        _detections = const <DetectedIngredient>[];
        _selectedIds.clear();
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _hasScannedCurrentImage = false;
        _detections = const <DetectedIngredient>[];
        _selectedIds.clear();
        _errorMessage = 'Gagal terhubung ke server AI: $e';
      });
    } finally {
      if (mounted) {
        _laserController.duration = const Duration(milliseconds: 2400);
        _laserController.repeat(reverse: true);
      }
    }
  }

  static String _inferImageMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  void _toggleDetectedSelection(String ingredientId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.remove(ingredientId)) {
        _selectedIds.add(ingredientId);
      }
    });
  }

  void _confirmAndReturn() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();
    final selectedList = _selectedIds.toList(growable: false);
    ref.read(pantryProvider.notifier).addDetectedIngredients(selectedList);
    Navigator.of(context).pop(Set<String>.unmodifiable(_selectedIds));
  }

  @override
  Widget build(BuildContext context) {
    final pantryState = ref.watch(pantryProvider);
    final ingredientById = <String, Ingredient>{
      for (final ing in pantryState.masterIngredients) ing.id: ing,
    };

    return Scaffold(
      backgroundColor: _viewfinderBackdrop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Captured Photo OR Botanical Forest Simulated Backdrop
          if (_capturedImageBytes != null)
            Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _capturedImageBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.42),
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.56),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            CustomPaint(
              painter: _MidnightViewfinderBackdropPainter(
                flashActive: _flashOn,
              ),
            ),

          // 2. Scanner Viewfinder Frame (Corner Brackets, Laser Sweep, Floating Badges & Status Pill)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 78, 22, 265),
              child: AnimatedBuilder(
                animation: _laserController,
                builder: (context, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Rounded #4ADE80 -> #16A34A Brackets + Glowing Sweeping Laser Line
                      CustomPaint(
                        painter: _ScannerBracketAndLaserPainter(
                          laserProgress: _laserController.value,
                          isProcessing: _isScanning,
                        ),
                      ),

                      // Floating AI Confidence Badges over the preview once detection completes
                      if (!_isScanning && _detections.isNotEmpty)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 14,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: List<Widget>.generate(
                              _detections.length,
                              (index) {
                                final det = _detections[index];
                                final icon =
                                    ingredientById[det.ingredientId]?.icon ??
                                    '🥗';
                                final pct = (det.confidence * 100).round();
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey(
                                    'badge_${det.ingredientId}_$pct',
                                  ),
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                    milliseconds: 280 + (index * 90),
                                  ),
                                  curve: Curves.easeOutBack,
                                  builder: (context, anim, child) {
                                    return Transform.translate(
                                      offset: Offset(0, (1.0 - anim) * 14),
                                      child: Opacity(
                                        opacity: anim.clamp(0.0, 1.0),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 11,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: AppTheme.sageMint,
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.16,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              icon,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              det.detectedName,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    AppTheme.textForestCharcoal,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.sageMint,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '$pct%',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: _forestPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Empty Viewfinder Quick Capture Prompt (when no photo & not scanning)
                      if (!_isScanning &&
                          _capturedImageBytes == null &&
                          _detections.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.sageMint,
                                      width: 1.3,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.sageMint,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.mintLeaf,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_enhance_rounded,
                                          color: _forestPrimary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        pantryState.useOfflineSimulation
                                            ? 'Mode Simulasi Offline Aktif'
                                            : '${pantryState.geminiModel} Vision Siap',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textForestCharcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Ambil foto isi kulkas/stok atau pilih foto dari galeri.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppTheme.textSageGrey,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _captureOrPickImage(
                                                  ImageSource.camera,
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _forestPrimary,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 9,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.photo_camera_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Kamera',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _captureOrPickImage(
                                                  ImageSource.gallery,
                                                ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _forestPrimary,
                                              backgroundColor:
                                                  AppTheme.sageMint,
                                              side: const BorderSide(
                                                color: _mintAccent,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 9,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.photo_library_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Galeri',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Frosted White Status Pill while AiVisionService.analyzeImage() is running
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
                                  horizontal: 18,
                                  vertical: 13,
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
                                    SizedBox(width: 11),
                                    Flexible(
                                      child: Text(
                                        'AI sedang mengenali bahan makanan...',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textForestCharcoal,
                                        ),
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

          // 3. Translucent Glassmorphic Top Bar ("Pindai Bahan di Kulkas")
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
                        color: Colors.white.withValues(alpha: 0.92),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          // 4. Frosted White (92%) Glassmorphic Bottom Sheet (#DCFCE7 Top Border)
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
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
                        const SizedBox(height: 12),

                        // Header Row: Detected count + Capture / Re-scan triggers
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textForestCharcoal,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            _SheetMiniActionButton(
                              icon: Icons.photo_camera_rounded,
                              label: 'Kamera',
                              onTap: _isScanning
                                  ? null
                                  : () => _captureOrPickImage(
                                        ImageSource.camera,
                                      ),
                            ),
                            const SizedBox(width: 6),
                            _SheetMiniActionButton(
                              icon: Icons.photo_library_rounded,
                              label: 'Galeri',
                              onTap: _isScanning
                                  ? null
                                  : () => _captureOrPickImage(
                                        ImageSource.gallery,
                                      ),
                            ),
                            if (_capturedImageBytes != null ||
                                pantryState.useOfflineSimulation) ...[
                              const SizedBox(width: 6),
                              _SheetMiniActionButton(
                                icon: Icons.refresh_rounded,
                                label: 'Pindai',
                                onTap: _isScanning
                                    ? null
                                    : () => _runRescan(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                      // Error Banner, Detection Chips, "0 Bahan Terdeteksi", or Initial Hint
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7F1D1D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_capturedImageBytes != null ||
                                  pantryState.useOfflineSimulation) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isScanning ? null : _runRescan,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _forestPrimary,
                                      backgroundColor: AppTheme.pureWhite,
                                      side: const BorderSide(
                                        color: _forestPrimary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Coba Pindai Lagi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else if (_detections.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 132),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _detections.map((det) {
                                final selected = _selectedIds.contains(
                                  det.ingredientId,
                                );
                                final icon =
                                    ingredientById[det.ingredientId]?.icon ??
                                    '🥗';
                                final pct = (det.confidence * 100).round();
                                return GestureDetector(
                                  onTap: () => _toggleDetectedSelection(
                                    det.ingredientId,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppTheme.sageMint
                                          : AppTheme.scaffoldMintWhite,
                                      borderRadius: BorderRadius.circular(
                                        999,
                                      ),
                                      border: Border.all(
                                        color: selected
                                            ? _forestPrimary
                                            : AppTheme.borderMint,
                                        width: selected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          icon,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${det.detectedName} ($pct%)',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: selected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: selected
                                                ? _forestPrimary
                                                : AppTheme.textSageGrey,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.add_circle_outline_rounded,
                                          size: 16,
                                          color: selected
                                              ? _forestPrimary
                                              : AppTheme.textSageGrey,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(growable: false),
                            ),
                          ),
                        )
                      else if (_hasScannedCurrentImage)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldMintWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderMint),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 19,
                                    color: Color(0xFFD97706),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tidak Ada Bahan Terdeteksi',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textForestCharcoal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Foto tidak menampilkan bahan makanan yang dikenali. Pastikan bahan terlihat jelas dan tidak buram.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSageGrey,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isScanning
                                          ? null
                                          : () => _captureOrPickImage(
                                                ImageSource.camera,
                                              ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _forestPrimary,
                                        backgroundColor: AppTheme.pureWhite,
                                        side: const BorderSide(
                                          color: _forestPrimary,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 9,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.photo_camera_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Foto Ulang',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isScanning
                                          ? null
                                          : () => _captureOrPickImage(
                                                ImageSource.gallery,
                                              ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _forestPrimary,
                                        backgroundColor: AppTheme.sageMint,
                                        side: const BorderSide(
                                          color: _mintAccent,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 9,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.photo_library_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Pilih Galeri',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        else
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
                                    'Arahkan kamera ke bahan di kulkas atau pilih foto dari galeri untuk mulai memindai.',
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
                        const SizedBox(height: 14),

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

class _SheetMiniActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SheetMiniActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.sageMint,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppTheme.borderMint),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13.5, color: AppTheme.forestEmerald),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.forestEmerald,
              ),
            ),
          ],
        ),
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
  final bool isProcessing;

  _ScannerBracketAndLaserPainter({
    required this.laserProgress,
    required this.isProcessing,
  });

  static const Color _brightMint = Color(0xFF4ADE80);
  static const Color _laserGreenEnd = Color(0xFF16A34A);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle HUD grid lines
    final gridPaint = Paint()
      ..color = _brightMint.withValues(alpha: 0.09)
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

    final glowAuraRect = Rect.fromLTWH(
      10,
      (laserY - (isProcessing ? 44 : 32)).clamp(0.0, size.height),
      size.width - 20,
      isProcessing ? 88 : 64,
    );
    final glowAuraPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _laserGreenEnd.withValues(alpha: 0.0),
          _brightMint.withValues(alpha: isProcessing ? 0.44 : 0.28),
          _laserGreenEnd.withValues(alpha: 0.0),
        ],
      ).createShader(glowAuraRect);
    canvas.drawRect(glowAuraRect, glowAuraPaint);

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
      ..strokeWidth = isProcessing ? 3.8 : 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(12, laserY),
      Offset(size.width - 12, laserY),
      laserLinePaint,
    );

    // 3. Sleek Rounded Corner Brackets with #4ADE80 to #16A34A Gradient
    final bracketGlowPaint = Paint()
      ..color = _brightMint.withValues(alpha: isProcessing ? 0.50 : 0.35)
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
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(len, 0),
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, len),
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(len, size.height),
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
        oldDelegate.isProcessing != isProcessing;
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
