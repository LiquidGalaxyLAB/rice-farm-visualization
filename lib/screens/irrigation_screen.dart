import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';
import '../services/kml_builder_service.dart';
import '../services/tts_service.dart';
import '../data/rice_states.dart';
import '../data/irrigation_data.dart';
import '../data/narration_scripts.dart';
import '../theme/app_theme.dart';

class IrrigationScreen extends StatefulWidget {
  final LGController lgController;
  const IrrigationScreen({super.key, required this.lgController});
  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final KmlBuilderService _kmlBuilder = KmlBuilderService();
  final TtsService _tts = TtsService();
  bool _isLoading = false;
  String? _activeView;
  String _kmlError = '';

  @override
  void initState() {
    super.initState();
    _tts.init();
    // Auto-trigger show on LG when screen opens
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showRainfallPatterns(),
    );
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  void _goBack() {
    _tts.stop();
    widget.lgController.clearKmls();
    Navigator.pop(context);
  }
  // Future<void> _showRainfallPatterns() async {
  //   setState(() { _isLoading = true; _activeView = 'rainfall'; });
  //   try {
  //     await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
  //     await Future.delayed(const Duration(milliseconds: 300));
  //     final kml = _kmlBuilder.buildIrrigationKml();
  //     await widget.lgController.sendKmlToMaster(kml);
  //     await widget.lgController.safeQuery(_kmlBuilder.buildLookAt(lat: 22.0, lng: 82.0, range: 3500000, tilt: 30));
  //     await Future.delayed(const Duration(seconds: 3));
  //     await _tts.speak(NarrationScripts.irrigationOverview);
  //     await widget.lgController.showDashboard('assets/dashboards/dashboard_irrigation.png');
  //   } catch (e) { _showError('Failed: $e'); }
  //   finally { setState(() => _isLoading = false); }
  // }

  Future<void> _showRainfallPatterns() async {
    setState(() {
      _isLoading = true;
      _activeView = 'rainfall';
      _kmlError = '';
    });
    try {
      final kml = _kmlBuilder.buildIrrigationKml();
      await widget.lgController.sendKmlToMaster(kml);
      if (!mounted) return;
      Future.delayed(const Duration(seconds: 2), () {
        widget.lgController.verifyKmlDelivery().then((s) {
          if (mounted) setState(() => _kmlError = s);
        });
      });
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(lat: 22.0, lng: 82.0, range: 3500000, tilt: 30),
      );
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      await _tts.speak(NarrationScripts.irrigationOverview);
      if (!mounted) return;
      await widget.lgController.showNationalDashboard();
      if (!mounted) return;
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Future<void> _flyToStateIrrigation(String stateName) async {
  //   setState(() { _isLoading = true; _activeView = stateName; });
  //   try {
  //     final state = RiceStates.states.firstWhere((s) => s.name == stateName);
  //     final irrData = IrrigationData.stateWise[stateName];

  //     // Clear old KML first
  //     await widget.lgController.safeExecute('> /var/www/html/kmls.txt');

  //     await Future.delayed(const Duration(milliseconds: 300));

  //     final kml = _kmlBuilder.buildStateBlueKml(state);
  //     await widget.lgController.sendKmlToMaster(kml);
  //     await widget.lgController.safeQuery(_kmlBuilder.buildLookAt(lat: state.latitude, lng: state.longitude, range: 800000, tilt: 45));

  //     await Future.delayed(const Duration(seconds: 3));
  //     if (irrData != null) {
  //       await _tts.speak(
  //         '${state.name} receives ${state.rainfall.toInt()} millimeters of annual rainfall. '
  //         '${state.irrigatedPercent} percent of rice area is irrigated. '
  //         'Major sources include tubewells at ${irrData['tubewell']}% and canals at ${irrData['canal']}%.',
  //       );
  //     }
  //     final safeName = stateName.toLowerCase().replaceAll(' ', '_');
  //     await widget.lgController.showDashboard('assets/dashboards/dashboard_$safeName.png');
  //   } catch (e) { _showError('Failed: $e'); }
  //   finally { setState(() => _isLoading = false); }
  // }
  Future<void> _flyToStateIrrigation(String stateName) async {
    setState(() {
      _isLoading = true;
      _activeView = stateName;
      _kmlError = '';
    });
    try {
      final state = RiceStates.states.firstWhere((s) => s.name == stateName);
      final irrData = IrrigationData.stateWise[stateName];

      final kml = _kmlBuilder.buildStateBlueKml(state);
      await widget.lgController.sendKmlToMaster(kml);
      if (!mounted) return;
      await widget.lgController.showIrrigationDashboard(state);
      if (!mounted) return;
      Future.delayed(const Duration(seconds: 2), () {
        widget.lgController.verifyKmlDelivery().then((s) {
          if (mounted) setState(() => _kmlError = s);
        });
      });
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(
          lat: state.latitude,
          lng: state.longitude,
          range: 800000,
          tilt: 45,
        ),
      );
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      if (irrData != null) {
        await _tts.speak(
          '${state.name} receives ${state.rainfall.toInt()} millimeters of annual rainfall. '
          '${state.irrigatedPercent} percent of rice area is irrigated. '
          'Major sources include tubewells at ${irrData['tubewell']}% and canals at ${irrData['canal']}%.',
        );
        if (!mounted) return;
      }
      final safeName = stateName.toLowerCase().replaceAll(' ', '_');
      await widget.lgController.showDashboard(
        'assets/dashboards/dashboard_irrigation_$safeName.png',
      );
      if (!mounted) return;
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              if (_kmlError.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _kmlError,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewStats(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('State-wise Irrigation'),
                      const SizedBox(height: 10),
                      _buildStateList(),
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
              'Irrigation & Rainfall',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF42A5F5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    final avgRainfall =
        RiceStates.states.map((s) => s.rainfall).reduce((a, b) => a + b) ~/
        RiceStates.states.length;
    final avgIrrigated =
        RiceStates.states
            .map((s) => s.irrigatedPercent)
            .reduce((a, b) => a + b) /
        RiceStates.states.length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: '$avgRainfall',
            unit: 'mm',
            label: 'Avg Rainfall',
            color: const Color(0xFF42A5F5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            value: avgIrrigated.toStringAsFixed(1),
            unit: '%',
            label: 'Avg Irrigated',
            color: const Color(0xFF66BB6A),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildStateList() {
    final states = RiceStates.states;
    return Column(
      children: states.map((state) {
        final isActive = _activeView == state.name;
        return GestureDetector(
          onTap: () => _flyToStateIrrigation(state.name),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.blue.withOpacity(0.1)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppTheme.blue.withOpacity(0.3)
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.rainfall.toInt()} mm',
                    style: const TextStyle(
                      color: AppTheme.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.irrigatedPercent}%',
                    style: const TextStyle(
                      color: AppTheme.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
