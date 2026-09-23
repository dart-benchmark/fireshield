/// Core audit checkpoint model — shared by the NBC and BIS masters,
/// the risk engine and the CAPA engine.
library;

enum CheckpointSource { nbc, bis }

/// How badly a failed checkpoint hurts. Drives both the risk score weight
/// and the CAPA due-date window.
enum Severity { critical, major, minor }

extension SeverityInfo on Severity {
  /// Weight used by the risk engine. A critical miss costs 5x a minor one.
  int get weight => switch (this) {
        Severity.critical => 5,
        Severity.major => 3,
        Severity.minor => 1,
      };

  String get label => switch (this) {
        Severity.critical => 'Critical',
        Severity.major => 'Major',
        Severity.minor => 'Minor',
      };

  /// Days allowed to close a CAPA raised against this severity.
  int get capaDueDays => switch (this) {
        Severity.critical => 7,
        Severity.major => 30,
        Severity.minor => 90,
      };
}

/// The auditor's answer to a checkpoint.
enum Response { unanswered, yes, no, notApplicable }

extension ResponseInfo on Response {
  String get label => switch (this) {
        Response.unanswered => 'Not answered',
        Response.yes => 'Yes',
        Response.no => 'No',
        Response.notApplicable => 'N/A',
      };

  /// N/A and unanswered are excluded from scoring — they must not be
  /// silently counted as passes.
  bool get isScored => this == Response.yes || this == Response.no;
}

class Checkpoint {
  /// Stable id, e.g. NBC-001 / BIS-014. Safe to store against an audit record.
  final String id;
  final CheckpointSource source;

  /// NBC category ("Means of Escape") or BIS standard ("IS 2189").
  final String category;
  final String subCategory;
  final String title;
  final String description;

  /// What the auditor has to photograph or attach to prove the answer.
  final String evidence;
  final Severity severity;

  const Checkpoint({
    required this.id,
    required this.source,
    required this.category,
    required this.subCategory,
    required this.title,
    required this.description,
    required this.evidence,
    required this.severity,
  });

  String get standardLabel =>
      source == CheckpointSource.nbc ? 'NBC 2016 Part 4' : category;
}

/// One answered checkpoint within an audit.
class CheckpointAnswer {
  final String checkpointId;
  final Response response;
  final String remarks;

  /// Local file paths / URLs of evidence captured against this checkpoint.
  final List<String> evidenceRefs;

  const CheckpointAnswer({
    required this.checkpointId,
    this.response = Response.unanswered,
    this.remarks = '',
    this.evidenceRefs = const [],
  });

  CheckpointAnswer copyWith({
    Response? response,
    String? remarks,
    List<String>? evidenceRefs,
  }) =>
      CheckpointAnswer(
        checkpointId: checkpointId,
        response: response ?? this.response,
        remarks: remarks ?? this.remarks,
        evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      );
}
