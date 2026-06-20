import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/app_theme.dart';

class BiometricLockScreen extends StatefulWidget {
  /// True when reached from the splash screen on cold start (no real screen
  /// underneath, so success/give-up should replace the whole stack). False
  /// when pushed on top of an in-progress session after the app resumes
  /// from the background — in that case success should just reveal the
  /// screen underneath, and the lock must not be back-button dismissible.
  final bool isInitialLaunch;

  const BiometricLockScreen({super.key, this.isInitialLaunch = true});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    setState(() { _authenticating = true; _errorMessage = null; });
    final success = await BiometricService.authenticate();
    if (!mounted) return;
    if (success) {
      if (widget.isInitialLaunch) {
        context.go('/dashboard');
      } else {
        Navigator.of(context).pop();
      }
    } else {
      setState(() { _authenticating = false; _errorMessage = 'Authentication failed. Try again.'; });
    }
  }

  Future<void> _signInWithPassword() async {
    // The biometric check failed/was skipped — the existing Supabase session
    // must not remain valid, otherwise backing out of the login screen (or
    // any deep link) would reach the dashboard without ever proving identity.
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      // Only the initial-launch lock is the root of the stack (back exits the
      // app, which is fine). A resume-triggered lock sits on top of a real
      // screen, so it must not be dismissible without authenticating.
      canPop: widget.isInitialLaunch,
      child: Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/worqly_logo.svg', width: 100, height: 100),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 64,
                    color: _authenticating ? AppTheme.emeraldGreen : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _authenticating ? 'Authenticating...' : 'Touch to unlock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _authenticating ? AppTheme.emeraldGreen : AppTheme.darkBlue,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                ],
                const SizedBox(height: 40),
                if (!_authenticating) ...[
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _signInWithPassword,
                    child: const Text('Sign in with password', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
