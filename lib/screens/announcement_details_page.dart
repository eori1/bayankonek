import 'package:flutter/material.dart';

import '../models/community_announcement.dart';

class AnnouncementDetailsPage extends StatelessWidget {
  const AnnouncementDetailsPage({super.key, required this.announcement});

  final CommunityAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Announcement Details',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(announcement: announcement),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Description',
                child: Text(
                  announcement.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF4A4F5F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ReminderCard(announcement: announcement),
              const SizedBox(height: 16),
              _InquiriesCard(announcement: announcement),
              const SizedBox(height: 24),
              _PrimaryButton(
                label: 'Confirm Attendance',
                background: const Color(0xFF1F85D5),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance confirmed!'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                label: 'Back to Community',
                background: const Color(0xFFF2F4FA),
                labelColor: const Color(0xFF1F85D5),
                borderColor: const Color(0xFFE0E6F2),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.announcement});

  final CommunityAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF1C76D6), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Information',
                      style: TextStyle(
                        color: Color(0xFF1C76D6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Color(0xFF7A8193)),
                onPressed: () {},
              ),
              IconButton(
                icon:
                    const Icon(Icons.bookmark_border, color: Color(0xFF7A8193)),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            announcement.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
          ),
          const SizedBox(height: 20),
          _InfoRow(
            icon: Icons.date_range_outlined,
            label: 'Date & Time',
            value: '${announcement.dateLabel} • ${announcement.timeLabel}',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Location',
            value: announcement.location,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.group_outlined,
            label: 'Organizer',
            value: announcement.organizer,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF1F85D5), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8A92A6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.announcement});

  final CommunityAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: announcement.reminderColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: announcement.reminderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.notifications_active_outlined,
                color: announcement.reminderColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.reminderTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: announcement.reminderColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  announcement.reminderDetails,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF4A4F5F),
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

class _InquiriesCard extends StatelessWidget {
  const _InquiriesCard({required this.announcement});

  final CommunityAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'For Inquiries',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InquiryRow(label: 'Contact Person', value: announcement.contactPerson),
          const SizedBox(height: 12),
          _InquiryRow(label: 'Phone', value: announcement.contactPhone),
          const SizedBox(height: 12),
          _InquiryRow(label: 'Email', value: announcement.contactEmail),
        ],
      ),
    );
  }
}

class _InquiryRow extends StatelessWidget {
  const _InquiryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A92A6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.background,
    required this.onPressed,
    this.labelColor = Colors.white,
    this.borderColor,
  });

  final String label;
  final Color background;
  final Color labelColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: labelColor,
          elevation: background == Colors.white ? 0 : 2,
          side: borderColor != null ? BorderSide(color: borderColor!) : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

