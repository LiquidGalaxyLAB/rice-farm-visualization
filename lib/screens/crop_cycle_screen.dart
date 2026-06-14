import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';
import '../services/kml_builder_service.dart';
import '../services/tts_service.dart';
import '../data/crop_cycles.dart';
import '../data/narration_scripts.dart';
import '../models/crop_cycle.dart';
import '../theme/app_theme.dart';

class CropCycleScreen extends StatefulWidget {
  final LGController lgController;

  const CropCycleScreen({super.key, required this.lgController});

  @override
  State<CropCycleScreen> createState() => _CropCycleScreenState();
}

class _CropCycleScreenState extends State<CropCycleScreen> {
  final KmlBuilderService _kmlBuilder = KmlBuilderService();
  final TtsService _tts = TtsService();
  bool _isLoading = false;
  bool _isAutoPlaying = false;
  int _activeStageIndex = -1;
  bool _isKharif = true;

  CropCycle get _currentCycle =>
      _isKharif ? CropCycles.kharif : CropCycles.rabi;

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _isAutoPlaying = false;
    _tts.dispose();
    super.dispose();
  }

  Future<void> _showStage(int index) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _activeStageIndex = index;
    });

    try {
      final stage = _currentCycle.stages[index];

      await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
      await Future.delayed(const Duration(milliseconds: 300));

      final kml = _kmlBuilder.buildCropCycleKml(stage.name, stage.color);
      await widget.lgController.sendKmlToMaster(kml);
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(lat: 22.0, lng: 82.0, range: 4000000, tilt: 20),
      );
      // Update right screen dashboard
      await widget.lgController.showDashboard(
        _isKharif
            ? 'assets/dashboards/dashboard_crop_kharif.png'
            : 'assets/dashboards/dashboard_crop_rabi.png',
      );
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _autoPlay() async {
    if (_isAutoPlaying) {
      setState(() => _isAutoPlaying = false);
      return;
    }

    setState(() => _isAutoPlaying = true);

    // Narrate intro
    await _tts.speak(NarrationScripts.cropCycleOverview);
    await Future.delayed(const Duration(seconds: 3));

    for (int i = 0; i < _currentCycle.stages.length; i++) {
      if (!_isAutoPlaying) break;

      await _showStage(i);

      final stage = _currentCycle.stages[i];
      await _tts.speak('${stage.name}. ${stage.months}. ${stage.description}');

      // Wait for narration to finish
      int waited = 0;
      while (_tts.isSpeaking && waited < 200 && _isAutoPlaying) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }

      if (_isAutoPlaying) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    setState(() => _isAutoPlaying = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.bgDark,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSeasonToggle(),
                      const SizedBox(height: 16),
                      _buildTimeline(),
                      const SizedBox(height: 16),
                      _buildStageDetails(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _isAutoPlaying = false;
              _tts.stop();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Seasonal Crop Cycle',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFFA726),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeasonToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isKharif = true;
                  _activeStageIndex = -1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isKharif
                      ? const Color(0xFF66BB6A).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _isKharif
                      ? Border.all(
                          color: const Color(0xFF66BB6A).withOpacity(0.3),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      'Kharif Season',
                      style: TextStyle(
                        color: _isKharif
                            ? const Color(0xFF66BB6A)
                            : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'June - November',
                      style: TextStyle(
                        color: _isKharif
                            ? const Color(0xFF66BB6A).withOpacity(0.7)
                            : AppTheme.textSecondary.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isKharif = false;
                  _activeStageIndex = -1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isKharif
                      ? const Color(0xFFFFA726).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: !_isKharif
                      ? Border.all(
                          color: const Color(0xFFFFA726).withOpacity(0.3),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      'Rabi Season',
                      style: TextStyle(
                        color: !_isKharif
                            ? const Color(0xFFFFA726)
                            : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'November - April',
                      style: TextStyle(
                        color: !_isKharif
                            ? const Color(0xFFFFA726).withOpacity(0.7)
                            : AppTheme.textSecondary.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final stages = _currentCycle.stages;
    final stageIcons = [Icons.spa, Icons.grass, Icons.park, Icons.agriculture];

    return Row(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isActive = _activeStageIndex == index;
        final accentColor = _isKharif
            ? const Color(0xFF66BB6A)
            : const Color(0xFFFFA726);

        return Expanded(
          child: GestureDetector(
            onTap: () => _showStage(index),
            child: Container(
              margin: EdgeInsets.only(right: index < stages.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? accentColor.withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? accentColor.withOpacity(0.4)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    stageIcons[index],
                    color: isActive ? accentColor : AppTheme.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stage.name,
                    style: TextStyle(
                      color: isActive ? accentColor : AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.months,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStageDetails() {
    if (_activeStageIndex < 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: const Center(
          child: Text(
            'Tap a stage above to see it on Liquid Galaxy',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final stage = _currentCycle.stages[_activeStageIndex];
    final accentColor = _isKharif
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFFA726);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stage.name} — ${stage.months}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stage.description,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final accentColor = _isKharif
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFFA726);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : _autoPlay,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _isAutoPlaying
                    ? Colors.redAccent.withOpacity(0.15)
                    : accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAutoPlaying
                      ? Colors.redAccent.withOpacity(0.3)
                      : accentColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAutoPlaying ? Icons.stop : Icons.play_arrow,
                    color: _isAutoPlaying ? Colors.redAccent : accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isAutoPlaying ? 'Stop' : 'Auto-play',
                    style: TextStyle(
                      color: _isAutoPlaying ? Colors.redAccent : accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              _isAutoPlaying = false;
              _tts.stop();
              await widget.lgController.clearKmls();
              setState(() => _activeStageIndex = -1);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.clear_all, color: Colors.redAccent, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
