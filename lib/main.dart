import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:service_manager_app/l10n/generated/app_localizations.dart';
import 'core/constants/supabase_env.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/widgets/offline_banner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/services/notification_service.dart';
import 'core/services/biometric_service.dart';
import 'core/router/app_router.dart';
import 'features/onboarding/presentation/pages/biometric_lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (SupabaseEnv.url != 'YOUR_SUPABASE_URL') {
      await Supabase.initialize(
        url: SupabaseEnv.url,
        anonKey: SupabaseEnv.anonKey,
      );
    }
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  if (!kIsWeb) {
    await NotificationService.init();
    await NotificationService.requestPermission();
  }

  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _wasBackgrounded = false;
  bool _lockScreenShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _wasBackgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      _maybeShowLockScreen();
    }
  }

  Future<void> _maybeShowLockScreen() async {
    if (_lockScreenShowing) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    final enabled = await BiometricService.isEnabled();
    final available = await BiometricService.isAvailable();
    if (!enabled || !available) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    _lockScreenShowing = true;
    await navigator.push(
      MaterialPageRoute(builder: (_) => const BiometricLockScreen(isInitialLaunch: false)),
    );
    _lockScreenShowing = false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      title: 'Workly',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => OfflineBanner(child: child!),
    );
  }
}
