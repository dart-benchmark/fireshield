/// Portfolio-level (all-facilities) scoring-policy resolvers, used by the Org
/// Admin dashboard's "Apply Formula" actions (`fs_orgadmin_dashboard.dart`).
///
/// Two concrete strategies share one interface; which one an admin action
/// constructs — not any branch inside the dispatch function below — decides
/// whether the organisation's raw formula text reaches the evaluator
/// unvalidated.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Builds the expression to hand to the evaluator from the organisation's
/// formula text and the portfolio's severity tallies.
abstract class FsScoreFormulaResolver {
  String buildExpression({
    required String formula,
    required int critical,
    required int major,
    required int minor,
  });
}

/// Substitutes the tallies and returns the organisation's formula text
/// verbatim otherwise — whatever else the admin typed survives untouched.
class JsEvalScoreFormulaResolver implements FsScoreFormulaResolver {
  const JsEvalScoreFormulaResolver();

  @override
  String buildExpression({
    required String formula,
    required int critical,
    required int major,
    required int minor,
  }) => formula
      .replaceAll(RegExp(r'\bcritical\b'), '$critical')
      .replaceAll(RegExp(r'\bmajor\b'), '$major')
      .replaceAll(RegExp(r'\bminor\b'), '$minor');
}

/// Same substitution, but falls back to a fixed, always-safe expression
/// unless the fully-substituted text passes a strict digits/operators
/// allow-list — the organisation's own free-form formula text can never
/// reach the evaluator unvalidated through this resolver.
class SafeArithmeticScoreFormulaResolver implements FsScoreFormulaResolver {
  const SafeArithmeticScoreFormulaResolver();

  @override
  String buildExpression({
    required String formula,
    required int critical,
    required int major,
    required int minor,
  }) {
    final substituted = formula
        .replaceAll(RegExp(r'\bcritical\b'), '$critical')
        .replaceAll(RegExp(r'\bmajor\b'), '$major')
        .replaceAll(RegExp(r'\bminor\b'), '$minor');
    return RegExp(r'^[0-9+\-*/(). \t]+$').hasMatch(substituted)
        ? substituted
        : '100 - ($critical*20 + $major*8 + $minor*2)';
  }
}

/// Dispatched from the "Apply Formula (JS engine)" button
/// (`fs_orgadmin_dashboard.dart`), always constructed with a
/// [JsEvalScoreFormulaResolver].
double? applyPortfolioFormulaViaResolver(
  FsScoreFormulaResolver resolver, {
  required String formula,
  required int critical,
  required int major,
  required int minor,
}) {
  final expr = resolver.buildExpression(
    formula: formula,
    critical: critical,
    major: major,
    minor: minor,
  );
  final JSAny? result = globalContext.callMethod(
    'eval'.toJS,
    expr.toJS,
  ); // SINK: PLANTED-Dart-HR-588
  final value = (result?.dartify() as num?)?.toDouble();
  return (value == null || value.isNaN) ? null : value.clamp(0, 100);
}

/// Dispatched from the "Apply Formula (safe engine)" button
/// (`fs_orgadmin_dashboard.dart`), always constructed with a
/// [SafeArithmeticScoreFormulaResolver] — structurally identical to
/// [applyPortfolioFormulaViaResolver] above; only the resolver's own
/// concrete type decides whether the evaluated text is trustworthy.
double? applyPortfolioFormulaViaResolverSafe(
  FsScoreFormulaResolver resolver, {
  required String formula,
  required int critical,
  required int major,
  required int minor,
}) {
  final expr = resolver.buildExpression(
    formula: formula,
    critical: critical,
    major: major,
    minor: minor,
  );
  final JSAny? result = globalContext.callMethod(
    'eval'.toJS,
    expr.toJS,
  ); // SAFE_SINK: PLANTED-Dart-HR-588-safe
  final value = (result?.dartify() as num?)?.toDouble();
  return (value == null || value.isNaN) ? null : value.clamp(0, 100);
}
