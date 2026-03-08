import '../../../../app/models.dart';
import '../../domain/entities/patient_visit_timeline_item.dart';

class PatientVisitTimelineApiModel {
  const PatientVisitTimelineApiModel({
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

  PatientVisitTimelineItem toEntity() {
    return PatientVisitTimelineItem(
      id: id,
      patientId: patientId,
      encounterType: encounterType,
      status: status,
      chiefComplaint: chiefComplaint,
      summary: summary,
      templateTitle: templateTitle,
      dictationsCount: dictationsCount,
      startedAt: startedAt,
      completedAt: completedAt,
      syncedAt: syncedAt,
    );
  }

  VisitRecord toVisitRecord() {
    return VisitRecord(
      id: id,
      patientId: patientId,
      encounterType: encounterType,
      status: status,
      chiefComplaint: chiefComplaint,
      conversationSummary: summary,
      startedAt: startedAt,
      completedAt: completedAt,
      syncedAt: syncedAt,
      meta: templateTitle == null
          ? null
          : <String, dynamic>{'template_title': templateTitle},
    );
  }

  factory PatientVisitTimelineApiModel.fromJson(
    String patientId,
    Map<String, dynamic> json,
  ) {
    final template = json['template'];

    return PatientVisitTimelineApiModel(
      id: json['id'] as String,
      patientId: patientId,
      encounterType: (json['encounter_type'] ?? 'follow_up') as String,
      status: (json['status'] ?? 'draft') as String,
      chiefComplaint: json['chief_complaint'] as String?,
      summary: json['summary'] as String?,
      templateTitle: template is Map<String, dynamic>
          ? template['title'] as String?
          : null,
      dictationsCount: (json['dictations_count'] as num?)?.toInt() ?? 0,
      startedAt: _parseDate(json['started_at']),
      completedAt: _parseDate(json['completed_at']),
      syncedAt: _parseDate(json['synced_at']),
    );
  }

  factory PatientVisitTimelineApiModel.fromVisitRecord(VisitRecord visit) {
    return PatientVisitTimelineApiModel(
      id: visit.id,
      patientId: visit.patientId,
      encounterType: visit.encounterType,
      status: visit.status,
      chiefComplaint: visit.chiefComplaint,
      summary: visit.conversationSummary ?? visit.assessment ?? visit.plan,
      templateTitle:
          visit.templateSnapshot == null ? null : visit.templateSnapshot!['title']?.toString(),
      startedAt: visit.startedAt,
      completedAt: visit.completedAt,
      syncedAt: visit.syncedAt,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}
