import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'services_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    void handleNavTap(int index) {
      if (index == 0) return;
      if (index == 1) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ServicesPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This tab is coming soon.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: SafeArea(
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onItemSelected: handleNavTap,
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
            color: const Color(0xFF1A60C8).withOpacity(0.35),
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
                        color: Colors.white.withOpacity(0.9),
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
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
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
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android, color: Colors.white.withOpacity(0.9)),
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
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            ],
          ),
          const SizedBox(height: 16),
          const _NotificationItem(
            message: 'Your document is ready for pickup',
            tag: 'New',
            tagColor: Color(0xFFFF8B2E),
          ),
          const SizedBox(height: 12),
          const _NotificationItem(
            message: 'Payment deadline is tomorrow',
            tag: 'Important',
            tagColor: Color(0xFFEE3E4F),
          ),
          const SizedBox(height: 12),
          const _NotificationItem(
            message: 'Community Clean-Up Drive',
            tag: 'Info',
            tagColor: Color(0xFF1F85D5),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.message,
    required this.tag,
    required this.tagColor,
  });

  final String message;
  final String tag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: TextStyle(fontWeight: FontWeight.w600, color: tagColor),
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
              color: Colors.black.withOpacity(0.04),
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _activityStream() {
    final collection = FirebaseFirestore.instance.collection('Requests');
    if (userId == null) {
      return collection
          .orderBy('submittedAt', descending: true)
          .limit(3)
          .snapshots();
    }
    return collection.where('userId', isEqualTo: userId).snapshots();
  }

  DateTime _submittedAt(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data()['submittedAt'];
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'ready':
      case 'ready for pickup':
        return const Color(0xFF3DBE8B);
      case 'processing':
      case 'submitted':
        return const Color(0xFFF1C850);
      default:
        return const Color(0xFF7A8193);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'ready':
      case 'ready for pickup':
        return 'Ready for Pickup';
      case 'processing':
        return 'Processing';
      default:
        return 'Submitted';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (diff.inDays >= 1) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    } else if (diff.inHours >= 1) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    } else if (diff.inMinutes >= 1) {
      return diff.inMinutes == 1
          ? '1 minute ago'
          : '${diff.inMinutes} minutes ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SectionHeader(title: 'Recent Activity', actionLabel: 'View All'),
          SizedBox(height: 16),
          _EmptyActivityCard(message: 'Sign in to see your activity.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Recent Activity', actionLabel: 'View All'),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _activityStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const _EmptyActivityCard(
                message: 'Unable to load recent activity.',
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const _EmptyActivityCard(
                message: 'No activity yet. Submit a request to see it here.',
              );
            }

            final sorted = [...docs]
              ..sort(
                (a, b) => _submittedAt(b).compareTo(_submittedAt(a)),
              );
            final recent = sorted.take(3).toList();

            return Column(
              children: recent.map((doc) {
                final data = doc.data();
                final status = (data['status'] ?? 'submitted').toString();
                final submittedAt = _submittedAt(doc);
                final subtitle =
                    (data['documentType'] ?? 'Document').toString();
                final purpose = data['purpose']?.toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActivityItem(
                    title: subtitle,
                    subtitle: purpose ?? 'No details provided',
                    timeAgo: _timeAgo(submittedAt),
                    status: _statusLabel(status),
                    statusColor: _statusColor(status),
                  ),
                );
              }).toList(),
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
            color: Colors.black.withOpacity(0.04),
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
  });

  final String title;
  final String subtitle;
  final String timeAgo;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: const Color(0xFFE8F3FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: Color(0xFF1F85D5),
            ),
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
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              status,
              style: TextStyle(fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel});

  final String title;
  final String? actionLabel;

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
            onPressed: () {},
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
