import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/activity_record.dart';
import 'activity_utils.dart';

List<ActivityRecord> mapRequestRecords(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return docs.map((doc) {
    final data = doc.data();
    final status = (data['status'] ?? 'submitted').toString();
    final detailPayload = Map<String, dynamic>.from(data)
      ..putIfAbsent('requestId', () => doc.id)
      ..putIfAbsent('submittedAt', () => data['submittedAt']);
    return ActivityRecord(
      type: ActivityType.request,
      data: detailPayload,
      date: _extractTimestamp(data['submittedAt']),
      title: (data['documentType'] ?? 'Document Request').toString(),
      subtitle: (data['purpose'] ?? 'No details provided').toString(),
      status: requestStatusLabel(status),
      statusColor: requestStatusColor(status),
      icon: Icons.description_outlined,
      iconBg: const Color(0xFFE8F3FF),
      iconColor: const Color(0xFF1F85D5),
    );
  }).toList();
}

List<ActivityRecord> mapIssueRecords(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return docs.map((doc) {
    final data = doc.data();
    final status = (data['status'] ?? 'submitted').toString();
    final detailPayload = Map<String, dynamic>.from(data)
      ..putIfAbsent('issueId', () => doc.id)
      ..putIfAbsent('createdAt', () => data['createdAt']);
    return ActivityRecord(
      type: ActivityType.issue,
      data: detailPayload,
      date: _extractTimestamp(data['createdAt']),
      title: (data['category'] ?? 'Reported Issue').toString(),
      subtitle: (data['location'] ?? 'No location provided').toString(),
      status: issueStatusLabel(status),
      statusColor: issueStatusColor(status),
      icon: Icons.warning_amber_outlined,
      iconBg: const Color(0xFFFFF2E6),
      iconColor: const Color(0xFFEE7A35),
    );
  }).toList();
}

List<ActivityRecord> mapPaymentRecords(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return docs.map((doc) {
    final data = doc.data();
    final amount = (data['paymentAmount'] as num?)?.toDouble() ?? 0;
    return ActivityRecord(
      type: ActivityType.payment,
      data: data,
      date: _extractTimestamp(data['paidAt']),
      title: 'Payment Receipt',
      subtitle:
          '${data['documentType'] ?? 'Document Fee'} - ₱${amount.toStringAsFixed(0)}',
      status: paymentStatusLabel(data['status']?.toString() ?? ''),
      statusColor: paymentStatusColor(data['status']?.toString() ?? ''),
      icon: Icons.receipt_long_outlined,
      iconBg: const Color(0xFFEAF4FF),
      iconColor: const Color(0xFF5E54FF),
    );
  }).toList();
}

DateTime _extractTimestamp(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return DateTime.now();
}
