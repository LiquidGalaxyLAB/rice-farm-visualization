import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/ssh_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/lg_controller.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  debugPrint(
    '=== RICE FARM BUILD v9: voice toggle + irrigation orbit + dashboard narration + onboarding ===',
  );
  WidgetsFlutterBinding.ensureInitialized();

  final settingsController = SettingsController();
  await settingsController.loadSettings();

  final sshController = SSHController();
  final lgController = LGController(
    sshController: sshController,
    settingsController: settingsController,
  );

  runApp(
    ProviderScope(
      child: MyApp(
        sshController: sshController,
        settingsController: settingsController,
        lgController: lgController,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const MyApp({
    super.key,
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LG Controller',
      theme: AppTheme.theme,
      home: _StartupGate(
        sshController: sshController,
        settingsController: settingsController,
        lgController: lgController,
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  final SSHController sshController;
  final SettingsController settingsController;
  final LGController lgController;

  const _StartupGate({
    required this.sshController,
    required this.settingsController,
    required this.lgController,
  });

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Always show onboarding on every launch (demo mode)
    setState(() => _seenOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget home = SplashScreen(
      nextScreen: HomeScreen(
        sshController: widget.sshController,
        settingsController: widget.settingsController,
        lgController: widget.lgController,
      ),
    );

    if (_seenOnboarding == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgLight,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_seenOnboarding == false) {
      return OnboardingScreen(
        onDone: () => setState(() => _seenOnboarding = true),
      );
    }

    return home;
  }
}
