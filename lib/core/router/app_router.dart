import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/onboarding/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/dashboard/presentation/pages/task_detail_screen.dart';
import '../../features/dashboard/presentation/pages/admin_detail_screen.dart';
import '../../features/dashboard/presentation/pages/office_detail_screen.dart';
import '../../features/dashboard/presentation/pages/client_detail_screen.dart';
import '../../features/dashboard/presentation/pages/system_detail_screen.dart';
import '../../features/dashboard/presentation/pages/detail_trend_screen.dart';
import '../../features/dashboard/presentation/pages/active_cases_screen.dart';
import '../../features/dashboard/presentation/pages/revenue_detail_screen.dart';
import '../../features/auth/presentation/pages/edit_profile_screen.dart';
import '../../features/auth/presentation/pages/change_password_screen.dart';
import '../../features/auth/domain/models/profile.dart' as model;
import '../../features/enquiries/presentation/pages/enquiry_summary_screen.dart';
import '../../features/enquiries/presentation/pages/add_enquiry_screen.dart';
import '../../features/enquiries/presentation/pages/enquiry_detail_screen.dart';
import '../../features/enquiries/domain/models/enquiry.dart';
import '../../features/reports/presentation/report_export_screen.dart';
import '../../features/saas/presentation/pages/organization_detail_screen.dart';
import '../../features/saas/domain/models/organization.dart';
import '../../features/search/presentation/global_search_screen.dart';

/// Lets every screen in the app — including ones nested deep inside the
/// dashboard — drive navigation through go_router instead of raw
/// Navigator.push, so the `redirect` guard below actually applies to all
/// of them, not just the top-level auth screens.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Re-runs the router's redirect whenever Supabase auth state changes, so
/// e.g. a sign-out or expired session is caught on the next navigation
/// rather than only at the next app cold start.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
}

/// Bundles for routes whose destination screen needs more than a primitive
/// path/query param. These travel via [GoRouterState.extra] (in-memory,
/// not URL-encoded) — consistent with the rest of the app, where these
/// screens are only ever reached by tapping into an already-loaded list,
/// never by a user typing/bookmarking the URL directly.
class TaskRouteArgs {
  final String clientName;
  final String? clientPhone;
  final String priority;
  final String initialStatus;
  const TaskRouteArgs({
    required this.clientName,
    this.clientPhone,
    required this.priority,
    this.initialStatus = 'Pending',
  });
}

class ClientRouteArgs {
  final String clientName;
  final String? clientPhone;
  const ClientRouteArgs({required this.clientName, this.clientPhone});
}

class SystemDetailRouteArgs {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? status;
  final bool? isHealthy;
  const SystemDetailRouteArgs({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.status,
    this.isHealthy,
  });
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: _AuthRefreshNotifier(),
  redirect: (context, state) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    final goingTo = state.matchedLocation;

    // startsWith, not ==, so every nested /dashboard/... screen inherits
    // the same auth guard as the bare /dashboard route.
    if (goingTo.startsWith('/dashboard') && !hasSession) return '/login';
    if (goingTo == '/login' && hasSession) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(
          path: 'task/:taskId',
          builder: (context, state) {
            final taskId = state.pathParameters['taskId']!;
            final extra = state.extra as TaskRouteArgs?;
            return TaskDetailScreen(
              taskId: taskId,
              clientName: extra?.clientName ?? '—',
              clientPhone: extra?.clientPhone,
              priority: extra?.priority ?? 'Medium',
              initialStatus: extra?.initialStatus ?? 'Pending',
            );
          },
        ),
        GoRoute(
          path: 'admin-detail',
          builder: (context, state) => AdminDetailScreen(admin: state.extra as Map<String, dynamic>),
        ),
        GoRoute(
          path: 'office-detail',
          builder: (context, state) => OfficeDetailScreen(office: state.extra as Map<String, dynamic>),
        ),
        GoRoute(
          path: 'client-detail',
          builder: (context, state) {
            final extra = state.extra as ClientRouteArgs;
            return ClientDetailScreen(clientName: extra.clientName, clientPhone: extra.clientPhone);
          },
        ),
        GoRoute(
          path: 'edit-profile',
          builder: (context, state) => EditProfileScreen(profile: state.extra as model.Profile),
        ),
        GoRoute(path: 'change-password', builder: (context, state) => const ChangePasswordScreen()),
        GoRoute(path: 'trend', builder: (context, state) => const DetailTrendScreen()),
        GoRoute(path: 'active-cases', builder: (context, state) => const ActiveCasesScreen()),
        GoRoute(path: 'revenue', builder: (context, state) => const RevenueDetailScreen()),
        GoRoute(
          path: 'system-detail',
          builder: (context, state) {
            final extra = state.extra as SystemDetailRouteArgs;
            return SystemDetailScreen(
              title: extra.title,
              subtitle: extra.subtitle,
              icon: extra.icon,
              status: extra.status,
              isHealthy: extra.isHealthy,
            );
          },
        ),
        GoRoute(path: 'enquiries/summary', builder: (context, state) => const EnquirySummaryScreen()),
        GoRoute(path: 'enquiries/add', builder: (context, state) => const AddEnquiryScreen()),
        GoRoute(
          path: 'enquiries/detail',
          builder: (context, state) => EnquiryDetailScreen(enquiry: state.extra as Enquiry),
        ),
        GoRoute(path: 'reports/export', builder: (context, state) => const ReportExportScreen()),
        GoRoute(
          path: 'org-detail',
          builder: (context, state) => OrganizationDetailScreen(org: state.extra as Organization),
        ),
        GoRoute(path: 'search', builder: (context, state) => const GlobalSearchScreen()),
      ],
    ),
  ],
);
