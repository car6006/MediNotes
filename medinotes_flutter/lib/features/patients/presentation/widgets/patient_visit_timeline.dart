import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/patient_visit_timeline_item.dart';

class PatientVisitTimeline extends StatelessWidget {
  const PatientVisitTimeline({super.key, required this.timeline});

  final List<PatientVisitTimelineItem> timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visit timeline',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'No visit history has been captured yet. This timeline is ready for Phase 2 encounter history expansion.',
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visit timeline',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...timeline.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.event_note_outlined, size: 18),
                        ),
                        if (entry != timeline.last)
                          Container(
                            width: 2,
                            height: 64,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.chiefComplaint ?? 'Visit ${entry.encounterType}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              entry.status,
                              entry.templateTitle,
                              _formatDate(entry.startedAt),
                            ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
                          ),
                          if (entry.summary?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            Text(entry.summary!),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(entry.encounterType.replaceAll('_', ' '))),
                              if (entry.dictationsCount > 0)
                                Chip(label: Text('${entry.dictationsCount} dictations')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    return DateFormat('dd MMM yyyy').format(value);
  }
}
