import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key, required this.data});

  final Map<String, dynamic> data;

  String get _requestId =>
      (data['requestId'] as String?) ?? (data['id'] as String?) ?? 'Request';

  String get _documentType =>
      (data['documentType'] as String?) ?? 'Barangay Clearance';

  String get _purpose =>
      (data['purpose'] as String?) ?? 'For documentation requirements';

  String get _applicant =>
      (data['fullName'] as String?) ?? 'Applicant Name';

  String get _status => (data['status'] as String?)?.toLowerCase() ?? 'submitted';
  String get _paymentStatus =>
      (data['paymentStatus'] as String?)?.toLowerCase() ?? 'paid';

  double get _amountDue {
    final raw = data['amountDue'];
    if (raw is num) return raw.toDouble();
    return 0;
  }

  double get _paymentAmount {
    final raw = data['paymentAmount'];
    if (raw is num) return raw.toDouble();
    return _amountDue;
  }

  DateTime? get _paymentDueDate {
    final raw = data['paymentDueDate'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  DateTime? get _paidAt {
    final raw = data['paidAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  DateTime get _submittedAt {
    final raw = data['submittedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.now();
  }

  DateTime get _expectedCompletion => _submittedAt.add(const Duration(days: 4));

  String _formatShortDate(DateTime date) {
    return DateFormat('MM/dd/yy').format(date);
  }

  Color _statusColor() {
    switch (_status) {
      case 'payment_pending':
        return const Color(0xFFEE3E4F);
      case 'ready':
        return const Color(0xFF2AC769);
      case 'processing':
        return const Color(0xFFE0A218);
      default:
        return const Color(0xFF7A8193);
    }
  }

  List<_TimelineEvent> _timelineEvents() {
    final anchors = <DateTime>[
      _submittedAt,
      _submittedAt.add(const Duration(hours: 3)),
      _submittedAt.add(const Duration(hours: 8)),
      _submittedAt.add(const Duration(days: 1)),
      _submittedAt.add(const Duration(days: 2)),
      _submittedAt.add(const Duration(days: 3)),
    ];

    final steps = <String>[
      'payment_pending',
      'submitted',
      'reviewed',
      'approved',
      'processing',
      'ready',
    ];
    final idx = steps.indexWhere((step) => step == _status);
    final currentIndex = idx < 0 ? 0 : idx.clamp(0, steps.length - 1);

    final descriptions = [
      'Awaiting payment confirmation',
      'Your request has been submitted',
      'Documents reviewed by staff',
      'Approved by barangay captain',
      'Document is being prepared',
      'Ready for pickup',
    ];

    return List.generate(steps.length, (index) {
      final normalizedStatus = index < currentIndex
          ? _TimelineStatus.done
          : index == currentIndex
              ? _TimelineStatus.active
              : _TimelineStatus.pending;
      return _TimelineEvent(
        title: steps[index][0].toUpperCase() + steps[index].substring(1),
        description: descriptions[index],
        date: anchors[index],
        status: normalizedStatus,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timelineEvents();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Request Details',
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
              _RequestHeaderCard(
                requestId: _requestId,
                documentType: _documentType,
                purpose: _purpose,
                submittedAt: _formatShortDate(_submittedAt),
                statusColor: _statusColor(),
                statusLabel: _status == 'ready'
                    ? 'Ready for pickup'
                    : _status == 'processing'
                        ? 'Processing'
                        : 'Submitted',
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Processing Timeline',
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
                title: 'Applicant Information',
                child: Column(
                  children: [
                    _InfoRow(label: 'Name', value: _applicant),
                    _InfoRow(label: 'Document Type', value: _documentType),
                    _InfoRow(label: 'Purpose', value: _purpose),
                    _InfoRow(
                        label: 'Submission Date',
                        value: _formatShortDate(_submittedAt)),
                    _InfoRow(
                      label: 'Expected Completion',
                      value: _formatShortDate(_expectedCompletion),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                child: _PaymentCard(
                  amountDue: _amountDue,
                  paymentStatus: _paymentStatus,
                  dueDate: _paymentDueDate,
                  paymentAmount: _paymentAmount,
                  paidAt: _paidAt,
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                child: _NoticeCard(
                  message:
                      'Bring a valid ID and claim stub when picking up the document. Office hours: Monday–Friday, 8:00 AM – 5:00 PM.',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt download coming soon.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6FE3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.download_outlined, color: Colors.white),
                  label: const Text(
                    'Download Receipt',
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
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A5568),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFE0E6F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
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

class _RequestHeaderCard extends StatelessWidget {
  const _RequestHeaderCard({
    required this.requestId,
    required this.documentType,
    required this.purpose,
    required this.submittedAt,
    required this.statusColor,
    required this.statusLabel,
  });

  final String requestId;
  final String documentType;
  final String purpose;
  final String submittedAt;
  final Color statusColor;
  final String statusLabel;

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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
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
                  color: statusColor.withValues(alpha: 0.15),
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
                  'Ref: $requestId',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7A8193),
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
                  color: const Color(0xFFF1F6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF1F6FE3),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For $purpose',
                      style: const TextStyle(color: Color(0xFF7A8193)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Color(0xFF9AA3B9)),
                        const SizedBox(width: 4),
                        Text(
                          'Submitted on $submittedAt',
                          style: const TextStyle(color: Color(0xFF9AA3B9)),
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
  const _SectionCard({this.title, required this.child});

  final String? title;
  final Widget child;

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
            color: Colors.black.withValues(alpha: 0.04),
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
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B94A9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1F1F1F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TimelineStatus { done, active, pending }

class _TimelineEvent {
  const _TimelineEvent({
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
  const _TimelineRow({
    required this.event,
    required this.isLast,
  });

  final _TimelineEvent event;
  final bool isLast;

  Color get _color {
    switch (event.status) {
      case _TimelineStatus.done:
        return const Color(0xFF1F6FE3);
      case _TimelineStatus.active:
        return const Color(0xFF2AC769);
      case _TimelineStatus.pending:
        return const Color(0xFFBCC4D6);
    }
  }

  Widget _buildIndicator() {
    final bool isPending = event.status == _TimelineStatus.pending;
    final double size = 28;
    final Color borderColor =
        isPending ? const Color(0xFFE0E6F0) : _color;
    final Color fillColor =
        isPending ? Colors.white : _color.withValues(alpha: 0.15);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fillColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          if (!isPending)
            BoxShadow(
              color: _color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Icon(
        isPending ? Icons.access_time : Icons.check,
        size: 16,
        color: isPending ? const Color(0xFF9AA3B9) : _color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildIndicator(),
            if (!isLast)
              Container(
                width: 3,
                height: 56,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: event.status == _TimelineStatus.pending
                      ? const Color(0xFFE7EBF3)
                      : _color.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
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
                  style: const TextStyle(color: Color(0xFF7A8193)),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy · h:mm a').format(event.date),
                  style: const TextStyle(color: Color(0xFF9AA3B9)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.amountDue,
    required this.paymentStatus,
    this.dueDate,
    this.paidAt,
    required this.paymentAmount,
  });

  final double amountDue;
  final String paymentStatus;
  final double paymentAmount;
  final DateTime? dueDate;
  final DateTime? paidAt;

  bool get _isPaid => paymentStatus == 'paid';

  @override
  Widget build(BuildContext context) {
    final themeColor = _isPaid ? const Color(0xFF1F9D5C) : const Color(0xFFEE3E4F);
    final title = _isPaid ? 'Payment Completed' : 'Payment Pending';
    final subtitle = _isPaid
        ? '₱${paymentAmount.toStringAsFixed(2)} • Paid on ${DateFormat('MM/dd/yy').format(paidAt ?? DateTime.now())}'
        : '₱${amountDue.toStringAsFixed(2)} • Due on ${dueDate != null ? DateFormat('MM/dd/yy').format(dueDate!) : '—'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isPaid ? const Color(0xFFE7F7EE) : const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPaid ? Icons.check_circle : Icons.schedule_outlined,
              color: themeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF3A4A5A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF1F6FE3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Important Notice',
                  style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(color: Color(0xFF4A5A73), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

