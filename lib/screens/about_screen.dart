import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.bgDark,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 24),
                      _buildProjectInfo(),
                      const SizedBox(height: 16),
                      _buildFeaturesList(),
                      const SizedBox(height: 16),
                      _buildTeamInfo(),
                      const SizedBox(height: 16),
                      _buildDataSources(),
                      const SizedBox(height: 16),
                      _buildTechStack(),
                      const SizedBox(height: 24),
                      _buildFooter(),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            'About',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.eco, color: Color(0xFF66BB6A), size: 50),
        ),
        const SizedBox(height: 14),
        const Text(
          'Rice Farm Agriculture',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'India Visualization Platform',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'Version 1.0.0',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProjectInfo() {
    return _buildCard(
      title: 'About the Project',
      child: const Text(
        'Rice Farm Agriculture Visualization transforms India\'s rice production data into an immersive multi-screen storytelling experience on the Liquid Galaxy platform. '
        'The app visualizes production statistics, seasonal crop cycles, irrigation patterns, and guided tours across all Indian states using KML overlays on Google Earth.',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.map,
        'title': 'All-India Production Heatmap',
        'desc': '36 states color-coded by rice output',
      },
      {
        'icon': Icons.place,
        'title': 'Major Rice Regions',
        'desc': 'Fly-to and orbit top 10 producing states',
      },
      {
        'icon': Icons.grass,
        'title': 'Seasonal Crop Cycle',
        'desc': 'Kharif and Rabi stage visualization',
      },
      {
        'icon': Icons.water_drop,
        'title': 'Irrigation & Rainfall',
        'desc': 'Water management analysis by state',
      },
      {
        'icon': Icons.route,
        'title': '3 Guided Tours',
        'desc': 'Automated storytelling with TTS narration',
      },
      {
        'icon': Icons.sync,
        'title': 'Synced Navigation',
        'desc': 'Real-time Google Maps to LG sync',
      },
      {
        'icon': Icons.tv,
        'title': 'Side Screen Dashboards',
        'desc': 'Auto-updating stats on slave screens',
      },
      {
        'icon': Icons.rotate_right,
        'title': 'Orbit Camera',
        'desc': '360° cinematic rotation around locations',
      },
    ];

    return _buildCard(
      title: 'Features',
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    f['icon'] as IconData,
                    color: const Color(0xFF66BB6A),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['title'] as String,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        f['desc'] as String,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamInfo() {
    return _buildCard(
      title: 'Team',
      child: Column(
        children: [
          _buildTeamRow('Contributor', 'Vinayak Dhaka'),
          _buildTeamRow('Mentor 1', 'Vedant Singh'),
          _buildTeamRow('Mentor 2', 'Dev Gadani'),
          _buildTeamRow('Organization', 'Liquid Galaxy Lab'),
          _buildTeamRow('Program', 'Google Summer of Code 2026'),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSources() {
    return _buildCard(
      title: 'Data Sources',
      child: Column(
        children: [
          _buildSourceRow('Production Data', 'data.gov.in'),
          _buildSourceRow('State Boundaries', 'Datameet GitHub'),
          _buildSourceRow('Crop Cycles', 'ICAR-CRRI'),
          _buildSourceRow('Rainfall Data', 'IMD'),
          _buildSourceRow('Irrigation', 'Ministry of Water Resources'),
          _buildSourceRow('Export Data', 'APEDA'),
        ],
      ),
    );
  }

  Widget _buildSourceRow(String label, String source) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          Text(
            source,
            style: const TextStyle(
              color: Color(0xFF66BB6A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStack() {
    final techs = [
      'Flutter',
      'KML',
      'Google Earth',
      'SSH/SFTP',
      'Flutter TTS',
      'Google Maps',
      'Riverpod',
    ];

    return _buildCard(
      title: 'Tech Stack',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: techs.map((t) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF42A5F5).withOpacity(0.2),
              ),
            ),
            child: Text(
              t,
              style: const TextStyle(
                color: Color(0xFF42A5F5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'Made with Flutter for Liquid Galaxy',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
        SizedBox(height: 4),
        Text(
          'GSoC 2026 • Liquid Galaxy Lab',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF66BB6A),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
