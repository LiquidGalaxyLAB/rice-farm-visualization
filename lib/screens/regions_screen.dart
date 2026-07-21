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
  String _kmlError = '';
  String? _orbitingState;

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

  void _goBack() {
    _tts.stop();
    widget.lgController.clearKmls();
    Navigator.pop(context);
  }

  Future<void> _showAllStates() async {
    setState(() {
      _isLoading = true;
      _kmlError = '';
    });
    try {
      await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final kml = _kmlBuilder.buildProductionKml();
      await widget.lgController.sendKmlToMaster(kml);
      if (!mounted) return;
      widget.lgController.verifyKmlDelivery().then((s) {
        if (mounted) setState(() => _kmlError = s);
      });
      await widget.lgController.safeQuery(
        _kmlBuilder.buildLookAt(lat: 22.0, lng: 82.0, range: 3500000, tilt: 30),
      );
      if (!mounted) return;
      setState(() => _activeState = null);
      await widget.lgController.showDashboard(
        'assets/dashboards/dashboard_production.png',
      );
      if (!mounted) return;
    } catch (e) {
      _showError('Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _flyToState(StateData state) async {
    setState(() {
      _isLoading = true;
      _activeState = state.name;
      _kmlError = '';
    });
    try {
      await widget.lgController.safeExecute('> /var/www/html/kmls.txt');
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final kml = _kmlBuilder.buildStateFlyToKml(state);
      await widget.lgController.sendKmlToMaster(kml);
      if (!mounted) return;
      widget.lgController.verifyKmlDelivery().then((s) {
        if (mounted) setState(() => _kmlError = s);
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
      final narration = _getNarration(state.name);
      if (narration != null) {
        await _tts.speak(narration);
        if (!mounted) return;
      }
      final safeName = state.name.toLowerCase().replaceAll(' ', '_');
      await widget.lgController.showDashboard(
        'assets/dashboards/dashboard_$safeName.png',
      );
      if (!mounted) return;
    } catch (e) {
      _showError('Failed to fly to ${state.name}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _orbitState(StateData state) async {
    if (_orbitingState == state.name) {
      await widget.lgController.stopOrbit();
      if (mounted) setState(() => _orbitingState = null);
      return;
    }
    if (_orbitingState != null) return;
    setState(() => _orbitingState = state.name);
    try {
      final orbitKml = _kmlBuilder.buildOrbitTourKml(
        lat: state.latitude,
        lng: state.longitude,
        range: 500000,
        tilt: 60,
      );
      await widget.lgController.startOrbit(orbitKml);
      // Full orbit = 25 steps x 0.8s + load buffer
      await Future.delayed(const Duration(seconds: 24));
    } finally {
      if (mounted && _orbitingState == state.name) {
        setState(() => _orbitingState = null);
      }
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

  void _showError(String msg) {
    if (!mounted) return;
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
              _buildKmlErrorBanner(),
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
              'Major Rice Regions',
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
                color: Color(0xFF66BB6A),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? color.withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
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

  Widget _buildOrbitPill(StateData state) {
    final bool isActive = _orbitingState == state.name;
    final bool isDisabled = _orbitingState != null && !isActive;

    if (isActive) {
      return GestureDetector(
        onTap: () => _orbitState(state),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.stop, color: Colors.redAccent, size: 14),
              SizedBox(width: 6),
              Text(
                'Stop',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isDisabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.threesixty, color: Colors.grey, size: 14),
            SizedBox(width: 6),
            Text(
              'Orbit',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _orbitState(state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF42A5F5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.threesixty, color: Color(0xFF42A5F5), size: 14),
            SizedBox(width: 6),
            Text(
              'Orbit',
              style: TextStyle(
                color: Color(0xFF42A5F5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1B5E20).withOpacity(0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? const Color(0xFF66BB6A).withOpacity(0.4)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF66BB6A).withOpacity(0.2)
                        : AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF66BB6A)
                            : AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${state.production}M tonnes  •  ${state.area}M ha  •  ${state.yield.toInt()} kg/ha',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
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
                          Icon(Icons.send, color: Color(0xFF66BB6A), size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Fly to',
                            style: TextStyle(
                              color: Color(0xFF66BB6A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildOrbitPill(state),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barWidth,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isActive
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFF66BB6A).withOpacity(0.4),
                ),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
