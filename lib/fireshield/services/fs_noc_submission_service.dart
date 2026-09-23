/// FireShield NOC-submission / enforcement / certificate gateway client.
///
/// ENGINEERED-HOST NOTE (planted-vulnerability benchmark project): FireShield
/// has no organic hard-coded-credential host on its own — the Groq key stays
/// server-side (fs_groq_service.dart never even holds it) and the Supabase
/// key in fs_config.dart is a genuine public "publishable" key protected by
/// Row Level Security, not a secret. This service was added purely to give
/// the CWE-798 in-browser benchmark corpus a realistic host in this project;
/// see benchmarking/dart/planting-research/dart-cwe-798-inbrowser-planting-research.md.
///
/// Every "local" method below signs or authenticates a call to an external
/// system entirely in the browser, using a value compiled into the client
/// bundle. Every "verified"/"withToken" sibling method is the fix: it either
/// asks the Worker gateway to mint the value server-side (the shared secret
/// then never leaves the server), or refuses to run until an operator
/// supplies the credential at runtime.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fs_config.dart';

class FsNocSubmissionException implements Exception {
  final String message;
  const FsNocSubmissionException(this.message);
  @override
  String toString() => 'FsNocSubmissionException: $message';
}

class FsNocSubmissionService {
  FsNocSubmissionService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  String _signLocally(String secret, Map<String, dynamic> payload) {
    final mac = Hmac(sha256, utf8.encode(secret));
    return mac.convert(utf8.encode(jsonEncode(payload))).toString();
  }

  Map<String, String> _authHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (isSupabaseConfigured) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Asks the Worker gateway to mint a signature for [payload] server-side.
  /// The shared signing secret lives only on the Worker (`NOC_INTEGRATIONS_
  /// SECRET`, read via the Secrets Store) and never reaches the browser.
  Future<String> requestVerifiedSignature(
    String kind,
    Map<String, dynamic> payload,
  ) async {
    if (!isWorkerConfigured) {
      throw const FsNocSubmissionException(
          'Verified signing is not configured — set FIRESHIELD_WORKER_URL.');
    }
    final response = await _client
        .post(
          Uri.parse('$workerBaseUrl/noc/sign'),
          headers: _authHeaders(),
          body: jsonEncode({'kind': kind, 'payload': payload}),
        )
        .timeout(const Duration(seconds: 20));
    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode >= 400 || decoded == null || decoded['error'] != null) {
      throw FsNocSubmissionException(
          decoded?['error']?.toString() ?? 'Verified signing failed.');
    }
    return decoded['signature'].toString();
  }

  // ── NOC submission (AI Audit Engine, Phase 8) ─────────────────────────

  // SINK: PLANTED-Dart-HR-395
  // Shared secret the State Fire NOC portal treats as proof a submission
  // came from a genuine FireShield deployment. Signing locally means the
  // same secret ships in every visitor's bundle — anyone who extracts it can
  // forge a valid submission signature for ANY facility, not just their own.
  static const String _nocWebhookSigningSecret =
      'noc_whsec_8f2Kx91mTqL5vRn3Zc7Yd0Ab4Ep6Ws2Hj9Qi';

  Map<String, dynamic> _submissionPayload({
    required String facilityId,
    required String buildingType,
    required double score,
    required int openCriticals,
  }) =>
      {
        'facilityId': facilityId,
        'buildingType': buildingType,
        'score': score,
        'openCriticals': openCriticals,
        'submittedAt': DateTime.now().toUtc().toIso8601String(),
      };

  Future<String> _postSubmission(
      Map<String, dynamic> payload, String signature) async {
    final response = await _client
        .post(
          Uri.parse(
              'https://noc-submissions.karnatakafire.gov.in/api/v2/intake'),
          headers: {
            'Content-Type': 'application/json',
            'X-Fireshield-Signature': signature,
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 400) {
      throw FsNocSubmissionException(
          'NOC portal rejected the submission (${response.statusCode}).');
    }
    return signature;
  }

  /// Signs and submits the audit result to the State Fire NOC portal.
  ///
  /// VULNERABLE: the signature is computed in-browser with a secret compiled
  /// into every visitor's bundle — see [_nocWebhookSigningSecret].
  Future<String> submitForNocApproval({
    required String facilityId,
    required String buildingType,
    required double score,
    required int openCriticals,
  }) async {
    final payload = _submissionPayload(
      facilityId: facilityId,
      buildingType: buildingType,
      score: score,
      openCriticals: openCriticals,
    );
    final signature = _signLocally(_nocWebhookSigningSecret, payload);
    return _postSubmission(payload, signature);
  }

  // SAFE_SINK: PLANTED-Dart-HR-395-safe
  /// Same submission, but the signature is minted by the Worker gateway —
  /// the shared secret never reaches this client.
  Future<String> submitViaVerifiedGateway({
    required String facilityId,
    required String buildingType,
    required double score,
    required int openCriticals,
  }) async {
    final payload = _submissionPayload(
      facilityId: facilityId,
      buildingType: buildingType,
      score: score,
      openCriticals: openCriticals,
    );
    final signature = await requestVerifiedSignature('submission', payload);
    return _postSubmission(payload, signature);
  }

  // ── Escalation (Government dashboard "Escalate" action) ───────────────

  // SINK: PLANTED-Dart-HR-396
  // Split across three literal fragments and concatenated at call time. This
  // is cosmetic, not a sanitizer — the whole secret still ends up verbatim
  // in the compiled bundle the moment any of these fields is referenced.
  static const String _escalationSecretFragmentA = 'esc_k9F2mQ7x';
  static const String _escalationSecretFragmentB = 'Rt3ZsP0Jc5';
  static const String _escalationSecretFragmentC = 'Wn8LhY4Dq1';

  String _buildEscalationAuthHeader(String findingRef) {
    var secret = '';
    secret += _escalationSecretFragmentA;
    secret += _escalationSecretFragmentB;
    secret += _escalationSecretFragmentC;
    var header = secret;
    header += ':';
    header += findingRef;
    return base64Encode(utf8.encode(header));
  }

  Future<void> _postEscalation(String building, String findingRef, String auth) async {
    final response = await _client
        .post(
          Uri.parse('https://enforcement.ksfes.gov.in/api/escalations'),
          headers: {
            'Content-Type': 'application/json',
            'X-Enforcement-Auth': auth,
          },
          body: jsonEncode({'building': building, 'findingRef': findingRef}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 400) {
      throw FsNocSubmissionException(
          'Enforcement system rejected the escalation (${response.statusCode}).');
    }
  }

  /// Escalates a finding to the department's internal enforcement-tracking
  /// system.
  ///
  /// VULNERABLE: the shared auth header is assembled from three literal
  /// fragments compiled into every visitor's bundle — see
  /// `_escalationSecretFragment*` above.
  Future<void> escalateFindingToEnforcement({
    required String building,
    required String findingRef,
  }) async {
    final auth = _buildEscalationAuthHeader(findingRef);
    await _postEscalation(building, findingRef, auth);
  }

  // SAFE_SINK: PLANTED-Dart-HR-396-safe
  Future<void> escalateFindingViaVerifiedGateway({
    required String building,
    required String findingRef,
  }) async {
    final auth = await requestVerifiedSignature(
        'escalation', {'building': building, 'findingRef': findingRef});
    await _postEscalation(building, findingRef, auth);
  }

  // ── Vendor AMC renewal notification (NOC Readiness screen) ────────────

  // SINK: PLANTED-Dart-HR-397
  // Cached the first time a renewal push is needed so the demo doesn't
  // reconstruct it on every call within the same session.
  static String? _cachedVendorCrmToken;

  String _vendorCrmToken() =>
      _cachedVendorCrmToken ??= 'crm_pat_Gx7mQ2Lp9VtY4hR6nZ8sW1cD3fJk0Ub5A';

  Future<void> _getVendorRenewal(String token, String system, String vendor) async {
    final uri = Uri.https(
      'vendor-crm.example-fireservices.com',
      '/api/v1/renewal-requests',
      {'token': token, 'system': system, 'vendor': vendor},
    );
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode >= 400) {
      throw FsNocSubmissionException(
          'Vendor CRM rejected the renewal request (${response.statusCode}).');
    }
  }

  /// Pushes a renewal request to the facilities-CRM vendor portal for an
  /// expired AMC contract.
  ///
  /// VULNERABLE: the partner API token is a literal compiled into every
  /// visitor's bundle — see [_cachedVendorCrmToken].
  Future<void> notifyVendorForRenewal({
    required String system,
    required String vendor,
  }) =>
      _getVendorRenewal(_vendorCrmToken(), system, vendor);

  // SAFE_SINK: PLANTED-Dart-HR-397-safe
  /// Same renewal push, but no partner token is bundled at all — an org
  /// admin must supply one at runtime (kept in memory for this session
  /// only) and the feature refuses to run without it.
  Future<void> notifyVendorForRenewalWithToken({
    required String system,
    required String vendor,
    required String adminSuppliedToken,
  }) {
    if (adminSuppliedToken.trim().isEmpty) {
      throw const FsNocSubmissionException(
          'Vendor integration is not configured for this organisation.');
    }
    return _getVendorRenewal(adminSuppliedToken.trim(), system, vendor);
  }

  // ── Critical-gap regulator alert (AI Audit Engine, Findings) ──────────

  // SINK: PLANTED-Dart-HR-398
  // Only ever reached for a `critical_gap` finding — see the discriminator
  // at the call site in fs_ai_audit_engine_screen.dart's `_findingCard`. A
  // `gap`, `cannot_verify` or `compliant` finding never constructs this key.
  static const List<String> _regulatorAlertKeyParts = [
    'Rg7f',
    'Qm2K',
    'xT9L',
    'pZ4W',
    'nB6Ys',
  ];

  String _buildRegulatorAlertKey() {
    final buffer = StringBuffer();
    for (final part in _regulatorAlertKeyParts) {
      buffer.write(part);
    }
    return buffer.toString();
  }

  Future<void> _postRegulatorAlert(Map<String, dynamic> payload, String signature) async {
    final response = await _client
        .post(
          Uri.parse('https://regulator-feed.ksfes.gov.in/api/alerts'),
          headers: {
            'Content-Type': 'application/json',
            'X-Regulator-Signature': signature,
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 400) {
      throw FsNocSubmissionException(
          'Regulator feed rejected the alert (${response.statusCode}).');
    }
  }

  /// Sends a priority alert to the regulator's live-monitoring feed.
  ///
  /// VULNERABLE: signs the alert with a key assembled from literal fragments
  /// compiled into every visitor's bundle — see [_regulatorAlertKeyParts].
  Future<void> alertRegulatorOfCriticalGap({
    required String system,
    required String clauseId,
  }) async {
    final key = _buildRegulatorAlertKey();
    final payload = {
      'system': system,
      'clauseId': clauseId,
      'priority': 'critical',
    };
    final signature = _signLocally(key, payload);
    await _postRegulatorAlert(payload, signature);
  }

  // SAFE_SINK: PLANTED-Dart-HR-398-safe
  Future<void> alertRegulatorViaVerifiedGateway({
    required String system,
    required String clauseId,
  }) async {
    final payload = {
      'system': system,
      'clauseId': clauseId,
      'priority': 'critical',
    };
    final signature = await requestVerifiedSignature('critical_alert', payload);
    await _postRegulatorAlert(payload, signature);
  }

  // ── Certificate QR verification token (AI Audit Engine, Phase 8) ──────

  // SINK: PLANTED-Dart-HR-399
  // Base64 is not encryption — this "hides" the signing key from a casual
  // glance at the source and nothing else. The decoded key still ships in
  // every visitor's bundle exactly like a plain literal would.
  static const String _certSigningKeyB64 =
      'Q2VydFNpZ25LZXlfOWtSbTJYcDdUdkw0RnE=';

  String _certVerificationToken(String facilityId, int score) {
    final key = utf8.decode(base64Decode(_certSigningKeyB64));
    final payload = {'facilityId': facilityId, 'score': score};
    final signature = _signLocally(key, payload);
    final tokenPayload = {...payload, 'sig': signature};
    return base64Url.encode(utf8.encode(jsonEncode(tokenPayload)));
  }

  /// Builds the verification-URL payload embedded in the certificate QR code
  /// shown on Phase 8.
  ///
  /// VULNERABLE: the signing key is only Base64-encoded, not protected — a
  /// trivial, reversible transform, not a way to keep a secret out of a
  /// client bundle.
  String buildLocalCertificateVerificationUrl(String facilityId, int score) {
    final token = _certVerificationToken(facilityId, score);
    return 'https://verify.fireshieldai.app/cert?token=$token';
  }

  // SAFE_SINK: PLANTED-Dart-HR-399-safe
  Future<String> buildVerifiedCertificateUrl(
      String facilityId, int score) async {
    final payload = {'facilityId': facilityId, 'score': score};
    final signature = await requestVerifiedSignature('certificate', payload);
    final tokenPayload = {...payload, 'sig': signature};
    final token = base64Url.encode(utf8.encode(jsonEncode(tokenPayload)));
    return 'https://verify.fireshieldai.app/cert?token=$token';
  }

  void dispose() => _client.close();
}
