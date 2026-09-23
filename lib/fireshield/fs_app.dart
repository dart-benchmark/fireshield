/// FireShield app shell and router — Flutter equivalent of
/// pwa_app/src/App.jsx (BrowserRouter + PrivateRoute + phone shell).
///
/// Run this app with:
///   flutter run -t lib/fireshield_main.dart
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'fs_app_state.dart';
import 'screens/fs_add_facility_screen.dart';
import 'screens/fs_admin_dashboard.dart';
import 'screens/fs_auditor_dashboard.dart';
import 'screens/fs_ai_audit_engine_screen.dart';
import 'screens/fs_ai_workspace_screen.dart';
import 'screens/fs_floorplan_screen.dart';
import 'screens/fs_assign_audit_screen.dart';
import 'screens/fs_audit_screens.dart';
import 'screens/fs_building_classification_screen.dart';
import 'screens/fs_create_user_screen.dart';
import 'screens/fs_equipment_inventory_screen.dart';
import 'screens/fs_login_screen.dart';
import 'screens/fs_manager_dashboard.dart';
import 'screens/fs_misc_screens.dart';
import 'screens/fs_govt_dashboard.dart';
import 'screens/fs_noc_readiness_screen.dart';
import 'screens/fs_orgadmin_dashboard.dart';
import 'screens/fs_register_org_screen.dart';
import 'screens/fs_training_drills_screen.dart';
import 'screens/fs_upload_documents_screen.dart';
import 'screens/fs_splash_screen.dart';
import 'screens/fs_tour_screen.dart';
import 'screens/fs_welcome_screen.dart';
import 'theme/fs_tokens.dart';
import 'widgets/fs_bottom_nav.dart';
import 'widgets/fs_ui.dart';

class FireShieldApp extends StatelessWidget {
  const FireShieldApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'FireShield AI™ by EY',
        debugShowCheckedModeBanner: false,
        theme: buildFireShieldTheme(),
        routerConfig: fsRouter,
        builder: (context, child) => FsPhoneShell(child: child!),
      );
}

/// Public routes — everything else requires a signed-in user.
const _publicRoutes = {'/', '/welcome', '/tour', '/login'};

final GoRouter fsRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: FsAppState.instance,
  redirect: (context, state) {
    final path = state.uri.path;
    if (_publicRoutes.contains(path)) return null;
    // PrivateRoute equivalent — bounce to login when unauthenticated.
    return FsAppState.instance.isAuthenticated ? null : '/login';
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const FsSplashScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const FsWelcomeScreen()),
    GoRoute(path: '/tour', builder: (_, __) => const FsTourScreen()),
    GoRoute(path: '/login', builder: (_, __) => const FsLoginScreen()),

    // ── Admin ──
    _page('/admin', 'Admin Dashboard', const FsAdminDashboard(), bare: true),
    _page('/admin/orgs', 'Organisations', const FsAdminDashboard(tab: 'orgs'),
        bare: true),
    _page('/admin/analytics', 'Analytics',
        const FsAdminDashboard(tab: 'analytics'),
        bare: true),
    _page(
        '/admin/activity', 'Activity', const FsAdminDashboard(tab: 'activity'),
        bare: true),
    _page('/admin/register-org', 'Register Organisation',
        const FsRegisterOrgScreen()),
    _page('/admin/classify', 'Building Classification',
        const FsBuildingClassificationScreen()),
    _page('/admin/create-user', 'Create User', const FsCreateUserScreen()),

    // ── Org Admin ──
    _page('/orgadmin', 'Org Admin Dashboard', const FsOrgAdminDashboard(),
        bare: true),
    _page('/orgadmin/facilities', 'Facilities',
        const FsOrgAdminDashboard(tab: 'facilities'),
        bare: true),
    _page('/orgadmin/team', 'Team', const FsOrgAdminDashboard(tab: 'team'),
        bare: true),
    _page(
        '/orgadmin/audits', 'Audits', const FsOrgAdminDashboard(tab: 'audits'),
        bare: true),
    _page(
        '/orgadmin/add-facility', 'Add Facility', const FsAddFacilityScreen()),
    _page('/orgadmin/create-user', 'Create User', const FsCreateUserScreen()),

    // ── Safety Manager ──
    _page('/manager', 'Manager Dashboard', const FsManagerDashboard(),
        bare: true),
    _page('/manager/facilities', 'Facilities', const FsFacilitiesScreen()),
    _page('/manager/audits', 'Audits', const FsManagerDashboard(), bare: true),
    _page('/manager/assign', 'Assign Audit', const FsAssignAuditScreen()),
    _page('/manager/add-facility', 'Add Facility', const FsAddFacilityScreen()),
    _page('/manager/noc', 'NOC Readiness', const FsNocReadinessScreen()),
    _page('/manager/equipment', 'Equipment Inventory',
        const FsEquipmentInventoryScreen()),
    _page('/manager/training', 'Training & Drills',
        const FsTrainingDrillsScreen()),
    _page('/manager/upload-documents', 'Upload Documents',
        const FsUploadDocumentsScreen()),

    // ── Auditor ──
    _page('/auditor', 'Auditor Dashboard', const FsAuditorDashboard(),
        bare: true),
    _page('/auditor/audits', 'My Audits', const FsAuditorDashboard(),
        bare: true),

    // ── Government ──
    _page('/govt', 'Government Dashboard', const FsGovtDashboard(), bare: true),

    // ── Shared ──
    _page('/ai-workspace', 'AI Workspace', const FsAiWorkspaceScreen()),
    _page('/ai-engine', 'AI Audit Engine', const FsAiAuditEngineScreen()),
    _page('/audit', 'Audit Execution', const FsAuditExecution()),
    _page('/audit/summary', 'Audit Summary', const FsAuditSummary()),
    _page('/reports', 'Reports', const FsReportsScreen()),
    _page('/ai', 'AI Assistant', const FsAiAssistant()),
    _page('/floorplan', 'Building Plan Assessment', const FsFloorplanScreen()),
    _page('/reference', 'Reference Library', const FsReferenceLibrary()),
    _page('/profile', 'Profile', const FsProfileScreen()),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: FsColors.bg,
    body: EmptyState(
      icon: '🧭',
      title: 'Page not found',
      subtitle: state.uri.path,
    ),
  ),
);

/// Every authenticated route renders inside the same chrome: TopBar +
/// content + role bottom nav.
///
/// [bare] omits the TopBar for screens that draw their own gradient header.
GoRoute _page(String path, String title, Widget child, {bool bare = false}) =>
    GoRoute(
      path: path,
      builder: (context, state) => FsScaffold(
        title: title,
        location: path,
        bare: bare,
        child: child,
      ),
    );

/// Standard authenticated page chrome.
class FsScaffold extends StatelessWidget {
  final String title;
  final String location;
  final Widget child;
  final String? subtitle;
  final Widget? floatingAction;

  /// Screens with their own gradient header skip the TopBar.
  final bool bare;

  const FsScaffold({
    super.key,
    required this.title,
    required this.location,
    required this.child,
    this.subtitle,
    this.floatingAction,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FsAppState.instance.user;
    return Scaffold(
      backgroundColor: FsColors.bg,
      appBar: bare
          ? null
          : TopBar(
              title: title,
              subtitle: subtitle ?? user?.facility,
              right: user == null
                  ? null
                  : Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FsColors.primary,
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                      ),
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
      body: child,
      floatingActionButton: floatingAction,
      bottomNavigationBar: user == null
          ? null
          : FsBottomNav(role: user.role, location: location),
    );
  }
}

/// Placeholder for routes whose screens are not ported yet.
///
/// It states plainly which PWA source file the Flutter version should come
/// from, so the remaining work is unambiguous rather than looking finished.
class FsPendingScreen extends StatelessWidget {
  final String title;
  final String path;

  const FsPendingScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FsColors.warningLight,
                        borderRadius: BorderRadius.circular(FsRadius.xl),
                      ),
                      child: const Text('🚧', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: FsText.title),
                          Text('Route $path', style: FsText.small),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: FsColors.border),
                const SizedBox(height: 12),
                Text(
                  'Screen not ported yet. The routing, role guard, navigation '
                  'chrome and data layer for this page are in place — only the '
                  'page body is outstanding.',
                  style: FsText.small.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      );
}

/// Reproduces `.phone-shell` from index.css: a 393x852 frame on wide
/// viewports, full-bleed at 430px and below.
///
/// This is a WEB PREVIEW AID ONLY. On Android and iOS it always renders the
/// child full-bleed — otherwise a tablet or unfolded foldable would show a
/// fake phone frame inside a real app.
class FsPhoneShell extends StatelessWidget {
  final Widget child;
  const FsPhoneShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final width = MediaQuery.of(context).size.width;
    if (width <= 430) return child;

    return ColoredBox(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FsRadius.xl2),
          child: SizedBox(
            width: 393,
            height: 852,
            child: MediaQuery(
              // Inside the frame the app should believe it is on a phone.
              data: MediaQuery.of(context).copyWith(
                size: const Size(393, 852),
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
