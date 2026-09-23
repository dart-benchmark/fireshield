import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/safety_manager/sm_dashboard.dart';
import 'screens/auditor/auditor_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/government/govt_dashboard.dart';
import 'data/mock_data.dart';
import 'screens/audit_engine/audit_execution_screen.dart';
import 'screens/equipment/equipment_screen.dart';
import 'screens/corrective_actions/ca_screen.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/admin/register_org_screen.dart';
import 'screens/org_admin/org_admin_dashboard.dart';
import 'screens/org_admin/create_user_screen.dart';
import 'screens/audit_engine/audit_summary_screen.dart';
import 'screens/documents/document_intelligence_screen.dart';
import 'screens/classification/building_classification_screen.dart';
import 'screens/audit_engine/nbc_checklist_screen.dart';
import 'screens/risk/risk_dashboard_screen.dart';
import 'screens/capa/capa_tracker_screen.dart';
import 'screens/welcome/welcome_screen.dart';

void main() {
  runApp(const FireAuditDemoApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/safety-manager', builder: (_, __) => SafetyManagerDashboard(user: demoUsers[0])),
    GoRoute(path: '/auditor', builder: (_, __) => const AuditorDashboard()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
    GoRoute(path: '/government', builder: (_, __) => GovernmentDashboard(user: demoUsers[2])),
    GoRoute(path: '/audit-execution', builder: (_, __) => const AuditExecutionScreen()),
    GoRoute(path: '/equipment', builder: (_, __) => const EquipmentScreen()),
    GoRoute(path: '/corrective-actions', builder: (_, __) => const CorrectiveActionsScreen()),
    GoRoute(path: '/ai-assistant', builder: (_, __) => const AiAssistantScreen()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/register-org', builder: (_, __) => const RegisterOrgScreen()),
    GoRoute(path: '/org-admin', builder: (_, __) => const OrgAdminDashboard()),
    GoRoute(path: '/create-user', builder: (_, __) => const CreateUserScreen()),
    GoRoute(path: '/audit-summary', builder: (_, state) => AuditSummaryScreen(audit: (state.extra as MockAudit?) ?? mockAudits[0])),
    GoRoute(path: '/doc-intelligence', builder: (_, __) => const DocumentIntelligenceScreen()),

    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),

    // NBC/BIS audit flow: classify → checklist → risk → CAPA
    GoRoute(path: '/building-classification', builder: (_, __) => const BuildingClassificationScreen()),
    GoRoute(path: '/nbc-checklist', builder: (_, __) => const NbcChecklistScreen()),
    GoRoute(path: '/risk-dashboard', builder: (_, __) => const RiskDashboardScreen()),
    GoRoute(path: '/capa-tracker', builder: (_, __) => const CapaTrackerScreen()),
  ],
);

class FireAuditDemoApp extends StatelessWidget {
  const FireAuditDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Self Fire Audit Platform — Demo',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    routerConfig: _router,
    builder: (context, child) => _MobileFrame(child: child!),
  );
}

// Wraps the app in a phone frame when viewed on desktop/web
class _MobileFrame extends StatelessWidget {
  final Widget child;
  const _MobileFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // On narrow screens (actual phone), just show normally
    if (screenWidth <= 430) return child;

    // On wide screens, show as phone frame centered
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Container(
          width: 393,
          height: 852,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 60, spreadRadius: 10),
              BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 1, spreadRadius: 1),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: Stack(
              children: [
                child,
                // Status bar notch overlay
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 24, top: 12),
                          child: Text('9:41', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                        // Dynamic island
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: 120, height: 32,
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 20, top: 12),
                          child: Row(children: [
                            Icon(Icons.signal_cellular_alt, size: 14, color: Colors.black87),
                            SizedBox(width: 4),
                            Icon(Icons.wifi, size: 14, color: Colors.black87),
                            SizedBox(width: 4),
                            Icon(Icons.battery_full, size: 14, color: Colors.black87),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
