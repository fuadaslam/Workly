import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_manager_app/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:service_manager_app/features/auth/presentation/providers/profile_provider.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'package:service_manager_app/core/widgets/responsive_layout.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        ref.invalidate(profileProvider);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email address first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  // ── Background gradient ──────────────────────────────────────────
  LinearGradient _bgGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(
        colors: [Color(0xFF0B172A), Color(0xFF0F2038), Color(0xFF0F1520)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.55, 1.0],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFEEF2F8), Color(0xFFE3EDFB), Color(0xFFF0F4F8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [0.0, 0.5, 1.0],
    );
  }

  // ── Decorative blobs ─────────────────────────────────────────────
  Widget _blobs(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -90, right: -70,
          child: _blob(
            300,
            isDark
                ? AppTheme.navyDeep.withValues(alpha: 0.6)
                : AppTheme.emeraldGreen.withValues(alpha: 0.07),
          ),
        ),
        Positioned(
          bottom: -100, left: -80,
          child: _blob(
            320,
            isDark
                ? AppTheme.accentGold.withValues(alpha: 0.08)
                : AppTheme.accentGold.withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          top: 200, left: -50,
          child: _blob(
            180,
            isDark
                ? AppTheme.statBlue.withValues(alpha: 0.12)
                : AppTheme.statBlue.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          bottom: 180, right: -30,
          child: _blob(
            140,
            isDark
                ? AppTheme.statPurple.withValues(alpha: 0.1)
                : AppTheme.statPurple.withValues(alpha: 0.04),
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ── Glass form card ───────────────────────────────────────────────
  Widget _glassFormCard(BuildContext context, bool isDark) {
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.80);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.92);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 48,
                      offset: const Offset(0, 24),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 48,
                      offset: const Offset(0, 24),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: _formContent(context, isDark),
        ),
      ),
    );
  }

  Widget _formContent(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final inputFill = isDark ? const Color(0xFF1E2A3C) : Colors.white;
    final inputBorder = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final inputFocusBorder = isDark ? AppTheme.accentGold : AppTheme.emeraldGreen;
    final labelColor = isDark ? AppTheme.accentGold : AppTheme.emeraldGreen;
    final iconColor  = isDark ? AppTheme.accentGold : AppTheme.emeraldGreen;
    final textColor  = isDark ? AppTheme.darkOnSurface : AppTheme.darkBlue;
    final subtextColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500;
    final btnBg  = isDark ? AppTheme.accentGold : AppTheme.emeraldGreen;
    final btnFg  = isDark ? Colors.black        : Colors.white;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Center(
            child: SvgPicture.asset(
              'assets/images/worqly_logo.svg',
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(height: 28),

          // Title
          Text(
            l10n.welcomeBack,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to your Workly account',
            style: TextStyle(color: subtextColor, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: l10n.email,
              labelStyle: TextStyle(color: labelColor.withValues(alpha: 0.8)),
              prefixIcon: Icon(Icons.email_outlined, color: iconColor),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputFocusBorder, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.errorRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.errorRed),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _signIn(),
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: l10n.password,
              labelStyle: TextStyle(color: labelColor.withValues(alpha: 0.8)),
              prefixIcon: Icon(Icons.lock_outlined, color: iconColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: subtextColor,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: inputFocusBorder, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.errorRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.errorRed),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppTheme.accentGold : AppTheme.emeraldGreen,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 20),

          // Sign In button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnBg,
                foregroundColor: btnFg,
                disabledBackgroundColor: Colors.grey.shade400,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: btnFg,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      l10n.signIn,
                      style: TextStyle(
                        color: btnFg,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),

          // Contact admin note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.accentGold.withValues(alpha: 0.08)
                  : AppTheme.emeraldGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppTheme.accentGold.withValues(alpha: 0.2)
                    : AppTheme.emeraldGreen.withValues(alpha: 0.15),
              ),
            ),
            child: Row(children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? AppTheme.accentGold : AppTheme.emeraldGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No account? Contact your system administrator to get access.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // Powered by
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Powered by ',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Image.asset(
                'assets/images/Xoviq Logo.jpeg',
                height: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _bgGradient(isDark)),
        child: Stack(
          children: [
            _blobs(isDark),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Center(
                  child: ResponsiveLayout(
                    maxWidth: 420,
                    padding: EdgeInsets.zero,
                    child: _glassFormCard(context, isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
