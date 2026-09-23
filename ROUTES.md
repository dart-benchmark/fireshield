# Route Map — Fire Audit Platform Demo App

All routes are defined in `lib/main.dart` using GoRouter.

| Route Path | Screen | Widget File | Accessible By |
|------------|--------|-------------|---------------|
| `/` | SplashScreen | `lib/screens/auth/splash_screen.dart` | All (auto-redirect) |
| `/login` | LoginScreen | `lib/screens/auth/login_screen.dart` | All |
| `/safety-manager` | SafetyManagerDashboard | `lib/screens/safety_manager/sm_dashboard.dart` | Safety Manager |
| `/auditor` | AuditorDashboard | `lib/screens/auditor/auditor_dashboard.dart` | Auditor |
| `/admin` | AdminDashboard | `lib/screens/admin/admin_dashboard.dart` | Platform Admin |
| `/government` | GovernmentDashboard | `lib/screens/government/govt_dashboard.dart` | Government Officer |
| `/org-admin` | OrgAdminDashboard | `lib/screens/org_admin/org_admin_dashboard.dart` | Organisation Admin |
| `/audit-execution` | AuditExecutionScreen | `lib/screens/audit_engine/audit_execution_screen.dart` | Auditor, Safety Manager |
| `/audit-summary` | AuditSummaryScreen | `lib/screens/audit_engine/audit_summary_screen.dart` | Auditor, Safety Manager |
| `/corrective-actions` | CorrectiveActionsScreen | `lib/screens/corrective_actions/ca_screen.dart` | Auditor, Safety Manager, Org Admin |
| `/equipment` | EquipmentScreen | `lib/screens/equipment/equipment_screen.dart` | Auditor, Safety Manager, Org Admin |
| `/reports` | ReportsScreen | `lib/screens/reports/reports_screen.dart` | Safety Manager, Auditor, Org Admin |
| `/notifications` | NotificationsScreen | `lib/screens/notifications/notifications_screen.dart` | All |
| `/ai-assistant` | AiAssistantScreen | `lib/screens/ai_assistant/ai_assistant_screen.dart` | All |
| `/doc-intelligence` | DocumentIntelligenceScreen | `lib/screens/documents/document_intelligence_screen.dart` | Safety Manager, Org Admin |
| `/register-org` | RegisterOrgScreen | `lib/screens/admin/register_org_screen.dart` | Platform Admin |
| `/create-user` | CreateUserScreen | `lib/screens/org_admin/create_user_screen.dart` | Org Admin |

## Navigation Notes

- GoRouter is configured in `lib/main.dart` with `_router` (GoRouter instance).
- All dashboards pass a `MockUser` via `extra` parameter from the login screen.
- `SafetyManagerDashboard` and `GovernmentDashboard` receive a `user` parameter; other dashboards use `demoUsers` directly from mock data.
- Navigation between screens uses `context.push()` (stack push) or `context.go()` (replace stack, used for sign-out to `/login`).
