library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fs_config.dart';
import 'fs_groq_service.dart';

class FsPlanResult {
  final Map<String, dynamic> topology;
  final Map<String, dynamic> commercialModel;
  final Map<String, dynamic> guidance;
  final Map<String, dynamic> visionAdvisory;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> artifacts;
  final Map<String, dynamic> compliance;
  final List<String> warnings;

  const FsPlanResult({
    required this.topology,
    required this.commercialModel,
    required this.guidance,
    required this.visionAdvisory,
    required this.metrics,
    required this.artifacts,
    required this.compliance,
    required this.warnings,
  });

  factory FsPlanResult.fromJson(Map<String, dynamic> json) => FsPlanResult(
        topology: Map<String, dynamic>.from(json['topology'] as Map? ?? {}),
        commercialModel:
            Map<String, dynamic>.from(json['commercialModel'] as Map? ?? {}),
        guidance: Map<String, dynamic>.from(json['guidance'] as Map? ?? {}),
        visionAdvisory:
            Map<String, dynamic>.from(json['visionAdvisory'] as Map? ?? {}),
        metrics: Map<String, dynamic>.from(json['metrics'] as Map? ?? {}),
        artifacts: Map<String, dynamic>.from(json['artifacts'] as Map? ?? {}),
        compliance: Map<String, dynamic>.from(json['compliance'] as Map? ?? {}),
        warnings: (json['warnings'] as List? ?? const [])
            .map((item) => item.toString())
            .toList(),
      );
}

class FsPlanService {
  FsPlanService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = (baseUrl ?? workerBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _base;

  bool get isConfigured => _base.isNotEmpty;

  // Shares the org's gpt-oss-120b TPM budget with the site/photo audit's
  // reasonCompliance (fs_groq_service.dart) — same rate key so a wait learned
  // from one screen paces the other, since a demo can hit either in any order.
  static const _rateKey = 'gpt-oss-120b';

  Future<FsPlanResult> convert({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    int page = 0,
    String? overall,
    Map<String, dynamic> buildingProfile = const {},
    bool retriedAfterRateLimit = false,
  }) async {
    if (!isConfigured) {
      throw const FsServiceException(
          'Plan service not configured — set FIRESHIELD_WORKER_URL.');
    }
    if (bytes.isEmpty) {
      throw const FsServiceException('The selected file is empty.');
    }
    if (bytes.length > 25 * 1024 * 1024) {
      throw const FsServiceException('The selected plan exceeds 25 MB.');
    }
    final wait = FsGroqRateTracker.waitBefore(_rateKey, 3000);
    if (wait > Duration.zero) await Future.delayed(wait);

    final request =
        http.MultipartRequest('POST', Uri.parse('$_base/plan/convert'))
          ..fields['page'] = '$page'
          ..fields['require_qwen'] = 'true'
          ..fields['building_profile'] = jsonEncode(buildingProfile);
    if (isSupabaseConfigured) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    if (overall != null && overall.trim().isNotEmpty) {
      request.fields['overall'] = overall.trim();
    }
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    ));

    try {
      final streamed =
          await _client.send(request).timeout(const Duration(minutes: 3));
      final response = await http.Response.fromStream(streamed);
      FsGroqRateTracker.observe(_rateKey, response.headers);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FsServiceException(
            'Plan service returned an invalid response.');
      }
      if (response.statusCode >= 400 || decoded['error'] != null) {
        throw FsServiceException(
          decoded['detail']?.toString() ??
              decoded['error']?.toString() ??
              'Plan conversion failed.',
          status: response.statusCode,
        );
      }
      // Geometry conversion always succeeds standalone; only the embedded
      // compliance step can be TPM-limited (200 + partial:true). Re-running
      // the whole conversion is the only lever available (no compliance-only
      // endpoint), so retry once, dynamically, using Groq's own cooldown.
      final compliance = decoded['compliance'] as Map<String, dynamic>?;
      final retryAfter = (compliance?['retryAfterSeconds'] as num?)?.toDouble();
      if (decoded['partial'] == true &&
          !retriedAfterRateLimit &&
          retryAfter != null &&
          retryAfter > 0 &&
          Duration(milliseconds: (retryAfter * 1000).round()) <= FsGroqRateTracker.maxDynamicWait) {
        await Future.delayed(Duration(milliseconds: (retryAfter * 1000).round()));
        return convert(
          bytes: bytes,
          filename: filename,
          mimeType: mimeType,
          page: page,
          overall: overall,
          buildingProfile: buildingProfile,
          retriedAfterRateLimit: true,
        );
      }
      return FsPlanResult.fromJson(decoded);
    } on TimeoutException {
      throw const FsServiceException(
          'Plan processing timed out. The conversion service may be starting; retry once.');
    } on FsServiceException {
      rethrow;
    } catch (error) {
      throw FsServiceException('Could not process the plan: $error');
    }
  }

  void dispose() => _client.close();
}
