import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportDetailsPage extends StatelessWidget {
  const ReportDetailsPage({super.key, required this.data});

  final Map<String, dynamic> data;

  String get _reportId =>
      (data['issueId'] as String?) ?? (data['id'] as String?) ?? 'Report';
  String get _category =>
      (data['category'] as String?) ?? 'Community Issue';
  String get _location =>
      (data['location'] as String?) ?? 'Location not specified';
  String get _description =>
      (data['description'] as String?) ?? 'No description provided.';
  String get _contact =>
      (data['contact'] as String?) ?? 'No contact provided';
  String get _status =>
      (data['status'] as String?)?.toLowerCase() ?? 'submitted';

  DateTime get _createdAt {
    final raw = data['createdAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is double) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }

  List<dynamic> get _photoUrls {
    final photos = data['photoUrls'];
    if (photos is List) return photos;
    return const [];
  }

  String get _statusLabel {
    switch (_status) {
      case 'in_progress':
        return 'In Progress';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'completed':
      case 'resolved':
        return 'Completed';
      default:
        return 'Submitted';
    }
  }

  Color get _statusColor {
    switch (_status) {
      case 'completed':
      case 'resolved':
        return const Color(0xFF3DBE8B);
      case 'in_progress':
        return const Color(0xFFFFA63F);
      case 'under_review':
      case 'approved':
        return const Color(0xFF4C8DFF);
      default:
        return const Color(0xFF9AA3B9);
    }
  }

  List<_ReportTimelineEvent> _timeline() {
    final steps = [
      'submitted',
      'under_review',
      'approved',
      'in_progress',
      'completed',
    ];
    final labels = [
      'Submitted',
      'Under Review',
      'Approved',
      'In Progress',
      'Completed',
    ];
    final descriptions = [
      'Issue reported',
      'Being reviewed by barangay',
      'Acknowledged by maintenance team',
      'Repair work in progress',
      'Repair completed',
    ];
    final dates = List.generate(
      steps.length,
      (index) => _createdAt.add(Duration(hours: 6 * index)),
    );

    final currentIndex =
        steps.indexWhere((step) => step == _status).clamp(0, steps.length - 1);

    return List.generate(steps.length, (index) {
      final status = index < currentIndex
          ? _TimelineStatus.done
          : index == currentIndex
              ? _TimelineStatus.active
              : _TimelineStatus.pending;
      return _ReportTimelineEvent(
        title: labels[index],
        description: descriptions[index],
        date: dates[index],
        status: status,
      );
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy · h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timeline();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Report Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(
                statusColor: _statusColor,
                statusLabel: _statusLabel,
                reportId: _reportId,
                category: _category,
                createdAt: _formatDate(_createdAt),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Location',
                child: _DetailTile(
                  icon: Icons.place_outlined,
                  primaryText: _location,
                  secondaryText: 'Pinned via Report Issue form',
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Description',
                child: Text(
                  _description,
                  style: const TextStyle(
                    color: Color(0xFF4C5665),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Photos',
                child: _photoUrls.isEmpty
                    ? const Text(
                        'No photos uploaded for this report.',
                        style: TextStyle(color: Color(0xFF9AA3B9)),
                      )
                    : SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final url = _photoUrls[index]?.toString() ?? '';
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE3E7F1),
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: _photoUrls.length,
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Action Timeline',
                child: Column(
                  children: List.generate(
                    timeline.length,
                    (index) => _TimelineRow(
                      event: timeline[index],
                      isLast: index == timeline.length - 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Reporter Information',
                child: _DetailTile(
                  icon: Icons.person_outline,
                  primaryText: 'You',
                  secondaryText: _contact,
                ),
              ),
              const SizedBox(height: 18),
              const _SectionCard(
                title: 'Updates',
                child: Text(
                  'You will receive SMS updates on this report. Estimated completion: within 5 business days.',
                  style: TextStyle(
                    color: Color(0xFF4C5665),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cancellation flow coming soon.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE3E4F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Cancel Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A5A73),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE0E6F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.statusColor,
    required this.statusLabel,
    required this.reportId,
    required this.category,
    required this.createdAt,
  });

  final Color statusColor;
  final String statusLabel;
  final String reportId;
  final String category;
  final String createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Report #$reportId',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF9AA3B9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5EC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFEE7A35),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Category: Community Report',
                      style: TextStyle(color: Color(0xFF7A8193)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 16,
                          color: Color(0xFF9AA3B9),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Reported on $createdAt',
                            style: const TextStyle(
                              color: Color(0xFF9AA3B9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.primaryText,
    required this.secondaryText,
  });

  final IconData icon;
  final String primaryText;
  final String secondaryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1F6FE3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  secondaryText,
                  style: const TextStyle(
                    color: Color(0xFF7A8193),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _TimelineStatus { done, active, pending }

class _ReportTimelineEvent {
  const _ReportTimelineEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });

  final String title;
  final String description;
  final DateTime date;
  final _TimelineStatus status;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.isLast});

  final _ReportTimelineEvent event;
  final bool isLast;

  Color get _color {
    switch (event.status) {
      case _TimelineStatus.done:
        return const Color(0xFF4C8DFF);
      case _TimelineStatus.active:
        return const Color(0xFF2AC769);
      case _TimelineStatus.pending:
        return const Color(0xFFBCC4D6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor = _color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: event.status == _TimelineStatus.pending
                    ? Colors.white
                    : indicatorColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: indicatorColor, width: 2),
              ),
              child: Icon(
                event.status == _TimelineStatus.pending
                    ? Icons.schedule
                    : Icons.check,
                size: 14,
                color: indicatorColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: const Color(0xFFE0E6F0),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: const TextStyle(
                    color: Color(0xFF7A8193),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy · h:mm a').format(event.date),
                  style: const TextStyle(
                    color: Color(0xFF9AA3B9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

