import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/ssh_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/lg_controller.dart';

import '../widgets/new_button.dart';
import '../widgets/connection_status.dart';
import '../widgets/entry_animation.dart';

import '../theme/app_theme.dart';
import 'settings_screen.dart';

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
      _checkConnection();
    }
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.sshController.connect(
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
      _checkConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.bgDark,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Liquid Galaxy Console',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'System overview & operational controls',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      _buildControlGrid(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    color: AppTheme.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'LG CONTROLLER',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: ConnectionStatus(
                isConnected: _isConnected,
                label: _isConnected ? 'CONNECTED' : 'OFFLINE',
                onSettingsPressed: _navigateToSettings,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        final buttons = [
          NewButton(
            icon: Icons.place,
            label: 'Fly to Home\n(Agra)',
            color: Colors.green,
            onPressed: _isConnected ? widget.lgController.sendKml1 : null,
          ),
          NewButton(
            icon: Icons.change_history,
            label: 'Show 3D\nPyramid',
            color: AppTheme.purple,
            onPressed: _isConnected ? widget.lgController.sendKml2 : null,
          ),
          NewButton(
            icon: Icons.image,
            label: 'Show LG Logo',
            color: Colors.blue,
            onPressed: _isConnected
                ? () => widget.lgController.sendLogoToLeftScreen(
                    assetPath: 'assets/logo.png',
                    logoScreenNumber: 3,
                  )
                : null,
          ),
          NewButton(
            icon: Icons.hide_image,
            label: 'Clear Logo',
            color: Colors.redAccent,
            onPressed: _isConnected
                ? () => widget.lgController.clearLogoFromLeftScreen(
                    logoScreenNumber: 3,
                  )
                : null,
          ),
          NewButton(
            icon: Icons.clear_all,
            label: 'Clean KMLs',
            color: Colors.pink,
            onPressed: _isConnected ? widget.lgController.clearKmls : null,
          ),
          NewButton(
            icon: Icons.settings,
            label: 'Settings',
            color: Colors.grey,
            onPressed: _navigateToSettings,
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: buttons
              .asMap()
              .entries
              .map((e) => EntryAnimation(index: e.key, child: e.value))
              .toList(),
        );
      },
    );
  }
}
