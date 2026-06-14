import 'package:flutter/material.dart';
import '../controllers/lg_controller.dart';
import '../services/kml_builder_service.dart';
import '../data/rice_states.dart';
import '../models/state_data.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';
import '../data/narration_scripts.dart';

class RegionsScreen extends StatefulWidget {
  final LGController lgController;

  const RegionsScreen({super.key, required this.lgController});

  @override
  State<RegionsScreen> createState() => _RegionsScreenState();
}

class _RegionsScreenState extends State<RegionsScreen> {
  final KmlBuilderService _kmlBuilder = KmlBuilderService();
  bool _isLoading = false;
  String? _activeState;
  final TtsService _tts = TtsService();

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

  Future<void> _showAllStates() async {
    setState(() => _isLoading = true);
    try {
      await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
      await Future.delayed(const Duration(milliseconds: 300));

      final kml = _kmlBuilder.buildProductionKml();
      await widget.lgController.sendKmlToMaster(kml);
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(lat: 22.0, lng: 82.0, range: 3500000, tilt: 30),
      );
      setState(() => _activeState = null);
      await widget.lgController.showDashboard(
        'assets/dashboards/dashboard_production.png',
      );
    } catch (e) {
      _showError('Failed to load: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // Future<void> _flyToState(StateData state) async {
  //     setState(() {
  //       _isLoading = true;
  //       _activeState = state.name;
  //     });
  //     try {
  //       await widget.lgController.safeExecute(
  //         '> /var/www/html/kmls.txt',
  //       );
  //       await Future.delayed(const Duration(milliseconds: 300));

  //       final kml = _kmlBuilder.buildStateFlyToKml(state);
  //       await widget.lgController.sendKmlToMaster(kml);
  //       await widget.lgController.safeQuery(
  //         _kmlBuilder.buildLookAt(
  //           lat: state.latitude,
  //           lng: state.longitude,
  //           range: 800000,
  //           tilt: 45,
  //         ),
  //       );
  //     } catch (e) {
  //       _showError('Failed to fly to ${state.name}: $e');
  //     } finally {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  Future<void> _flyToState(StateData state) async {
    setState(() {
      _isLoading = true;
      _activeState = state.name;
    });
    try {
      await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
      await Future.delayed(const Duration(milliseconds: 300));

      final kml = _kmlBuilder.buildStateFlyToKml(state);
      await widget.lgController.sendKmlToMaster(kml);
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(
          lat: state.latitude,
          lng: state.longitude,
          range: 800000,
          tilt: 45,
        ),
      );

      // Play narration for this state
      final narration = _getNarration(state.name);
      if (narration != null) {
        await _tts.speak(narration);
      }

      // Update right screen dashboard
      final safeName = state.name.toLowerCase().replaceAll(' ', '_');
      await widget.lgController.showDashboard(
        'assets/dashboards/dashboard_$safeName.png',
      );
    } catch (e) {
      _showError('Failed to fly to ${state.name}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _getNarration(String stateName) {
    switch (stateName) {
      case 'West Bengal':
        return NarrationScripts.westBengal;
      case 'Uttar Pradesh':
        return NarrationScripts.uttarPradesh;
      case 'Punjab':
        return NarrationScripts.punjab;
      case 'Andhra Pradesh':
        return NarrationScripts.andhraPradesh;
      case 'Tamil Nadu':
        return NarrationScripts.tamilNadu;
      case 'Odisha':
        return NarrationScripts.odisha;
      case 'Bihar':
        return NarrationScripts.bihar;
      case 'Chhattisgarh':
        return NarrationScripts.chhattisgarh;
      case 'Assam':
        return NarrationScripts.assam;
      case 'Jharkhand':
        return NarrationScripts.jharkhand;
      default:
        return null;
    }
  }

  Future<void> _orbitState(StateData state) async {
    setState(() => _isLoading = true);
    try {
      final sequence = _kmlBuilder.buildOrbitSequence(
        lat: state.latitude,
        lng: state.longitude,
        range: 500000,
        tilt: 60,
        steps: 36,
      );
      for (final lookAt in sequence) {
        await widget.lgController.query(lookAt);
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      _showError('Orbit failed: $e');
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
              _buildActionButtons(),
              Expanded(child: _buildStateList()),
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
              'Major Rice Regions',
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
                color: Color(0xFF66BB6A),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildChipButton(
              label: 'Show all on LG',
              icon: Icons.map,
              color: const Color(0xFF66BB6A),
              filled: true,
              onTap: _showAllStates,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChipButton(
              label: 'Fly to India',
              icon: Icons.flight,
              color: const Color(0xFF42A5F5),
              filled: false,
              onTap: () async {
                await widget.lgController.query(
                  _kmlBuilder.buildLookAt(
                    lat: 22.0,
                    lng: 82.0,
                    range: 5000000,
                    tilt: 0,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChipButton(
              label: 'Clear',
              icon: Icons.clear_all,
              color: Colors.redAccent,
              filled: false,
              onTap: () async {
                await widget.lgController.clearKmls();
                setState(() => _activeState = null);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled
                ? color.withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateList() {
    final states = RiceStates.states;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        final isActive = _activeState == state.name;
        return _buildStateCard(state, index + 1, isActive);
      },
    );
  }

  Widget _buildStateCard(StateData state, int rank, bool isActive) {
    final maxProd = RiceStates.states
        .map((s) => s.production)
        .reduce((a, b) => a > b ? a : b);
    final barWidth = state.production / maxProd;

    return GestureDetector(
      onTap: () => _flyToState(state),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1B5E20).withOpacity(0.2)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFF66BB6A).withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF66BB6A).withOpacity(0.2)
                        : AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF66BB6A)
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.production}M tonnes  •  ${state.area}M ha  •  ${state.yield.toInt()} kg/ha',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _orbitState(state),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.rotate_right,
                      color: Color(0xFF42A5F5),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF66BB6A).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.send, color: Color(0xFF66BB6A), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'Fly to',
                        style: TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barWidth,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isActive
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFF66BB6A).withOpacity(0.4),
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
