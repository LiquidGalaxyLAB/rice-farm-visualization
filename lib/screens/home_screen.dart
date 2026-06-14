import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/ssh_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/lg_controller.dart';
import '../services/kml_builder_service.dart';
import '../theme/app_theme.dart';

import 'settings_screen.dart';
import 'regions_screen.dart';
import 'crop_cycle_screen.dart';
import 'irrigation_screen.dart';
import 'tours_screen.dart';
import 'maps_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const HomeScreen({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.settingsController.lgHost.isNotEmpty &&
        widget.settingsController.lgPassword.isNotEmpty) {
      _connectToLG();
    }
  }

  Future<void> _connectToLG() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.lgController.connect(
        host: widget.settingsController.lgHost,
        port: widget.settingsController.lgPort,
        username: widget.settingsController.lgUsername,
        password: widget.settingsController.lgPassword,
      );
      setState(() => _isConnected = success);
    } catch (_) {
      setState(() => _isConnected = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          sshController: widget.sshController,
          settingsController: widget.settingsController,
        ),
      ),
    );

    if (result == true) {
      _connectToLG();
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.bgDark,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildConnectionStatus(),
                  const SizedBox(height: 24),
                  _buildMenuItems(),
                  const SizedBox(height: 20),
                  _buildQuickStats(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.eco, color: Color(0xFF66BB6A), size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rice Farm Agriculture',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              Text(
                'India Visualization Platform',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _navigateToSettings,
          icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return GestureDetector(
      onTap: _isConnected ? null : _connectToLG,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isConnected
              ? const Color(0xFF1B5E20).withOpacity(0.2)
              : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isConnected
                ? const Color(0xFF66BB6A).withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF66BB6A),
                    ),
                  )
                : Icon(
                    _isConnected ? Icons.check_circle : Icons.error_outline,
                    color: _isConnected
                        ? const Color(0xFF66BB6A)
                        : Colors.redAccent,
                    size: 18,
                  ),
            const SizedBox(width: 8),
            Text(
              _isLoading
                  ? 'Connecting...'
                  : _isConnected
                  ? 'Connected to Liquid Galaxy'
                  : 'Tap to connect',
              style: TextStyle(
                color: _isConnected
                    ? const Color(0xFF66BB6A)
                    : Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (_isConnected)
              Text(
                widget.settingsController.lgHost,
                style: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      _MenuItem(
        icon: Icons.map_outlined,
        title: 'Major Rice Regions',
        subtitle: 'Explore top rice-producing states',
        color: const Color(0xFF66BB6A),
        bgColor: const Color(0xFF1B5E20),
        onTap: () {
          _navigateTo(RegionsScreen(lgController: widget.lgController));
        },
      ),
      _MenuItem(
        icon: Icons.grass,
        title: 'Seasonal Crop Cycle',
        subtitle: 'View Kharif and Rabi patterns',
        color: const Color(0xFFFFA726),
        bgColor: const Color(0xFFE65100),
        onTap: () {
          _navigateTo(CropCycleScreen(lgController: widget.lgController));
        },
      ),
      _MenuItem(
        icon: Icons.water_drop_outlined,
        title: 'Irrigation & Rainfall',
        subtitle: 'Analyze water management systems',
        color: const Color(0xFF42A5F5),
        bgColor: const Color(0xFF0D47A1),
        onTap: () {
          _navigateTo(IrrigationScreen(lgController: widget.lgController));
        },
      ),
      _MenuItem(
        icon: Icons.route,
        title: 'Guided Tours',
        subtitle: 'Take curated visualization tours',
        color: const Color(0xFFAB47BC),
        bgColor: const Color(0xFF4A148C),
        onTap: () {
          _navigateTo(ToursScreen(lgController: widget.lgController));
        },
      ),
      _MenuItem(
        icon: Icons.map,
        title: 'Synced Navigation',
        subtitle: 'Control LG with Google Maps',
        color: const Color(0xFF26A69A),
        bgColor: const Color(0xFF004D40),
        onTap: () {
          _navigateTo(MapsScreen(lgController: widget.lgController));
        },
      ),
    ];

    return Column(
      children: menuItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildMenuCard(item),
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return GestureDetector(
      onTap: _isConnected ? item.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.bgColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: _isConnected ? item.color : item.color.withOpacity(0.4),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: _isConnected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(
                        _isConnected ? 1 : 0.5,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary.withOpacity(
                _isConnected ? 0.5 : 0.2,
              ),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          _buildStatItem('129.8M', 'Tonnes', const Color(0xFF66BB6A)),
          _buildDivider(),
          _buildStatItem('48.3M', 'Hectares', const Color(0xFF42A5F5)),
          _buildDivider(),
          _buildStatItem('2.69', 'T/Ha Yield', const Color(0xFFFFA726)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.map,
                label: 'Show Production',
                color: const Color(0xFF66BB6A),
                onTap: _isConnected
                    ? () async {
                        final kmlBuilder = KmlBuilderService();
                        final kml = kmlBuilder.buildProductionHeatmapKml();
                        await widget.lgController.sendKmlToMaster(kml);
                        await widget.lgController.query(
                          kmlBuilder.buildLookAt(
                            lat: 22.0,
                            lng: 82.0,
                            range: 3500000,
                            tilt: 30,
                          ),
                        );
                        await widget.lgController.showDashboard(
                          'assets/dashboards/dashboard_production.png',
                        );
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.tv,
                label: 'Side Screens',
                color: const Color(0xFFAB47BC),
                onTap: _isConnected
                    ? () => widget.lgController.showSideScreens()
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildActionButton(
          icon: Icons.clear_all,
          label: 'Clean KMLs',
          color: Colors.redAccent,
          onTap: _isConnected
              ? () => widget.lgController.clearKmls(keepLogos: false)
              : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap != null ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(onTap != null ? 0.3 : 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color.withOpacity(onTap != null ? 1 : 0.3),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(onTap != null ? 1 : 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}
