import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentReceiptPage extends StatelessWidget {
  const PaymentReceiptPage({super.key, required this.paymentData});

  final Map<String, dynamic> paymentData;

  double get _amount =>
      (paymentData['paymentAmount'] as num?)?.toDouble() ??
      (paymentData['amountDue'] as num?)?.toDouble() ??
      0;

  String get _referenceNumber =>
      paymentData['referenceNumber']?.toString() ??
      paymentData['requestId']?.toString() ??
      '—';

  String get _documentType =>
      paymentData['documentType']?.toString() ?? 'Document Fee';

  String get _purpose =>
      paymentData['purpose']?.toString() ?? 'Barangay service payment';

  String get _payerName =>
      paymentData['payerName']?.toString() ?? 'Citizen';

  String get _payerContact =>
      paymentData['payerContact']?.toString() ?? 'Unavailable';

  DateTime get _paidAt {
    final raw = paymentData['paidAt'];
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    return DateTime.now();
  }

  String get _statusLabel => paymentData['status']?.toString() ?? 'Confirmed';

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final amountLabel = '₱${_amount.toStringAsFixed(2)}';
    final paidDateLabel = _formatDate(_paidAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Payment Receipt',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SuccessCard(statusLabel: _statusLabel),
              const SizedBox(height: 16),
              _TotalAmountCard(amountLabel: amountLabel),
              const SizedBox(height: 16),
              _TransactionDetailsCard(
                referenceId: _referenceNumber,
                paidDateLabel: paidDateLabel,
                statusLabel: _statusLabel,
              ),
              const SizedBox(height: 16),
              _BreakdownCard(
                documentType: _documentType,
                purpose: _purpose,
                amountLabel: amountLabel,
              ),
              const SizedBox(height: 16),
              _PaymentInfoCard(
                payerName: _payerName,
                payerContact: _payerContact,
              ),
              const SizedBox(height: 16),
              const _ReminderCard(),
              const SizedBox(height: 24),
              _ReceiptActions(
                onDownload: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Downloading receipt...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature coming soon.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onBack: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.statusLabel});

  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF1F9D5C), size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful!',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your payment has been received',
            style: TextStyle(color: Color(0xFF7A8193)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                color: Color(0xFF1F9D5C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalAmountCard extends StatelessWidget {
  const _TotalAmountCard({required this.amountLabel});

  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F75FF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F75FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Amount Paid',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amountLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Paid via GCash',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailsCard extends StatelessWidget {
  const _TransactionDetailsCard({
    required this.referenceId,
    required this.paidDateLabel,
    required this.statusLabel,
  });

  final String referenceId;
  final String paidDateLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Transaction Details',
      child: Column(
        children: [
          _TwoColumnRow(label: 'Reference Number', value: referenceId),
          const SizedBox(height: 12),
          _TwoColumnRow(label: 'Date & Time', value: paidDateLabel),
          const SizedBox(height: 12),
          const _TwoColumnRow(label: 'Payment Method', value: 'GCash'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A8193),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Color(0xFF1F9D5C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.documentType,
    required this.purpose,
    required this.amountLabel,
  });

  final String documentType;
  final String purpose;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Payment Breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EDFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.description, color: Color(0xFF7F5DF0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      purpose,
                      style: const TextStyle(color: Color(0xFF7A8193)),
                    ),
                  ],
                ),
              ),
              Text(
                amountLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
              Text(
                amountLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard({
    required this.payerName,
    required this.payerContact,
  });

  final String payerName;
  final String payerContact;

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: 'Payment Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'From:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A8193),
            ),
          ),
          const SizedBox(height: 8),
          _ProfileTile(
            title: payerName,
            subtitle: payerContact,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          const Text(
            'To:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A8193),
            ),
          ),
          const SizedBox(height: 8),
          const _ProfileTile(
            title: 'Barangay Treasury',
            subtitle: 'Official Collection Account',
            icon: Icons.account_balance_outlined,
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.event_note_outlined, color: Color(0xFF1F75FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Reminder',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Save this receipt for your records. You can download or print the receipt for future reference.',
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

class _ReceiptActions extends StatelessWidget {
  const _ReceiptActions({
    required this.onDownload,
    required this.onShare,
    required this.onBack,
  });

  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F75FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            label: const Text(
              'Download Receipt',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined),
            label: const Text(
              'Share',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onBack,
            child: const Text(
              'Back to Payments',
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionWrapper extends StatelessWidget {
  const _SectionWrapper({required this.child, this.title});

  final Widget child;
  final String? title;

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
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _TwoColumnRow extends StatelessWidget {
  const _TwoColumnRow({required this.label, required this.value});

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
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A8193),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1F75FF)),
          ),
          const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

