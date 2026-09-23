/// App-wide state — the Flutter equivalent of the PWA's `useApp()` context
/// (pwa_app/src/App.jsx).
library;

import 'package:flutter/foundation.dart';

import '../data/occupancy_taxonomy.dart';
import 'data/fs_models.dart';

class FsAppState extends ChangeNotifier {
  FsAppState._();

  static final FsAppState instance = FsAppState._();

  FsUser? _user;
  FsUser? get user => _user;

  bool get isAuthenticated => _user != null;

  /// Last building classified in the Building Classification screen, so the AI
  /// Audit Engine can start pre-scoped to it instead of re-selecting.
  BuildingType? _classifiedBuilding;
  BuildingType? get classifiedBuilding => _classifiedBuilding;

  void setClassifiedBuilding(BuildingType? type) {
    _classifiedBuilding = type;
    notifyListeners();
  }

  /// Org-wide custom compliance-scoring formula, authored by an Org Admin
  /// (Overview → Scoring Policy). Null means "use the reasoning model's own
  /// score, unmodified" — the default until an org configures one.
  String? _customScoreFormula;
  String? get customScoreFormula => _customScoreFormula;

  void setCustomScoreFormula(String? formula) {
    _customScoreFormula = (formula == null || formula.trim().isEmpty)
        ? null
        : formula.trim();
    notifyListeners();
  }

  /// Landing route for the signed-in user, mirroring the PWA's
  /// `navigate('/' + user.role)`.
  String get homeRoute => _user == null ? '/login' : '/${_user!.role.key}';

  void login(FsUser user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
