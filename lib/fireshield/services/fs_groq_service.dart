/// Client for the FireShield secure Groq gateway (Cloudflare Worker).
///
/// The app never holds GROQ_API_KEY — it POSTs to the Worker, which adds the
/// key server-side and (for reasoning) queries the NBCS 2026 graph live.
/// On any failure this throws [FsServiceException]; it never substitutes fake
/// compliance content (skill rule #8).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/fs_models.dart';
import 'fs_config.dart';

class FsServiceException implements Exception {
  final String message;
  final int? status;
  const FsServiceException(this.message, {this.status});
  @override
  String toString() => 'FsServiceException($status): $message';
}

/// Tracks Groq's own quota state for one model, from its response headers
/// (x-ratelimit-remaining-tokens / -reset-tokens, Retry-After). Nothing here
/// is hardcoded — every wait is derived from whatever Groq returned last.
class _RateWindow {
  int? remainingTokens;
  DateTime? resetAt;

  void observe(Map<String, String> headers) {
    final remaining = int.tryParse(headers['x-ratelimit-remaining-tokens'] ?? '');
    if (remaining != null) remainingTokens = remaining;
    final resetHeader = headers['x-ratelimit-reset-tokens'];
    final resetSeconds = _parseGroqDuration(resetHeader);
    if (resetSeconds != null) {
      resetAt = DateTime.now().add(Duration(milliseconds: (resetSeconds * 1000).round()));
    }
  }

  /// How long to wait before firing the next call of roughly [estimatedTokens]
  /// size, given what Groq last reported. Zero if there's no reason to wait.
  Duration waitBefore(int estimatedTokens) {
    final reset = resetAt;
    if (reset == null) return Duration.zero;
    final remaining = remainingTokens;
    if (remaining != null && remaining >= estimatedTokens) return Duration.zero;
    final until = reset.difference(DateTime.now());
    return until.isNegative ? Duration.zero : until;
  }
}

/// Parses Groq's rate-limit duration headers, e.g. "7.66s", "1m0.5s", "12ms".
double? _parseGroqDuration(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final match = RegExp(r'^(?:(\d+)m)?(\d+(?:\.\d+)?)(m?s)$').firstMatch(raw.trim());
  if (match == null) return double.tryParse(raw);
  final minutes = double.tryParse(match.group(1) ?? '0') ?? 0;
  final value = double.tryParse(match.group(2) ?? '0') ?? 0;
  final unit = match.group(3);
  final seconds = unit == 'ms' ? value / 1000 : value;
  return minutes * 60 + seconds;
}

/// Process-wide Groq quota tracker, shared across every service that draws
/// on the same model budget (site/photo audit's reasonCompliance here,
/// floor-plan compliance in fs_plan_service.dart). Different screens create
/// their own FsGroqService/FsPlanService instances, so this has to be a
/// static/global singleton — instance-level state wouldn't see calls made
/// from the other screen and a demo bouncing between features would still
/// collide into the same TPM window blind.
class FsGroqRateTracker {
  FsGroqRateTracker._();
  static const maxDynamicWait = Duration(seconds: 45);
  static final Map<String, _RateWindow> _windows = {};

  static Duration waitBefore(String rateKey, int estimatedTokens) {
    final wait = _windows.putIfAbsent(rateKey, () => _RateWindow()).waitBefore(estimatedTokens);
    return wait < maxDynamicWait ? wait : maxDynamicWait;
  }

  static void observe(String rateKey, Map<String, String> headers) {
    _windows.putIfAbsent(rateKey, () => _RateWindow()).observe(headers);
  }
}

class _RawResponse {
  final int status;
  final Map<String, dynamic>? decoded;
  final Map<String, String> headers;
  const _RawResponse({required this.status, required this.decoded, required this.headers});
}

class FsGroqService {
  FsGroqService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = (baseUrl ?? workerBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _base;

  static const _timeout = Duration(seconds: 60);

  bool get isConfigured => _base.isNotEmpty;

  Uri _uri(String path) => Uri.parse('$_base$path');

  /// [rateKey] groups calls that share a Groq quota (roughly: the model) via
  /// the process-wide [FsGroqRateTracker], so a wait derived from one call's
  /// headers applies to the next same-kind call — including calls made from
  /// a completely different screen/service instance. [estimatedTokens] only
  /// decides whether it's worth waiting at all, never the wait length itself.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? rateKey,
    int estimatedTokens = 1500,
  }) async {
    if (!isConfigured) {
      throw const FsServiceException(
          'AI service not configured — set FIRESHIELD_WORKER_URL at build time.');
    }
    final key = rateKey ?? path;
    final wait = FsGroqRateTracker.waitBefore(key, estimatedTokens);
    if (wait > Duration.zero) await Future.delayed(wait);

    final result = await _postOnce(path, body);
    FsGroqRateTracker.observe(key, result.headers);
    if (result.decoded?['error'] != null) {
      final retryAfter = (result.decoded?['retryAfterSeconds'] as num?)?.toDouble();
      if (retryAfter != null && retryAfter > 0 &&
          Duration(milliseconds: (retryAfter * 1000).round()) <= FsGroqRateTracker.maxDynamicWait) {
        // One dynamic, header-driven retry — mirrors the Worker's own backoff
        // so a same-window collision doesn't surface as a hard failure here.
        await Future.delayed(Duration(milliseconds: (retryAfter * 1000).round()));
        final retried = await _postOnce(path, body);
        FsGroqRateTracker.observe(key, retried.headers);
        return _unwrap(retried);
      }
    }
    return _unwrap(result);
  }

  Future<_RawResponse> _postOnce(String path, Map<String, dynamic> body) async {
    http.Response res;
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (isSupabaseConfigured) {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      res = await _client
          .post(_uri(path), headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
    } catch (e) {
      throw FsServiceException('Could not reach AI service: $e');
    }
    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = null;
    }
    return _RawResponse(status: res.statusCode, decoded: decoded, headers: res.headers);
  }

  Map<String, dynamic> _unwrap(_RawResponse res) {
    if (res.status >= 400 || res.decoded == null) {
      final msg = res.decoded?['error']?.toString() ?? 'request failed';
      throw FsServiceException(msg, status: res.status);
    }
    if (res.decoded!['error'] != null) {
      throw FsServiceException(res.decoded!['error'].toString(), status: res.status);
    }
    return res.decoded!;
  }

  /// Grounded chat through the Worker. The Worker adds relevant NBCS 2026
  /// graph results before calling gpt-oss; the browser never receives the key.
  Future<String> chat(List<Map<String, String>> messages) async {
    final res = await _post('/groq/chat', {'messages': messages});
    return res['content']?.toString() ?? '';
  }

  /// Vision detection: base64 data URLs → observed equipment (server-side Qwen).
  /// Works on every platform incl. mobile browsers (unlike in-browser CLIPSeg).
  Future<List<DetectedEquipment>> visionDetect(List<String> imageDataUrls,
      {String? prompt, Map<String, dynamic>? evidenceContext}) async {
    if (imageDataUrls.isEmpty) return const [];
    final body = <String, dynamic>{'images': imageDataUrls.take(5).toList()};
    if (prompt != null && prompt.isNotEmpty) body['prompt'] = prompt;
    if (evidenceContext != null) body['evidenceContext'] = evidenceContext;
    final res = await _post('/groq/vision', body);
    final list = res['detections'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((m) =>
            DetectedEquipment.fromJson({...m, 'source': m['source'] ?? 'qwen'}))
        .toList();
  }

  /// Direct NBC graph query (Regulations phase). Returns cited clauses.
  Future<List<NbcClause>> nbcQuery(String question,
      {String seedTerms = '', int k = 8, int hops = 1}) async {
    final res = await _post('/nbc/query', {
      'question': question,
      if (seedTerms.isNotEmpty) 'seed_terms': seedTerms,
      'k': k,
      'hops': hops,
    });
    final results = res['results'] as List? ?? const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(NbcClause.fromJson)
        .toList();
  }

  /// Compliance reasoning: gpt-oss decides mandatory systems, queries the graph
  /// live for each, compares vs observed, and returns findings + score.
  Future<FsAuditRun> reasonCompliance({
    required String occupancyGroup,
    required Map<String, dynamic> buildingProfile,
    required List<DetectedEquipment> detected,
    List<String> docs = const [],
    Map<String, dynamic> evidenceContext = const {},
    // Each entry: {label, level, floorAreaSqm?, coverage, detected: [...]}.
    // Lets the reasoning model grade spacing/coverage-sensitive systems
    // (extinguishers, sprinklers) per captured area instead of only against
    // a single flattened count that can hide a gap in an unphotographed zone.
    List<Map<String, dynamic>> zones = const [],
  }) async {
    final res = await _post(
      '/groq/reason',
      {
        'buildingProfile': buildingProfile,
        'detected': detected.map((d) => d.toJson()).toList(),
        'docs': docs,
        'evidenceContext': evidenceContext,
        if (zones.isNotEmpty) 'zones': zones,
      },
      // Shares the org's gpt-oss-120b TPM budget with floor-plan compliance
      // (fs_plan_service.dart) — same rate key so a wait learned from one
      // paces the other instead of both firing into the same 429.
      rateKey: 'gpt-oss-120b',
      estimatedTokens: 3000,
    );
    return FsAuditRun.fromVerdict(
      res,
      occupancyGroup: occupancyGroup,
      buildingProfile: buildingProfile,
      detected: detected,
      docs: docs,
    );
  }

  void dispose() => _client.close();
}
