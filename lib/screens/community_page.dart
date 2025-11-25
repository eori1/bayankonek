import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'services_page.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  void _handleNavTap(BuildContext context, int index) {
    if (index == 2) return;
    if (index == 0 && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ServicesPage()),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This tab is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Community',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: const [
                    _HighlightCard(),
                    SizedBox(height: 24),
                    _CommunityEventList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onItemSelected: (index) => _handleNavTap(context, index),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C71FF), Color(0xFF1854D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1854D3).withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Updated',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get the latest news and announcements from your barangay.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1F85D5),
                    backgroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'View Announcements',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _CommunityEventList extends StatelessWidget {
  const _CommunityEventList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _communityEvents
          .map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _CommunityEventCard(event: event),
            ),
          )
          .toList(),
    );
  }
}

class _CommunityEventCard extends StatelessWidget {
  const _CommunityEventCard({required this.event});

  final _CommunityEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: event.iconBackground,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(event.icon, color: event.iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: event.badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            event.badge,
                            style: TextStyle(
                              color: event.badgeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5B6476),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE9EDF5)),
          const SizedBox(height: 18),
          _EventDetailRow(
            icon: Icons.calendar_month_outlined,
            label: event.dateLabel,
          ),
          const SizedBox(height: 8),
          _EventDetailRow(
            icon: Icons.access_time_outlined,
            label: event.timeLabel,
          ),
          const SizedBox(height: 8),
          _EventDetailRow(
            icon: Icons.location_on_outlined,
            label: event.location,
          ),
          const SizedBox(height: 8),
          _EventDetailRow(
            icon: Icons.people_alt_outlined,
            label: event.attendeesLabel,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B6F7F),
                side: const BorderSide(color: Color(0xFFE2E6F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDetailRow extends StatelessWidget {
  const _EventDetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9AA3B9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4A4F5F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CommunityEvent {
  const _CommunityEvent({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.dateLabel,
    required this.timeLabel,
    required this.location,
    required this.attendeesLabel,
    required this.badge,
    required this.badgeColor,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;
  final String dateLabel;
  final String timeLabel;
  final String location;
  final String attendeesLabel;
  final String badge;
  final Color badgeColor;
}

const _communityEvents = [
  _CommunityEvent(
    icon: Icons.clean_hands_outlined,
    iconBackground: Color(0xFFEAF4FF),
    iconColor: Color(0xFF2E7CFB),
    title: 'Community Clean-Up Drive',
    description:
        'Join us for a barangay-wide clean-up activity this Saturday. Help keep our community clean and green!',
    dateLabel: 'Dec 28, 2024',
    timeLabel: '7:00 AM – 12:00 PM',
    location: 'Barangay Hall',
    attendeesLabel: '45 going',
    badge: 'Event',
    badgeColor: Color(0xFF1ABC9C),
  ),
  _CommunityEvent(
    icon: Icons.favorite_outline,
    iconBackground: Color(0xFFFFEDEE),
    iconColor: Color(0xFFE74C3C),
    title: 'COVID-19 Vaccination Drive',
    description:
        'Free COVID-19 booster shots available for all residents. Bring your vaccination card and valid ID.',
    dateLabel: 'Jan 5, 2025',
    timeLabel: '8:00 AM – 5:00 PM',
    location: 'Health Center',
    attendeesLabel: '120 going',
    badge: 'Health',
    badgeColor: Color(0xFFE74C3C),
  ),
  _CommunityEvent(
    icon: Icons.celebration_outlined,
    iconBackground: Color(0xFFF4EEFF),
    iconColor: Color(0xFF9B59B6),
    title: 'New Year Community Celebration',
    description:
        'Celebrate the New Year with your neighbors! Food, games, and entertainment for the whole family.',
    dateLabel: 'Dec 31, 2024',
    timeLabel: '6:00 PM – 12:00 AM',
    location: 'Town Plaza',
    attendeesLabel: '200+ going',
    badge: 'Celebration',
    badgeColor: Color(0xFF9B59B6),
  ),
  _CommunityEvent(
    icon: Icons.warning_amber_outlined,
    iconBackground: Color(0xFFFFF5EA),
    iconColor: Color(0xFFF39C12),
    title: 'Road Closure Advisory',
    description:
        'Main Road will be closed for repairs from Jan 10–15. Please use alternative routes.',
    dateLabel: 'Jan 10, 2025',
    timeLabel: 'All day',
    location: 'Main Road',
    attendeesLabel: '—',
    badge: 'Advisory',
    badgeColor: Color(0xFFF39C12),
  ),
];

