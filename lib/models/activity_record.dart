import 'package:flutter/material.dart';

enum ActivityType { request, issue, payment }

class ActivityRecord {
  const ActivityRecord({
    required this.type,
    required this.data,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final ActivityType type;
  final Map<String, dynamic> data;
  final DateTime date;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}
