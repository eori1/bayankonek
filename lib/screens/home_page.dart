import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/activity_record.dart';
import '../utils/activity_mappers.dart';
import '../utils/activity_utils.dart';
import '../widgets/app_bottom_nav.dart';
import 'all_activity_page.dart';
import 'community_page.dart';
import 'notifications_page.dart';
import 'payment_receipt_page.dart';
import 'payments_page.dart';
import 'profile_page.dart';
import 'report_details_page.dart';
import 'request_details_page.dart';
import 'services_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroHeader(user: user),
                  const SizedBox(height: 24),
                  const _NotificationsSection(),
                  const SizedBox(height: 24),
                  const _QuickServicesSection(),
                  const SizedBox(height: 24),
                  _RecentActivitySection(userId: userId),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          const ServicesPage(embedded: true),
          const CommunityPage(embedded: true),
          const PaymentsPage(embedded: true),
          const ProfilePage(embedded: true),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onItemSelected: _onNavTap,
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName;
    final greetingName = (displayName != null && displayName.isNotEmpty)
        ? displayName.split(' ').first
        : 'Citizen';
    final phoneStatus = user?.phoneNumber ?? 'Not linked yet';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F85D5), Color(0xFF1A60C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A60C8).withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good afternoon!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greetingName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        _UserStatsRow(userId: user?.uid),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Linked number: $phoneStatus',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    final notifications = [
      const _NotificationData(
        title: 'Document ready for pickup',
        body: 'Barangay Clearance',
        tag: 'New',
        color: Color(0xFF30C38C),
        timeAgo: '2h ago',
        icon: Icons.check_circle_outline,
      ),
      const _NotificationData(
        title: 'Payment reminder',
        body: 'Community Tax due tomorrow',
        tag: 'Due Soon',
        color: Color(0xFFF5A524),
        timeAgo: '1d ago',
        icon: Icons.payments_outlined,
      ),
      const _NotificationData(
        title: 'Clean-up Drive',
        body: 'Bring gloves and water bottle',
        tag: 'Event',
        color: Color(0xFF5E54FF),
        timeAgo: '3d ago',
        icon: Icons.campaign_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1F85D5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1F1F),
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...notifications.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HomeNotificationTile(data: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationData {
  const _NotificationData({
    required this.title,
    required this.body,
    required this.tag,
    required this.color,
    required this.timeAgo,
    required this.icon,
  });

  final String title;
  final String body;
  final String tag;
  final Color color;
  final String timeAgo;
  final IconData icon;
}

class _HomeNotificationTile extends StatelessWidget {
  const _HomeNotificationTile({required this.data});

  final _NotificationData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  style: const TextStyle(color: Color(0xFF6B6F7F)),
                ),
                const SizedBox(height: 4),
                Text(
                  data.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9AA3B9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.tag,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: data.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickServicesSection extends StatelessWidget {
  const _QuickServicesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Quick Services'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ServiceCard(
                icon: Icons.description_outlined,
                label: 'Request Document',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ServicesPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ServiceCard(
                icon: Icons.warning_amber_outlined,
                label: 'Report Issue',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ServicesPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E6F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1F85D5), size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F85D5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.userId});

  final String? userId;

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestStream() {
    final collection = FirebaseFirestore.instance.collection('Requests');
    if (userId == null) {
      return collection
          .orderBy('submittedAt', descending: true)
          .limit(3)
          .snapshots();
    }
    return collection.where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _issueStream() {
    final collection = FirebaseFirestore.instance.collection('Issues');
    if (userId == null) {
      return collection
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots();
    }
    return collection.where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _paymentStream() {
    final collection = FirebaseFirestore.instance.collection('Payments');
    if (userId == null) {
      return collection.snapshots();
    }
    return collection
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionHeader(title: 'Recent Activity'),
          SizedBox(height: 16),
          _EmptyActivityCard(message: 'Sign in to see your activity.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent Activity',
          actionLabel: 'View All',
          onActionTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AllActivityPage(userId: userId!),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _requestStream(),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (requestSnapshot.hasError) {
              return const _EmptyActivityCard(
                message: 'Unable to load recent activity.',
              );
            }

            final requestDocs = requestSnapshot.data?.docs ?? [];

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _issueStream(),
              builder: (context, issueSnapshot) {
                final issueDocs = issueSnapshot.data?.docs ?? [];
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _paymentStream(),
                  builder: (context, paymentSnapshot) {
                    if (paymentSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        requestDocs.isEmpty &&
                        issueDocs.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final records = [
                      ...mapRequestRecords(requestDocs),
                      if (!issueSnapshot.hasError)
                        ...mapIssueRecords(issueDocs),
                      if (!(paymentSnapshot.hasError))
                        ...mapPaymentRecords(
                            paymentSnapshot.data?.docs ?? []),
                    ];

                    if (records.isEmpty) {
                      return const _EmptyActivityCard(
                        message:
                            'No activity yet. Submit a request or report to see it here.',
                      );
                    }

                    records.sort((a, b) => b.date.compareTo(a.date));
                    final recent = records.take(3).toList();

                    return Column(
                      children: recent.map((record) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ActivityItem(
                            title: record.title,
                            subtitle: record.subtitle,
                            timeAgo: formatTimeAgo(record.date),
                            status: record.status,
                            statusColor: record.statusColor,
                            icon: record.icon,
                            iconBg: record.iconBg,
                            iconColor: record.iconColor,
                            onTap: () {
                              switch (record.type) {
                                case ActivityType.request:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RequestDetailsPage(
                                        requestId:
                                            record.data['requestId']?.toString() ??
                                                '',
                                        initialData: record.data,
                                      ),
                                    ),
                                  );
                                  break;
                                case ActivityType.issue:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReportDetailsPage(
                                        data: record.data,
                                      ),
                                    ),
                                  );
                                  break;
                                case ActivityType.payment:
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentReceiptPage(
                                        paymentData: record.data,
                                      ),
                                    ),
                                  );
                                  break;
                              }
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({required this.message});

  final String message;

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
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF7A8193)),
      ),
    );
  }
}

class _UserStatsRow extends StatelessWidget {
  const _UserStatsRow({required this.userId});

  final String? userId;

  Stream<QuerySnapshot<Map<String, dynamic>>> _statsStream() {
    final collection = FirebaseFirestore.instance.collection('Requests');
    return collection.where('userId', isEqualTo: userId).snapshots();
  }

  int _activeRequests(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((doc) {
      final status = (doc.data()['status'] ?? 'submitted').toString().toLowerCase();
      return status != 'completed' && status != 'ready' && status != 'ready for pickup';
    }).length;
  }

  double _pendingAmount(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    double total = 0;
    for (final doc in docs) {
      final status = (doc.data()['status'] ?? '').toString().toLowerCase();
      final rawAmount = doc.data()['amountDue'];
      if (rawAmount is num &&
          status != 'completed' &&
          status != 'ready' &&
          status != 'ready for pickup') {
        total += rawAmount.toDouble();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Row(
        children: const [
          Expanded(child: _StatCard(title: 'Active Requests', value: '0')),
          SizedBox(width: 16),
          Expanded(child: _StatCard(title: 'Amount Due', value: '₱0')),
        ],
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _statsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: const [
              Expanded(child: _StatCard(title: 'Active Requests', value: '—')),
              SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Amount Due', value: '—')),
            ],
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final active = _activeRequests(docs);
        final pendingAmount = _pendingAmount(docs);
        final amountLabel = pendingAmount == 0
            ? '₱0'
            : '₱${pendingAmount.toStringAsFixed(0)}';

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Active Requests',
                value: active.toString(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Amount Due',
                value: amountLabel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String timeAgo;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5A6272),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF9AA3B9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9AA3B9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F85D5),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
