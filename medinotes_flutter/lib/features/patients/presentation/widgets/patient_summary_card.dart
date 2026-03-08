import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/patient_summary.dart';

class PatientSummaryCard extends StatelessWidget {
  const PatientSummaryCard({super.key, required this.summary});

  final PatientSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person_outline),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (summary.preferredName?.trim().isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Preferred: ${summary.preferredName}'),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(label: summary.medicalRecordNumber),
                          if (summary.clinicName?.trim().isNotEmpty ?? false)
                            _MetaChip(label: summary.clinicName!),
                          if (summary.visitsCount > 0)
                            _MetaChip(label: '${summary.visitsCount} visits'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _InfoLine(label: 'Phone', value: summary.phone),
                _InfoLine(label: 'Email', value: summary.email),
                _InfoLine(
                  label: 'DOB',
                  value: summary.dateOfBirth == null
                      ? null
                      : DateFormat('dd MMM yyyy').format(summary.dateOfBirth!),
                ),
                _InfoLine(label: 'Sex', value: summary.sex),
                _InfoLine(
                  label: 'Last visit',
                  value: summary.lastVisitAt == null
                      ? null
                      : DateFormat('dd MMM yyyy').format(summary.lastVisitAt!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryBlock(
              title: 'Medical history',
              body: summary.medicalHistorySummary ?? 'Medical history summary pending capture.',
            ),
            const SizedBox(height: 12),
            _SummaryBlock(
              title: 'Allergies',
              body: summary.allergiesSummary ?? 'Allergy summary pending capture.',
            ),
            const SizedBox(height: 12),
            _SummaryBlock(
              title: 'Medications',
              body: summary.medicationSummary ?? 'Medication summary pending capture.',
            ),
            if (summary.hasAlerts && summary.alerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Alerts / flags',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.alerts
                    .map(
                      (alert) => Chip(
                        avatar: const Icon(Icons.warning_amber_outlined, size: 18),
                        label: Text(alert),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(body),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value?.trim().isNotEmpty == true ? value! : '—'),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
