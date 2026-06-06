import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/citizen_dashboard.dart';
import '../../screens/dashboard/officer_dashboard.dart';
import '../../screens/land/land_registration_screen.dart';
import '../../screens/land/land_detail_screen.dart';
import '../../screens/land/land_verification_screen.dart';
import '../../screens/land/land_transfer_screen.dart';
import '../../screens/map/gis_map_screen.dart';
import '../../screens/documents/document_upload_screen.dart';
import '../../screens/documents/document_viewer_screen.dart';
import '../../screens/tracking/application_tracking_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/chatbot/chatbot_screen.dart';
import '../../screens/audit/audit_log_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/notifications/notifications_screen.dart';

// Route paths
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const citizenDashboard = '/dashboard/citizen';
  static const officerDashboard = '/dashboard/officer';
  static const landRegistration = '/land/register';
  static const landDetail = '/land/detail/:id';
  static const landVerification = '/land/verify';
  static const landTransfer = '/land/transfer/:id';
  static const gisMap = '/map';
  static const documentUpload = '/documents/upload/:landId';
  static const documentViewer = '/documents/view';
  static const applicationTracking = '/tracking';
  static const search = '/search';
  static const chatbot = '/chatbot';
  static const auditLog = '/audit';
  static const profile = '/profile';
  static const notifications = '/notifications';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAuthRoute = state.fullPath == AppRoutes.login ||
          state.fullPath == AppRoutes.register ||
          state.fullPath == AppRoutes.splash;

      // If not logged in and not on auth route, go to login
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If logged in and on auth route (except splash), go to dashboard
      if (isLoggedIn && isAuthRoute && state.fullPath != AppRoutes.splash) {
        final user = authState.user;
        if (user?.role == UserRole.citizen) {
          return AppRoutes.citizenDashboard;
        } else {
          return AppRoutes.officerDashboard;
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.citizenDashboard,
        builder: (context, state) => const CitizenDashboard(),
      ),
      GoRoute(
        path: AppRoutes.officerDashboard,
        builder: (context, state) => const OfficerDashboard(),
      ),
      GoRoute(
        path: AppRoutes.landRegistration,
        builder: (context, state) => const LandRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.landDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LandDetailScreen(landId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.landVerification,
        builder: (context, state) => const LandVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.landTransfer,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LandTransferScreen(landId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.gisMap,
        builder: (context, state) => const GisMapScreen(),
      ),
      GoRoute(
        path: AppRoutes.documentUpload,
        builder: (context, state) {
          final landId = state.pathParameters['landId'] ?? '';
          return DocumentUploadScreen(landId: landId);
        },
      ),
      GoRoute(
        path: AppRoutes.documentViewer,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DocumentViewerScreen(
            url: extra['url'] as String? ?? '',
            title: extra['title'] as String? ?? 'Document',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.applicationTracking,
        builder: (context, state) => const ApplicationTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: AppRoutes.auditLog,
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});