import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/widgets/responsive_layout.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Effortless Management',
      description: 'Streamline your service operations with our intuitive platform designed for modern teams.',
      icon: Icons.auto_graph_rounded,
      color: const Color(0xFF6366F1), // Royal Indigo
    ),
    OnboardingContent(
      title: 'Real-time Tracking',
      description: 'Monitor task progress, location, and status updates in real-time. Never lose sight of what matters.',
      icon: Icons.map_rounded,
      color: const Color(0xFF3B82F6), // Vibrant Blue
    ),
    OnboardingContent(
      title: 'Seamless Communication',
      description: 'Update your clients instantly via WhatsApp and keep everyone synchronized effortlessly.',
      icon: Icons.message_rounded,
      color: const Color(0xFF10B981), // Fresh Emerald
    ),
    OnboardingContent(
      title: 'Ready to Lead',
      description: 'Join the most advanced service management platform. Efficiency starts here.',
      icon: Icons.verified_user_rounded,
      color: const Color(0xFFF59E0B), // Bright Amber
    ),
  ];

  void _onFinish(WidgetRef ref) {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : Colors.white;
    final textColor = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final subtextColor = isDark ? AppTheme.darkSubtext : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer(
        builder: (context, ref, child) {
          return SafeArea(
            child: ResponsiveLayout(
              maxWidth: 800,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _contents.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              index == 0
                                  ? Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: (isDark ? Colors.white : AppTheme.emeraldGreen).withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(
                                          color: (isDark ? Colors.white : AppTheme.emeraldGreen).withValues(alpha: 0.08),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/worqly_logo.svg',
                                        width: 160,
                                        height: 160,
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(36),
                                      decoration: BoxDecoration(
                                        color: _contents[index].color.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _contents[index].color.withValues(alpha: 0.25),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _contents[index].color.withValues(alpha: 0.18),
                                            blurRadius: 36,
                                            spreadRadius: 4,
                                          )
                                        ],
                                      ),
                                      child: Icon(
                                        _contents[index].icon,
                                        size: 88,
                                        color: _contents[index].color,
                                      ),
                                    ),
                              const SizedBox(height: 60),
                              Text(
                                _contents[index].title,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _contents[index].description,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: subtextColor,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            _contents.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? (isDark ? AppTheme.accentGold : AppTheme.emeraldGreen)
                                    : (isDark ? Colors.white24 : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _contents.length - 1) {
                              _onFinish(ref);
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.accentGold : AppTheme.emeraldGreen,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: Text(
                            _currentPage == _contents.length - 1 ? 'GET STARTED' : 'NEXT',
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
