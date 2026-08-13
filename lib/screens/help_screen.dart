import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.map_outlined,
        'color': const Color(0xFF66BB6A),
        'title': 'Major Rice Regions',
        'body':
            'Explore India\'s top rice-producing states. Tap a state to fly to it on the rig, use Orbit for a 360° view, and Voice to hear its details.',
      },
      {
        'icon': Icons.grass,
        'color': const Color(0xFFFFA726),
        'title': 'Seasonal Crop Cycle',
        'body':
            'Watch the Kharif and Rabi crop stages — sowing, transplanting, growth, and harvest — visualized in sequence with narration.',
      },
      {
        'icon': Icons.water_drop_outlined,
        'color': const Color(0xFF42A5F5),
        'title': 'Irrigation & Rainfall',
        'body':
            'View rainfall and water-source data for each state. Tap Fly to, Orbit, or Voice on any state to explore it on the rig.',
      },
      {
        'icon': Icons.route,
        'color': const Color(0xFFAB7DF6),
        'title': 'Guided Tours',
        'body':
            'Take three automated narrated tours across the rice belt, irrigation systems, and seasonal cycle. Use the playback controls to pause, skip, or stop.',
      },
      {
        'icon': Icons.explore_outlined,
        'color': const Color(0xFF42A5F5),
        'title': 'Synced Navigation',
        'body':
            'Pan and zoom a live Google Map, and the Liquid Galaxy camera follows your movement in real time.',
      },
      {
        'icon': Icons.link,
        'color': const Color(0xFF66BB6A),
        'title': 'Connecting to Liquid Galaxy',
        'body':
            'Tap the connection bar on the home screen, or open Settings to enter your rig\'s IP, port, username, and password. Once saved, the app connects automatically.',
      },
    ];

    return Scaffold(
      body: Container(
        color: AppTheme.bgDark,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
                    const Text(
                      'Help & Guide',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to use this app',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'A quick guide to each feature and how to use it on the Liquid Galaxy rig.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...features.map((f) => _buildHelpCard(f)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OnboardingScreen(
                              onDone: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAB7DF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFAB7DF6).withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.slideshow,
                                color: Color(0xFFAB7DF6),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'View Intro Tour',
                                style: TextStyle(
                                  color: Color(0xFFAB7DF6),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildHelpCard(Map<String, dynamic> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (f['color'] as Color).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              f['icon'] as IconData,
              color: f['color'] as Color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f['title'] as String,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  f['body'] as String,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
