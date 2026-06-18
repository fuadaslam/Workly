import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/services/biometric_service.dart';
import 'biometric_lock_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Wait for onboarding status to load if needed
    bool? showOnboarding = ref.read(onboardingProvider);
    while (showOnboarding == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      showOnboarding = ref.read(onboardingProvider);
    }

    final session = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;

    if (showOnboarding) {
      context.go('/onboarding');
    } else if (session != null) {
      // Check if biometric is enabled — show lock screen before dashboard
      final biometricEnabled = !kIsWeb && await BiometricService.isEnabled();
      final biometricAvailable = !kIsWeb && await BiometricService.isAvailable();
      if (!mounted) return;
      if (biometricEnabled && biometricAvailable) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BiometricLockScreen()),
        );
      } else {
        context.go('/dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/worqly_logo.svg',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 24),
              const Text(
                'Workly',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Excellence in Every Service',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
