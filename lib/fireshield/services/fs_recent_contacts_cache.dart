/// Keeps a small "recently added facility contacts" list on this device, so
/// a safety manager who just finished the Add Facility wizard can call or
/// email the facility's own contact person again without re-opening the full
/// facility record over the network.
///
/// Deliberately a convenience cache only — Supabase's `facilities` table
/// (via [FsPersistenceService]) stays the single source of truth; nothing
/// here is ever read back to populate the real facility record.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FsRecentContactsCache {
  static const _key = 'fs_recent_facility_contacts';
  static const _keySafe = 'fs_recent_facility_contact_ids';

  /// Full-detail variant: the facility contact's name, phone and email are
  /// cached verbatim so the manager can reach them without a round trip.
  static Future<void> remember({
    required String facilityName,
    required String name,
    required String phone,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key) ?? <String>[];
    final entry = jsonEncode({
      'facility': facilityName,
      'name': name,
      'phone': phone,
      'email': email,
    });
    existing.insert(0, entry);
    await prefs.setStringList(
        _key, existing.take(10).toList()); // SINK: PLANTED-Dart-HR-432
  }

  /// Safe variant: only the facility's own name is cached, never the
  /// contact person's identifying fields — the actual contact details are
  /// re-resolved from Supabase (the existing single source of truth) exactly
  /// when the manager taps through to the full facility record.
  static Future<void> rememberFacilityOnly({
    required String facilityName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_keySafe) ?? <String>[];
    existing.insert(0, facilityName);
    await prefs.setStringList(_keySafe,
        existing.take(10).toList()); // SAFE_SINK: PLANTED-Dart-HR-432-safe
  }
}
