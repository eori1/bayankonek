import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
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

  @override
  Widget build(BuildContext context) {
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
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6FE3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    final requestId = _generateRequestId();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            RequestSubmittedPage(requestId: requestId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_outlined, color: Colors.white),
                  label: const Text(
                    'Submit Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _RecentRequests(),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _ProgressStep(
                icon: Icons.send_outlined,
                label: 'Submit',
                active: true,
              ),
              _ProgressDivider(),
              _ProgressStep(icon: Icons.access_time, label: 'Process'),
              _ProgressDivider(),
              _ProgressStep(icon: Icons.inventory_2_outlined, label: 'Ready'),
            ],
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
            color: active ? color.withOpacity(0.1) : const Color(0xFFF3F5F9),
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

class _ProgressDivider extends StatelessWidget {
  const _ProgressDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 32, height: 2, color: const Color(0xFFE0E6F0));
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
            value: selectedDoc,
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
  const _RecentRequests();

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
        children: const [
          Text(
            'Recent Requests',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          SizedBox(height: 16),
          _RecentRequestTile(
            title: 'Barangay Clearance',
            subtitle: 'For employment · 2 days ago',
            status: 'Ready for Pickup',
            statusColor: Color(0xFF49C178),
            icon: Icons.check_circle_outline,
          ),
          SizedBox(height: 12),
          _RecentRequestTile(
            title: 'Business Permit',
            subtitle: 'For sari-sari store · 1 week ago',
            status: 'Processing',
            statusColor: Color(0xFFE5B546),
            icon: Icons.timelapse,
          ),
        ],
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
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Icon(icon, color: statusColor),
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
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
