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

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _showRainfallPatterns() async {
    setState(() {
      _isLoading = true;
      _activeView = 'rainfall';
    });
    try {
      await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
      await Future.delayed(const Duration(milliseconds: 300));

      final kml = _kmlBuilder.buildIrrigationKml();
      await widget.lgController.sendKmlToMaster(kml);
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(lat: 22.0, lng: 82.0, range: 3500000, tilt: 30),
      );

      await _tts.speak(NarrationScripts.irrigationOverview);
      await widget.lgController.showDashboard(
        'assets/dashboards/dashboard_irrigation.png',
      );
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _flyToStateIrrigation(String stateName) async {
    setState(() {
      _isLoading = true;
      _activeView = stateName;
    });
    try {
      final state = RiceStates.states.firstWhere((s) => s.name == stateName);
      final irrData = IrrigationData.stateWise[stateName];

      await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
      await Future.delayed(const Duration(milliseconds: 300));

      final kml = _kmlBuilder.buildStateBlueKml(state);
      await widget.lgController.sendKmlToMaster(kml);
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(
          lat: state.latitude,
          lng: state.longitude,
          range: 800000,
          tilt: 45,
        ),
      );

      if (irrData != null) {
        await _tts.speak(
          '${state.name} receives ${state.rainfall.toInt()} millimeters of annual rainfall. '
          '${state.irrigatedPercent} percent of rice area is irrigated. '
          'Major sources include tubewells at ${irrData['tubewell']}% and canals at ${irrData['canal']}%.',
        );
      }
      // Update right screen with state dashboard
      final safeName = stateName.toLowerCase().replaceAll(' ', '_');
      await widget.lgController.showDashboard(
        'assets/dashboards/dashboard_$safeName.png',
      );
    } catch (e) {
      _showError('Failed: $e');
    } finally {
      setState(() => _isLoading = false);
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewStats(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
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
            onTap: () {
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
              'Irrigation & Rainfall',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _tts.stop();
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _tts.isSpeaking
                    ? Colors.redAccent.withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _tts.isSpeaking ? Icons.volume_off : Icons.volume_up,
                color: _tts.isSpeaking
                    ? Colors.redAccent
                    : AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
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
            value: '${avgIrrigated.toStringAsFixed(1)}',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
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
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : _showRainfallPatterns,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _activeView == 'rainfall'
                    ? const Color(0xFF42A5F5).withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _activeView == 'rainfall'
                      ? const Color(0xFF42A5F5).withOpacity(0.3)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud,
                    color: _activeView == 'rainfall'
                        ? const Color(0xFF42A5F5)
                        : AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Show on LG',
                    style: TextStyle(
                      color: _activeView == 'rainfall'
                          ? const Color(0xFF42A5F5)
                          : AppTheme.textSecondary,
                      fontSize: 12,
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
              _tts.stop();
              await widget.lgController.clearKmls();
              setState(() => _activeView = null);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.clear_all, color: Colors.redAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStateList() {
    final states = RiceStates.states;

    return Column(
      children: states.map((state) {
        final irrData = IrrigationData.stateWise[state.name];
        final isActive = _activeView == state.name;
        final maxRainfall = 3000.0;
        final rainfallBar = state.rainfall / maxRainfall;

        return GestureDetector(
          onTap: () => _flyToStateIrrigation(state.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF0D47A1).withOpacity(0.2)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF42A5F5).withOpacity(0.4)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.rainfall.toInt()} mm',
                        style: const TextStyle(
                          color: Color(0xFF42A5F5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.irrigatedPercent}%',
                        style: const TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (irrData != null) ...[
                  const SizedBox(height: 10),
                  _buildIrrigationBar(irrData),
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: rainfallBar,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF42A5F5),
                    ),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIrrigationBar(Map<String, dynamic> data) {
    final total =
        (data['canal'] as double) +
        (data['tubewell'] as double) +
        (data['tank'] as double) +
        (data['other'] as double);

    return Row(
      children: [
        _buildIrrSegment(
          'Canal',
          data['canal'],
          total,
          const Color(0xFF42A5F5),
        ),
        _buildIrrSegment(
          'Tubewell',
          data['tubewell'],
          total,
          const Color(0xFF66BB6A),
        ),
        _buildIrrSegment('Tank', data['tank'], total, const Color(0xFFFFA726)),
        _buildIrrSegment('Other', data['other'], total, AppTheme.textSecondary),
      ],
    );
  }

  Widget _buildIrrSegment(
    String label,
    double value,
    double total,
    Color color,
  ) {
    if (value < 1) return const SizedBox();
    return Expanded(
      flex: (value / total * 100).toInt().clamp(1, 100),
      child: Tooltip(
        message: '$label: ${value.toStringAsFixed(1)}%',
        child: Container(
          height: 6,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
