import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';
import '../services/kml_builder_service.dart';
import '../services/tts_service.dart';
import '../services/tour_engine.dart';
import '../models/tour_step.dart';
import '../data/narration_scripts.dart';
import '../data/rice_states.dart';
import '../theme/app_theme.dart';

class ToursScreen extends StatefulWidget {
  final LGController lgController;
  const ToursScreen({super.key, required this.lgController});
  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  final KmlBuilderService _kmlBuilder = KmlBuilderService();
  final TtsService _tts = TtsService();
  late final TourEngine _tourEngine;
  bool _tourActive = false;
  String _kmlError = '';

  @override
  void initState() {
    super.initState();
    _tts.init();
    _tourEngine = TourEngine(
      lgController: widget.lgController,
      kmlBuilder: _kmlBuilder,
      ttsService: _tts,
    );
    _tourEngine.onStepChanged = () => setState(() {});
    _tourEngine.onTourComplete = () {
      setState(() => _tourActive = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tour completed!')));
    };
  }

  @override
  void dispose() {
    _tourEngine.stop();
    _tts.dispose();
    super.dispose();
  }

  void _goBack() {
    _tourEngine.stop();
    widget.lgController.clearKmls();
    Navigator.pop(context);
  }

  List<TourStep> _buildRiceBeltTour() {
    return NarrationScripts.riceBeltTour.map((data) {
      String? kmlContent;
      if (data['kmlAction'] == 'production') {
        kmlContent = _kmlBuilder.buildProductionTierKml();
      } else if (data['kmlAction'] == 'state') {
        final state = RiceStates.states.firstWhere(
          (s) => s.name == data['title'],
          orElse: () => RiceStates.states.first,
        );
        kmlContent = _kmlBuilder.buildStateFlyToKml(state);
      }
      return TourStep(
        title: data['title'],
        narration: data['narration'],
        latitude: data['lat'],
        longitude: data['lng'],
        range: data['range'],
        tilt: data['tilt'],
        heading: data['heading'],
        kmlAction: kmlContent,
        dashboardKey: data['kmlAction'] == 'state'
            ? data['title'] // state name → production dashboard
            : 'national', // 'production' steps → national dashboard
      );
    }).toList();
  }

  List<TourStep> _buildIrrigationTour() {
    return NarrationScripts.irrigationTour.map((data) {
      String? kmlContent;
      if (data['kmlAction'] == 'irrigation') {
        kmlContent = _kmlBuilder.buildIrrigationKml();
      } else if (data['kmlAction'] == 'state') {
        final state = RiceStates.states.firstWhere(
          (s) => s.name == data['title'],
          orElse: () => RiceStates.states.first,
        );
        kmlContent = _kmlBuilder.buildStateBlueKml(state);
      }
      return TourStep(
        title: data['title'],
        narration: data['narration'],
        latitude: data['lat'],
        longitude: data['lng'],
        range: data['range'],
        tilt: data['tilt'],
        heading: data['heading'],
        kmlAction: kmlContent,
        dashboardKey: data['kmlAction'] == 'state'
            ? 'irrigation:${data['title']}' // per-state irrigation dashboard
            : 'national',
      );
    }).toList();
  }

  List<TourStep> _buildSeasonalTour() {
    final stageColors = {
      'sowing': 'ff00ffff',
      'transplanting': 'ff00ff88',
      'growth': 'ff00cc00',
      'harvest': 'ff00aaff',
    };
    return NarrationScripts.seasonalFarmingTour.map((data) {
      final action = data['kmlAction'] as String;
      String? kmlContent;
      if (action == 'overview') {
        kmlContent = _kmlBuilder
            .buildProductionTierKml(); // colored production map
      } else {
        final color = stageColors[action] ?? 'ff00cc00';
        kmlContent = _kmlBuilder.buildCropCycleKml(data['title'], color);
      }
      return TourStep(
        title: data['title'],
        narration: data['narration'],
        latitude: data['lat'],
        longitude: data['lng'],
        range: data['range'],
        tilt: data['tilt'],
        heading: data['heading'],
        kmlAction: kmlContent,
        dashboardKey: action == 'overview' ? 'national' : 'crop:Kharif:$action',
      );
    }).toList();
  }

  Future<void> _startTour() async {
    final steps = _buildRiceBeltTour();
    _tourEngine.loadTour(steps);
    setState(() {
      _tourActive = true;
      _kmlError = '';
    });
    await widget.lgController.showNationalDashboard();
    if (!mounted) return;
    await _tourEngine.play();
    if (!mounted) return;
    widget.lgController.verifyKmlDelivery().then((s) {
      if (mounted) setState(() => _kmlError = s);
    });
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
              _buildKmlErrorBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTourCard(
                        title: "India's Rice Belt Tour",
                        description:
                            'Fly across India\'s major rice-producing regions with narration',
                        steps: 7,
                        icon: Icons.route,
                        color: const Color(0xFFAB47BC),
                        onPlay: _startTour,
                      ),
                      const SizedBox(height: 12),
                      _buildTourCard(
                        title: 'Irrigation Systems Tour',
                        description:
                            'Explore water management across agricultural zones',
                        steps: 5,
                        icon: Icons.water_drop,
                        color: const Color(0xFF42A5F5),
                        onPlay: () async {
                          final steps = _buildIrrigationTour();
                          _tourEngine.loadTour(steps);
                          setState(() {
                            _tourActive = true;
                            _kmlError = '';
                          });
                          await widget.lgController.showNationalDashboard();
                          if (!mounted) return;
                          await _tourEngine.play();
                          if (!mounted) return;
                          widget.lgController.verifyKmlDelivery().then((s) {
                            if (mounted) setState(() => _kmlError = s);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTourCard(
                        title: 'Seasonal Farming Tour',
                        description:
                            'Watch the crop cycle unfold across seasons',
                        steps: 4,
                        icon: Icons.grass,
                        color: const Color(0xFF66BB6A),
                        onPlay: () async {
                          final steps = _buildSeasonalTour();
                          _tourEngine.loadTour(steps);
                          setState(() {
                            _tourActive = true;
                            _kmlError = '';
                          });
                          await widget.lgController.showNationalDashboard();
                          if (!mounted) return;
                          await _tourEngine.play();
                          if (!mounted) return;
                          widget.lgController.verifyKmlDelivery().then((s) {
                            if (mounted) setState(() => _kmlError = s);
                          });
                        },
                      ),
                      if (_tourActive) ...[
                        const SizedBox(height: 24),
                        _buildNowPlaying(),
                      ],
                    ],
                  ),
                ),
              ),
              if (_tourActive) _buildPlaybackControls(),
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
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Guided Tours',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKmlErrorBanner() {
    if (_kmlError.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _kmlError,
        softWrap: true,
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }

  Widget _buildTourCard({
    required String title,
    required String description,
    required int steps,
    required IconData icon,
    required Color color,
    required VoidCallback onPlay,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.list, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                '$steps steps',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.volume_up,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'Narrated',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _tourActive ? null : onPlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _tourActive
                        ? Colors.grey.withOpacity(0.1)
                        : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _tourActive
                          ? Colors.grey.withOpacity(0.2)
                          : color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: _tourActive ? Colors.grey : color,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Start',
                        style: TextStyle(
                          color: _tourActive ? Colors.grey : color,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    final step = _tourEngine.currentStep;
    if (step == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFAB47BC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFAB47BC).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Color(0xFFAB47BC), size: 18),
              const SizedBox(width: 8),
              Text(
                'Step ${_tourEngine.currentIndex + 1} of ${_tourEngine.totalSteps}',
                style: const TextStyle(
                  color: Color(0xFFAB47BC),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_tourEngine.currentIndex + 1) / _tourEngine.totalSteps,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFAB47BC)),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            icon: Icons.skip_previous,
            onTap: () => _tourEngine.previous(),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              if (_tourEngine.isPaused) {
                _tourEngine.resume();
              } else {
                _tourEngine.pause();
              }
              setState(() {});
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFAB47BC).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFAB47BC).withOpacity(0.4),
                ),
              ),
              child: Icon(
                _tourEngine.isPaused ? Icons.play_arrow : Icons.pause,
                color: const Color(0xFFAB47BC),
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _controlButton(
            icon: Icons.skip_next,
            onTap: () => _tourEngine.next(),
          ),
          const SizedBox(width: 16),
          _controlButton(
            icon: Icons.stop,
            color: Colors.redAccent,
            onTap: () async {
              await _tourEngine.stop();
              await widget.lgController.clearKmls();
              setState(() => _tourActive = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    Color color = AppTheme.textSecondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.bgDark,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
