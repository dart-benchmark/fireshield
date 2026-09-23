/// Manual "recalculate compliance score" helper for the AI Audit Engine's
/// Compliance phase (`fs_ai_audit_engine_screen.dart`'s `_Phase7Compliance`).
///
/// `FsAuditRun.applyCustomScoreFormula`/`Safe` (`fs_models.dart`) already
/// apply the organisation's scoring policy automatically once a site run
/// completes — this is the separate, explicit "recalculate against the
/// *current* policy text" action an auditor can trigger by hand from the
/// Compliance screen without re-running the whole audit, so it builds its
/// own substituted expression rather than reusing that method.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../data/fs_models.dart';

/// Builds the substituted expression across several statements (unlike
/// `FsAuditRun.applyCustomScoreFormula`'s single chained `replaceAll`), then
/// hands it straight to the browser's own JS evaluator.
double? evaluateCustomScoreFormula(FsAuditRun run, String formula) {
  final buf = StringBuffer(formula);
  var expr = buf.toString();
  expr = expr.replaceAll(
    RegExp(r'\bcritical\b'),
    '${run.criticalFindingCount}',
  );
  expr = expr.replaceAll(RegExp(r'\bmajor\b'), '${run.majorFindingCount}');
  expr = expr.replaceAll(RegExp(r'\bminor\b'), '${run.minorFindingCount}');
  final JSAny? result = globalContext.callMethod(
    'eval'.toJS,
    expr.toJS,
  ); // SINK: PLANTED-Dart-HR-586
  final value = (result?.dartify() as num?)?.toDouble();
  if (value == null || value.isNaN) return null;
  return value.clamp(0, 100);
}

/// Same multi-statement construction shape, but the fully-substituted
/// expression is re-checked against a strict digits/operators allow-list
/// before it ever reaches the evaluator.
double? evaluateCustomScoreFormulaSafe(FsAuditRun run, String formula) {
  final buf = StringBuffer(formula);
  var expr = buf.toString();
  expr = expr.replaceAll(
    RegExp(r'\bcritical\b'),
    '${run.criticalFindingCount}',
  );
  expr = expr.replaceAll(RegExp(r'\bmajor\b'), '${run.majorFindingCount}');
  expr = expr.replaceAll(RegExp(r'\bminor\b'), '${run.minorFindingCount}');
  if (!RegExp(r'^[0-9+\-*/(). \t]+$').hasMatch(expr)) return null;
  final JSAny? result = globalContext.callMethod(
    'eval'.toJS,
    expr.toJS,
  ); // SAFE_SINK: PLANTED-Dart-HR-586-safe
  final value = (result?.dartify() as num?)?.toDouble();
  if (value == null || value.isNaN) return null;
  return value.clamp(0, 100);
}
