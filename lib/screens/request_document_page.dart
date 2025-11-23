import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import 'request_details_page.dart';
import 'request_submitted_page.dart';

class RequestDocumentPage extends StatefulWidget {
  const RequestDocumentPage({super.key});

  @override
  State<RequestDocumentPage> createState() => _RequestDocumentPageState();
}

class _RequestDocumentPageState extends State<RequestDocumentPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final List<String> _documentTypes = [
    'Barangay Clearance',
    'Business Permit',
    'Residency Certificate',
  ];
  String? _selectedDoc;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  String _generateRequestId() {
    final now = DateTime.now();
    final sequence = (now.millisecondsSinceEpoch % 1000000).toString().padLeft(
      6,
      '0',
    );
    return '#DOC-${now.year}-$sequence';
  }

  Future<void> _submitRequest() async {
    final name = _nameController.text.trim();
    final purpose = _purposeController.text.trim();

    if (name.isEmpty || purpose.isEmpty || _selectedDoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final requestId = _generateRequestId();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      await _firestore.collection('Requests').doc(requestId).set({
        'requestId': requestId,
        'fullName': name,
        'documentType': _selectedDoc,
        'purpose': purpose,
        'status': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
        if (userId != null) 'userId': userId,
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequestSubmittedPage(requestId: requestId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF1F1F1F),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Request Document',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressCard(),
              const SizedBox(height: 20),
              _FormSection(
                nameController: _nameController,
                purposeController: _purposeController,
                selectedDoc: _selectedDoc,
                documentTypes: _documentTypes,
                onDocChanged: (value) => setState(() => _selectedDoc = value),
              ),
              const SizedBox(height: 20),
              const _ProcessingFeeCard(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6FE3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 6,
                  ),
                  onPressed: _isSubmitting ? null : _submitRequest,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send_outlined, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _RecentRequests(userId: currentUserId),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onItemSelected: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      const _ProgressStep(
        icon: Icons.send_outlined,
        label: 'Submit',
        active: true,
      ),
      const _ProgressStep(icon: Icons.access_time, label: 'Process'),
      const _ProgressStep(icon: Icons.inventory_2_outlined, label: 'Ready'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Progress',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isEven) {
                return Expanded(child: steps[index ~/ 2]);
              } else {
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFFE0E6F0),
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF1F6FE3) : const Color(0xFFB8C5D9);

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.12) : const Color(0xFFF3F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.nameController,
    required this.purposeController,
    required this.selectedDoc,
    required this.documentTypes,
    required this.onDocChanged,
  });

  final TextEditingController nameController;
  final TextEditingController purposeController;
  final String? selectedDoc;
  final List<String> documentTypes;
  final ValueChanged<String?> onDocChanged;

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE0E6F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF1F6FE3)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Information',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Full Name',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF555E6C),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: _fieldDecoration('Enter your full name'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Document Type',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF555E6C),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedDoc,
            items: documentTypes
                .map((doc) => DropdownMenuItem(value: doc, child: Text(doc)))
                .toList(),
            decoration: _fieldDecoration('Select document type'),
            onChanged: onDocChanged,
          ),
          const SizedBox(height: 18),
          const Text(
            'Purpose',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF555E6C),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: purposeController,
            maxLines: 3,
            decoration: _fieldDecoration(
              'State the purpose of your request...',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingFeeCard extends StatelessWidget {
  const _ProcessingFeeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBDD8FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.info_outline, color: Color(0xFF1F6FE3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Processing Fee',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Most documents have a processing fee of ₱50-200. You\'ll be notified of the exact amount after review.',
                  style: TextStyle(color: Color(0xFF4A5A73), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRequests extends StatelessWidget {
  const _RecentRequests({required this.userId});

  final String? userId;

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestStream() {
    final collection = FirebaseFirestore.instance.collection('Requests');
    if (userId == null) {
      return collection
          .orderBy('submittedAt', descending: true)
          .limit(5)
          .snapshots();
    }
    // Equality filters do not need an index when we avoid composite ordering,
    // so we fetch everything for the user and sort client-side.
    return collection.where('userId', isEqualTo: userId).snapshots();
  }

  Timestamp _timestampForDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final raw = doc.data()['submittedAt'];
    if (raw is Timestamp) {
      return raw;
    }
    return Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(0));
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _takeRecent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (userId == null) {
      return docs;
    }
    final sorted = [...docs]
      ..sort(
        (a, b) => _timestampForDoc(b).compareTo(_timestampForDoc(a)),
      );
    return sorted.take(5).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
      case 'ready for pickup':
        return const Color(0xFF49C178);
      case 'processing':
        return const Color(0xFFE5B546);
      default:
        return const Color(0xFF9AA3B9);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _requestStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Unable to load requests right now.'),
            );
          }

          final docs = _takeRecent(snapshot.data?.docs ?? []);
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No requests yet. Submit a request to see it here.',
                style: TextStyle(color: Color(0xFF7A8193)),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Requests',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 16),
              ...docs.map((doc) {
                final data = doc.data();
                final status = (data['status'] ?? 'submitted').toString();
                final Timestamp? ts = data['submittedAt'] as Timestamp?;
                final submittedAt = ts?.toDate() ?? DateTime.now();
                final purposeText = (data['purpose'] ?? 'No details')
                    .toString();
                final detailPayload = Map<String, dynamic>.from(data)
                  ..putIfAbsent('requestId', () => doc.id)
                  ..putIfAbsent('submittedAt', () => ts);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecentRequestTile(
                    title: (data['documentType'] ?? 'Document').toString(),
                    subtitle: '$purposeText · ${_timeAgo(submittedAt)}',
                    status: _statusLabel(status),
                    statusColor: _statusColor(status),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RequestDetailsPage(
                            data: detailPayload,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _RecentRequestTile extends StatelessWidget {
  const _RecentRequestTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.description_outlined, color: statusColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF7A8193)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                status,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
