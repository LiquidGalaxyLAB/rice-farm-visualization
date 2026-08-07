import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_Slide> _slides = [
    _Slide(
      icon: Icons.public,
      color: Color(0xFF66BB6A),
      title: 'Welcome to Rice Farm Visualization',
      body:
          'Explore India\'s rice agriculture on the Liquid Galaxy rig, right from your phone.',
    ),
    _Slide(
      icon: Icons.map_outlined,
      color: Color(0xFF66BB6A),
      title: 'Major Rice Regions',
      body:
          'Fly to top rice-producing states, view colored production maps, and orbit any state in 3D.',
    ),
    _Slide(
      icon: Icons.water_drop_outlined,
      color: Color(0xFF42A5F5),
      title: 'Irrigation & Rainfall',
      body:
          'See rainfall patterns and irrigation sources state by state, with live dashboards on the rig.',
    ),
    _Slide(
      icon: Icons.route,
      color: Color(0xFFAB7DF6),
      title: 'Guided Tours & Seasons',
      body:
          'Take narrated tours across the rice belt and watch the seasonal crop cycle unfold.',
    ),
    _Slide(
      icon: Icons.explore_outlined,
      color: Color(0xFF42A5F5),
      title: 'Synced Navigation',
      body:
          'Pan and zoom a live map, and the Liquid Galaxy follows your view in real time.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _buildSlide(_slides[i]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_Slide s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(s.icon, color: s.color, size: 60),
          ),
          const SizedBox(height: 40),
          Text(
            s.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF66BB6A)
                : AppTheme.textSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
