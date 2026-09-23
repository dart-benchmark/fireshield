/// Holds the audit currently being conducted.
///
/// In-memory and app-wide, matching how the rest of the demo reads from
/// mock data. Swap the backing store here when a real API lands — the
/// screens only talk to this class.
library;

import 'package:flutter/foundation.dart';

import '../../data/checkpoint_model.dart';
import '../../data/nbc_bis_masterdata.dart';
import '../../data/occupancy_taxonomy.dart';
import 'capa_engine.dart';
import 'risk_engine.dart';

class AuditSession extends ChangeNotifier {
  AuditSession._();

  static final AuditSession instance = AuditSession._();

  BuildingType? _buildingType;
  String _facilityName = '';
  final Map<String, CheckpointAnswer> _answers = {};
  List<CapaAction> _capa = [];

  BuildingType? get buildingType => _buildingType;
  String get facilityName => _facilityName;
  Map<String, CheckpointAnswer> get answers => Map.unmodifiable(_answers);
  List<CapaAction> get capaActions => List.unmodifiable(_capa);

  /// True once a building type has been picked and the checklist is usable.
  bool get isStarted => _buildingType != null;

  /// Checkpoints in scope for the chosen building type.
  List<Checkpoint> get checkpoints {
    final t = _buildingType;
    if (t == null) return const [];
    return OccupancyTaxonomy.checkpointsFor(t, allCheckpoints);
  }

  List<String> get categories {
    final seen = <String>[];
    for (final c in checkpoints) {
      if (!seen.contains(c.category)) seen.add(c.category);
    }
    return seen;
  }

  List<Checkpoint> checkpointsIn(String category) =>
      checkpoints.where((c) => c.category == category).toList();

  void start({required BuildingType type, String facilityName = ''}) {
    _buildingType = type;
    _facilityName = facilityName;
    _answers.clear();
    _capa = [];
    notifyListeners();
  }

  void answer(String checkpointId, Response response) {
    final existing = _answers[checkpointId] ??
        CheckpointAnswer(checkpointId: checkpointId);
    _answers[checkpointId] = existing.copyWith(response: response);
    notifyListeners();
  }

  void setRemarks(String checkpointId, String remarks) {
    final existing = _answers[checkpointId] ??
        CheckpointAnswer(checkpointId: checkpointId);
    _answers[checkpointId] = existing.copyWith(remarks: remarks);
    notifyListeners();
  }

  void addEvidence(String checkpointId, String ref) {
    final existing = _answers[checkpointId] ??
        CheckpointAnswer(checkpointId: checkpointId);
    _answers[checkpointId] =
        existing.copyWith(evidenceRefs: [...existing.evidenceRefs, ref]);
    notifyListeners();
  }

  Response responseFor(String checkpointId) =>
      _answers[checkpointId]?.response ?? Response.unanswered;

  /// Null until a building type is chosen.
  RiskAssessment? get assessment {
    final t = _buildingType;
    if (t == null) return null;
    return RiskEngine.assess(
      buildingType: t,
      checkpoints: checkpoints,
      answers: _answers,
    );
  }

  int get answeredCount => _answers.values
      .where((a) => a.response != Response.unanswered)
      .length;

  double get progress =>
      checkpoints.isEmpty ? 0 : answeredCount / checkpoints.length;

  /// Raises CAPAs for every failed checkpoint, replacing any previous set.
  List<CapaAction> generateCapa() {
    final t = _buildingType;
    if (t == null) return const [];
    _capa = CapaEngine.raiseFrom(
      failed: RiskEngine.failedCheckpoints(checkpoints, _answers),
      answers: _answers,
      buildingType: t,
    );
    notifyListeners();
    return _capa;
  }

  void updateCapa(String id, CapaAction updated) {
    final i = _capa.indexWhere((c) => c.id == id);
    if (i == -1) return;
    _capa[i] = updated;
    notifyListeners();
  }

  void reset() {
    _buildingType = null;
    _facilityName = '';
    _answers.clear();
    _capa = [];
    notifyListeners();
  }
}
