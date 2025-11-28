import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/activity_record.dart';
import '../utils/activity_mappers.dart';
import '../utils/activity_utils.dart';
import 'payment_receipt_page.dart';
import 'report_details_page.dart';
import 'request_details_page.dart';

class AllActivityPage extends StatelessWidget {
  const AllActivityPage({super.key, required this.userId});
  
  final String userId;

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestStream() {
    return FirebaseFirestore.instance
        .collection('Requests')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _issueStream() {
    return FirebaseFirestore.instance
        .collection('Issues')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _paymentStream() {
    return FirebaseFirestore.instance
        .collection('Payments')
        .where('userId', isEqualTo: userId)
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'All Activity',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _requestStream(),
          builder: (context, requestSnapshot) {
            final requestDocs = requestSnapshot.data?.docs ?? [];
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _issueStream(),
              builder: (context, issueSnapshot) {
                final issueDocs = issueSnapshot.data?.docs ?? [];
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _paymentStream(),
                  builder: (context, paymentSnapshot) {
                    if (requestSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        issueSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        paymentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final records = [
                      ...mapRequestRecords(requestDocs),
                      ...mapIssueRecords(issueDocs),
                      ...mapPaymentRecords(paymentSnapshot.data?.docs ?? []),
                    ];

                    if (records.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No activity yet. Submit a request, report, or payment to see it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF6B6F7F)),
                          ),
                        ),
                      );
                    }

                    records.sort((a, b) => b.date.compareTo(a.date));
                    final total = records.length;
                    final ongoing = records.where((record) {
                      switch (record.type) {
                        case ActivityType.request:
                          return !record.status.toLowerCase().contains('ready') &&
                              !record.status.toLowerCase().contains('completed');
                        case ActivityType.issue:
                          return !record.status.toLowerCase().contains('resolved') &&
                              !record.status.toLowerCase().contains('completed');
                        case ActivityType.payment:
                          return false;
                      }
                    }).length;
                    final completed = total - ongoing;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        _ActivityStatsRow(
                          total: total,
                          ongoing: ongoing,
                          completed: completed,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Activity History',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...records.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActivityHistoryTile(record: record),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Back to Home'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ActivityStatsRow extends StatelessWidget {
  const _ActivityStatsRow({
    required this.total,
    required this.ongoing,
    required this.completed,
  });

  final int total;
  final int ongoing;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActivityStatCard(
              label: 'Total',
              valueColor: const Color(0xFF1F75FF),
              value: total,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActivityStatCard(
              label: 'Ongoing',
              valueColor: const Color(0xFFF5A524),
              value: ongoing,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActivityStatCard(
              label: 'Completed',
              valueColor: const Color(0xFF30C38C),
              value: completed,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStatCard extends StatelessWidget {
  const _ActivityStatCard({
    required this.label,
    required this.valueColor,
    required this.value,
  });

  final String label;
  final Color valueColor;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B6F7F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHistoryTile extends StatelessWidget {
  const _ActivityHistoryTile({required this.record});

  final ActivityRecord record;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        switch (record.type) {
          case ActivityType.request:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RequestDetailsPage(
                  requestId: record.data['requestId']?.toString() ?? '',
                  initialData: record.data,
                ),
              ),
            );
            break;
          case ActivityType.issue:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportDetailsPage(data: record.data),
              ),
            );
            break;
          case ActivityType.payment:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PaymentReceiptPage(paymentData: record.data),
              ),
            );
            break;
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: record.iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(record.icon, color: record.iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B6F7F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTimeAgo(record.date),
                    style: const TextStyle(
                      color: Color(0xFF9AA3B9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: record.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                record.status,
                style: TextStyle(
                  color: record.statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

