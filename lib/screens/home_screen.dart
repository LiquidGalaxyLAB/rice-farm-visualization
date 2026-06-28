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
import 'about_screen.dart';

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
    if (result == true) _connectToLG();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildConnectionStatus(),
                const SizedBox(height: 28),
                _buildMenuItems(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 28),
              ],
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.eco, color: AppTheme.green, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rice Farm Agriculture',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'India Visualization Platform',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _navigateTo(const AboutScreen()),
          icon: const Icon(
            Icons.info_outline,
            color: AppTheme.textSecondary,
            size: 26,
          ),
        ),
        IconButton(
          onPressed: _navigateToSettings,
          icon: const Icon(
            Icons.settings_outlined,
            color: AppTheme.textSecondary,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return GestureDetector(
      onTap: _isConnected ? null : _connectToLG,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _isConnected
              ? AppTheme.green.withOpacity(0.08)
              : AppTheme.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isConnected
                ? AppTheme.green.withOpacity(0.2)
                : AppTheme.red.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.green,
                    ),
                  )
                : Icon(
                    _isConnected ? Icons.check_circle : Icons.error_outline,
                    color: _isConnected ? AppTheme.green : AppTheme.red,
                    size: 22,
                  ),
            const SizedBox(width: 12),
            Text(
              _isLoading
                  ? 'Connecting...'
                  : _isConnected
                  ? 'Connected to Liquid Galaxy'
                  : 'Tap to connect',
              style: TextStyle(
                color: _isConnected ? AppTheme.green : AppTheme.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_isConnected)
              Text(
                widget.settingsController.lgHost,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
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
        color: AppTheme.green,
        bgColor: AppTheme.green,
        onTap: () =>
            _navigateTo(RegionsScreen(lgController: widget.lgController)),
      ),
      _MenuItem(
        icon: Icons.grass,
        title: 'Seasonal Crop Cycle',
        subtitle: 'View Kharif and Rabi patterns',
        color: AppTheme.orange,
        bgColor: AppTheme.orange,
        onTap: () =>
            _navigateTo(CropCycleScreen(lgController: widget.lgController)),
      ),
      _MenuItem(
        icon: Icons.water_drop_outlined,
        title: 'Irrigation & Rainfall',
        subtitle: 'Analyze water management systems',
        color: AppTheme.blue,
        bgColor: AppTheme.blue,
        onTap: () =>
            _navigateTo(IrrigationScreen(lgController: widget.lgController)),
      ),
      _MenuItem(
        icon: Icons.route,
        title: 'Guided Tours',
        subtitle: 'Take curated visualization tours',
        color: AppTheme.purple,
        bgColor: AppTheme.purple,
        onTap: () =>
            _navigateTo(ToursScreen(lgController: widget.lgController)),
      ),
      _MenuItem(
        icon: Icons.sync,
        title: 'Synced Navigation',
        subtitle: 'Control LG with Google Maps',
        color: AppTheme.teal,
        bgColor: AppTheme.teal,
        onTap: () => _navigateTo(MapsScreen(lgController: widget.lgController)),
      ),
    ];

    return Column(
      children: menuItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMenuCard(item),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMenuCard(_MenuItem item) {
    return GestureDetector(
      onTap: _isConnected ? item.onTap : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.bgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                color: _isConnected ? item.color : item.color.withOpacity(0.3),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(
                        _isConnected ? 1 : 0.5,
                      ),
                      fontSize: 14,
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
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('129.8M', 'Tonnes', AppTheme.green),
          _buildDivider(),
          _buildStatItem('48.3M', 'Hectares', AppTheme.blue),
          _buildDivider(),
          _buildStatItem('2.69', 'T/Ha Yield', AppTheme.orange),
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
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
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

  Widget _buildDivider() {
    return Container(height: 36, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Actions
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.map,
                label: 'Show Production',
                color: AppTheme.green,
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
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.clear_all,
                label: 'Clean KMLs',
                color: AppTheme.red,
                onTap: _isConnected
                    ? () => widget.lgController.clearKmls()
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // LG Management Section
        const Text(
          'LG Management',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMgmtButton(
                icon: Icons.visibility,
                label: 'Show Logo',
                color: AppTheme.green,
                onTap: _isConnected
                    ? () => widget.lgController.showBranding()
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMgmtButton(
                icon: Icons.visibility_off,
                label: 'Hide Logo',
                color: AppTheme.orange,
                onTap: _isConnected
                    ? () => widget.lgController.hideLogo()
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMgmtButton(
                icon: Icons.refresh,
                label: 'Relaunch',
                color: AppTheme.blue,
                onTap: _isConnected
                    ? () => _confirmAction(
                        'Relaunch Liquid Galaxy?',
                        () => widget.lgController.relaunch(),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMgmtButton(
                icon: Icons.restart_alt,
                label: 'Reboot',
                color: AppTheme.purple,
                onTap: _isConnected
                    ? () => _confirmAction(
                        'Reboot all LG machines?',
                        () => widget.lgController.reboot(),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMgmtButton(
                icon: Icons.power_settings_new,
                label: 'Shutdown',
                color: AppTheme.red,
                onTap: _isConnected
                    ? () => _confirmAction(
                        'Shutdown all LG machines?',
                        () => widget.lgController.shutdown(),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMgmtButton({
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
          color: color.withOpacity(onTap != null ? 0.08 : 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(onTap != null ? 0.2 : 0.08),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color.withOpacity(onTap != null ? 1 : 0.3),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(onTap != null ? 1 : 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(String message, VoidCallback action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              action();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Command sent to LG'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap != null ? 0.1 : 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(onTap != null ? 0.25 : 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color.withOpacity(onTap != null ? 1 : 0.3),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(onTap != null ? 1 : 0.3),
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
