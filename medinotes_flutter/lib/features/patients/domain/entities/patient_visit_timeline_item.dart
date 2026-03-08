class PatientVisitTimelineItem {
  const PatientVisitTimelineItem({
    required this.id,
    required this.patientId,
    required this.encounterType,
    required this.status,
    this.chiefComplaint,
    this.summary,
    this.templateTitle,
    this.dictationsCount = 0,
    this.startedAt,
    this.completedAt,
    this.syncedAt,
  });

  final String id;
  final String patientId;
  final String encounterType;
  final String status;
  final String? chiefComplaint;
  final String? summary;
  final String? templateTitle;
  final int dictationsCount;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? syncedAt;
}
