import 'package:flutter/material.dart';

class CommunityAnnouncement {
  const CommunityAnnouncement({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.timeLabel,
    required this.location,
    required this.organizer,
    required this.attendeesLabel,
    required this.badge,
    required this.badgeColor,
    this.reminderTitle = 'Important Reminder',
    this.reminderDetails =
        'Please arrive early. The event will start promptly at the posted time.',
    this.reminderColor = const Color(0xFFF39C12),
    this.contactPerson = 'Barangay Help Desk',
    this.contactPhone = '+63 917 000 0000',
    this.contactEmail = 'hello@barangay.gov',
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final String dateLabel;
  final String timeLabel;
  final String location;
  final String organizer;
  final String attendeesLabel;
  final String badge;
  final Color badgeColor;
  final String reminderTitle;
  final String reminderDetails;
  final Color reminderColor;
  final String contactPerson;
  final String contactPhone;
  final String contactEmail;
}

