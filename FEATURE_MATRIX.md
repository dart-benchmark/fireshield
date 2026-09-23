# Feature Matrix — Fire Audit Platform Demo App

| Screen | Widget File | Roles | Feature | Demo Status |
|--------|-------------|-------|---------|-------------|
| Splash Screen | `lib/screens/auth/splash_screen.dart` | All | Animated app intro, auto-navigates to login | Working |
| Login Screen | `lib/screens/auth/login_screen.dart` | All | Email sign-in, role picker sheet, Azure AD button | Working |
| Safety Manager Dashboard | `lib/screens/safety_manager/sm_dashboard.dart` | Safety Manager | Dashboard, Audits, Compliance, Reports, Profile tabs | Working |
| Auditor Dashboard | `lib/screens/auditor/auditor_dashboard.dart` | Auditor | Dashboard, My Audits, Equipment, Profile tabs | Working |
| Admin Dashboard | `lib/screens/admin/admin_dashboard.dart` | Platform Admin | Overview, Orgs, Users, Settings tabs | Working |
| Government Dashboard | `lib/screens/government/govt_dashboard.dart` | Government Officer | Overview, Facilities, Inspections, Analytics tabs | Working |
| Org Admin Dashboard | `lib/screens/org_admin/org_admin_dashboard.dart` | Organisation Admin | Overview, Facilities, Users, Audits, Equipment tabs | Working |
| Audit Execution Screen | `lib/screens/audit_engine/audit_execution_screen.dart` | Auditor, Safety Manager | Checklist sections, YES/NO/PARTIAL/N/A responses, evidence capture | Working |
| Audit Summary Screen | `lib/screens/audit_engine/audit_summary_screen.dart` | Auditor, Safety Manager | Executive Summary, Findings, Scores, Recommendations | Working |
| Corrective Actions Screen | `lib/screens/corrective_actions/ca_screen.dart` | Auditor, Safety Manager, Org Admin | CA list, filters, detail sheet, mark complete | Working |
| Equipment Screen | `lib/screens/equipment/equipment_screen.dart` | All field roles | Registry, search, filter, QR scan, service logging | Working |
| Reports Screen | `lib/screens/reports/reports_screen.dart` | Safety Manager, Auditor, Org Admin | Report archive, generate modal | Working |
| Notifications Screen | `lib/screens/notifications/notifications_screen.dart` | All | Notification list, mark read, type-based icons | Working |
| AI Assistant Screen | `lib/screens/ai_assistant/ai_assistant_screen.dart` | All | Chat interface, regulation Q&A, mock AI responses | Working |
| Document Intelligence Screen | `lib/screens/documents/document_intelligence_screen.dart` | Safety Manager, Org Admin | Upload flow, AI processing animation, gap analysis | Working |
| Register Org Screen | `lib/screens/admin/register_org_screen.dart` | Platform Admin | Multi-step org registration form | Working |
| Create User Screen | `lib/screens/org_admin/create_user_screen.dart` | Org Admin | User creation form with role assignment | Working |
| Admin Orgs Page | `web_portal/app/admin/orgs/page.tsx` | Platform Admin | Web portal orgs list | Partial (web portal) |
| Admin Users Page | `web_portal/app/admin/users/page.tsx` | Platform Admin | Web portal users management | Partial (web portal) |
| Compliance Tab (SM) | Inside `sm_dashboard.dart` | Safety Manager | Standards compliance progress bars, documents | Working |
| Profile Tab | Inside role dashboards | All | User info, menu items, sign out | Working |

**Total Screens: 21** (17 dedicated routes + 4 in-dashboard tabs)
