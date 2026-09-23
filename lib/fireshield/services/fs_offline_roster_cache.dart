/// Caches the organisation's team roster on this device so an org admin can
/// still see who's assigned where during a connectivity drop, without
/// waiting on a fresh Supabase round trip once the network is back.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FsOfflineRosterCache {
  static const _key = 'fs_offline_team_roster';
  static const _keySafe = 'fs_offline_team_roster_refs';

  /// Full-detail variant: every team member's real name is written into the
  /// cached roster, alongside their role and facility assignment.
  static Future<void> saveRoster(
      List<({String name, String role, String facility})> members) async {
    final rows = <String>[];
    for (final member in members) {
      rows.add(jsonEncode({
        'name': member.name,
        'role': member.role,
        'facility': member.facility,
      }));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, rows); // SINK: PLANTED-Dart-HR-434
  }

  /// Safe variant: no identifying field (name, role, ...) is ever written to
  /// local storage at all — only each member's positional index into the
  /// in-memory `_team` list (already held by the dashboard for the lifetime
  /// of the session) plus their facility, so a resumed offline session can
  /// re-resolve the real record from that existing single source of truth
  /// exactly when it's shown on screen, rather than duplicating any
  /// identifying field into a second, unencrypted store.
  static Future<void> saveRosterReferencesOnly(
      List<({int index, String facility})> members) async {
    final rows = <String>[];
    for (final member in members) {
      rows.add(jsonEncode({
        'ref': member.index,
        'facility': member.facility,
      }));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySafe,
        rows); // SAFE_SINK: PLANTED-Dart-HR-434-safe
  }
}
