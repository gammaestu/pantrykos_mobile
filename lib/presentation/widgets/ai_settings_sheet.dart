import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ai_vision_service.dart';
import '../providers/pantry_provider.dart';
import '../providers/repository_providers.dart';

/// Opens the "Info Proyek & AI Status" configuration bottom sheet.
Future<void> showAiSettingsSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AiSettingsSheet(),
  );
}

/// Settings & AI Diagnostics Bottom Sheet for configuring Gemini Interactions
/// API keys (`AQ.` / `AIza...`), active model selection, live connection tests,
/// catalog endpoints, and Offline Demo Simulation mode.
class AiSettingsSheet extends ConsumerStatefulWidget {
  const AiSettingsSheet({super.key});

  @override
  ConsumerState<AiSettingsSheet> createState() => _AiSettingsSheetState();
}

class _AiSettingsSheetState extends ConsumerState<AiSettingsSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _remoteCatalogController;
  late final TextEditingController _geminiKeyController;
  late final TextEditingController _geminiModelController;

  late bool _useOfflineSimulation;
  bool _obscureApiKey = true;
  bool _isTestingConnection = false;
  String? _connectionTestMessage;
  bool? _connectionTestOk;

  @override
  void initState() {
    super.initState();
    final pantryState = ref.read(pantryProvider);
    _urlController = TextEditingController(text: pantryState.laravelBaseUrl);
    _remoteCatalogController = TextEditingController(
      text: pantryState.remoteJsonUrl,
    );
    _geminiKeyController = TextEditingController(
      text: pantryState.geminiApiKey,
    );
    _geminiModelController = TextEditingController(
      text: pantryState.geminiModel,
    );
    _useOfflineSimulation = pantryState.useOfflineSimulation;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _remoteCatalogController.dispose();
    _geminiKeyController.dispose();
    _geminiModelController.dispose();
    super.dispose();
  }

  Future<void> _selectPresetModel(String preset) async {
    HapticFeedback.selectionClick();
    setState(() {
      _geminiModelController.text = preset;
      _connectionTestMessage = null;
      _connectionTestOk = null;
    });
    await ref.read(pantryProvider.notifier).updateServerConfig(
          geminiModel: preset,
        );
  }

  Future<void> _runConnectionTest() async {
    HapticFeedback.selectionClick();
    final cleanKey = _geminiKeyController.text.replaceAll(RegExp(r'\s+'), '');
    final selectedModel = _geminiModelController.text.trim();

    setState(() {
      _isTestingConnection = true;
      _connectionTestMessage = null;
      _connectionTestOk = null;
    });

    try {
      final latencyMs = await ref
          .read(aiVisionServiceProvider)
          .testConnection(apiKey: cleanKey, model: selectedModel);
      if (!mounted) return;
      final activeModel = selectedModel.isEmpty
          ? ApiConfig.defaultGeminiModel
          : selectedModel;
      setState(() {
        _isTestingConnection = false;
        _connectionTestOk = true;
        _connectionTestMessage = 'Terhubung ($latencyMs ms) • $activeModel';
      });
    } on AiVisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _isTestingConnection = false;
        _connectionTestOk = false;
        _connectionTestMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTestingConnection = false;
        _connectionTestOk = false;
        _connectionTestMessage = '$e';
      });
    }
  }

  Future<void> _saveConfiguration() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(pantryProvider.notifier).updateServerConfig(
          baseUrl: _urlController.text,
          remoteUrl: _remoteCatalogController.text,
          geminiApiKey: _geminiKeyController.text,
          geminiModel: _geminiModelController.text,
          useOfflineSimulation: _useOfflineSimulation,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.sageMint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.forestEmerald),
        ),
        content: Text(
          _useOfflineSimulation
              ? 'Mode Offline Demo Simulation tersimpan'
              : 'Mode Live Gemini AI & API Key tersimpan',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.forestEmerald,
          ),
        ),
      ),
    );
  }

  InputDecoration _configInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: AppTheme.forestEmerald),
      filled: true,
      fillColor: AppTheme.scaffoldMintWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.borderMint),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.borderMint),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.forestEmerald, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final activeModelLabel = _geminiModelController.text.trim().isEmpty
        ? ApiConfig.defaultGeminiModel
        : _geminiModelController.text.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: AppTheme.borderMint, width: 1.5),
          ),
          boxShadow: AppTheme.softShadow(context),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSlateLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.sageMint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.mintLeaf),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        size: 20,
                        color: AppTheme.forestEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Info Proyek & AI Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textForestCharcoal,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'PantryKos • Gemini Interactions API (v1beta)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSageGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.softMintTint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderMint),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tim Pengembang',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestEmerald,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• Erlan Agam Putra\n• Gamma Estu Mahardika\n• Muhammad Fazli Nurfahmi',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textForestCharcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gemini Vision API Key',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textForestCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _geminiKeyController,
                  obscureText: _obscureApiKey,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textForestCharcoal,
                  ),
                  decoration: _configInputDecoration(
                    hint: 'AQ... / AIzaSy... (opsional untuk mode simulasi)',
                    icon: Icons.vpn_key_rounded,
                  ).copyWith(
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_geminiKeyController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Hapus',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _geminiKeyController.clear();
                              setState(() {
                                _connectionTestMessage = null;
                                _connectionTestOk = null;
                              });
                            },
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: AppTheme.textSageGrey,
                            ),
                          ),
                        IconButton(
                          tooltip: _obscureApiKey
                              ? 'Tampilkan API Key'
                              : 'Sembunyikan API Key',
                          onPressed: () {
                            setState(() => _obscureApiKey = !_obscureApiKey);
                          },
                          icon: Icon(
                            _obscureApiKey
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 18,
                            color: AppTheme.textSageGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gemini Model (Interactions API)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textForestCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _geminiModelController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textForestCharcoal,
                  ),
                  decoration: _configInputDecoration(
                    hint: ApiConfig.defaultGeminiModel,
                    icon: Icons.memory_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ApiConfig.supportedGeminiModels.map((preset) {
                    final active = _geminiModelController.text.trim() == preset;
                    return GestureDetector(
                      onTap: () => _selectPresetModel(preset),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.forestEmerald
                              : AppTheme.sageMint,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active
                                ? AppTheme.forestEmerald
                                : AppTheme.mintLeaf,
                          ),
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? AppTheme.pureWhite
                                : AppTheme.forestEmerald,
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isTestingConnection ? null : _runConnectionTest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.forestEmerald,
                      backgroundColor: AppTheme.sageMint,
                      side: const BorderSide(color: AppTheme.forestEmerald),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.forestEmerald,
                              ),
                            ),
                          )
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(
                      _isTestingConnection
                          ? 'Menguji Koneksi...'
                          : 'Tes Koneksi AI',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (_connectionTestMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: (_connectionTestOk ?? false)
                          ? AppTheme.sageMint
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_connectionTestOk ?? false)
                            ? AppTheme.mintLeaf
                            : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (_connectionTestOk ?? false)
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          size: 16,
                          color: (_connectionTestOk ?? false)
                              ? AppTheme.forestEmerald
                              : const Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionTestMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: (_connectionTestOk ?? false)
                                  ? AppTheme.forestEmerald
                                  : const Color(0xFF7F1D1D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Laravel API Base URL',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textForestCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textForestCharcoal,
                  ),
                  decoration: _configInputDecoration(
                    hint: 'http://10.0.2.2:8000/api',
                    icon: Icons.link_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Remote JSON Catalog URL',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textForestCharcoal,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _remoteCatalogController,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textForestCharcoal,
                  ),
                  decoration: _configInputDecoration(
                    hint: 'https://raw.githubusercontent.com/...',
                    icon: Icons.cloud_download_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldMintWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderMint),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _useOfflineSimulation
                                  ? 'Offline Demo Simulation'
                                  : 'Live Gemini AI',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textForestCharcoal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _useOfflineSimulation
                                  ? 'Simulasi deteksi bahan instan tanpa internet'
                                  : 'Memindai foto via $activeModelLabel',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSageGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useOfflineSimulation,
                        activeThumbColor: AppTheme.pureWhite,
                        activeTrackColor: AppTheme.forestEmerald,
                        inactiveThumbColor: AppTheme.forestEmerald,
                        inactiveTrackColor: AppTheme.sageMint,
                        onChanged: (val) {
                          setState(() => _useOfflineSimulation = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveConfiguration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestEmerald,
                      foregroundColor: AppTheme.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text(
                      'Simpan Konfigurasi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
