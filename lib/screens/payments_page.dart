import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'payment_receipt_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  static const _feeDocumentTypes = [
    'Residency Certificate',
    'Barangay Clearance',
    'Business Permit',
  ];
  final _firestore = FirebaseFirestore.instance;
  String? _processingRequestId;

  String _generateReferenceNumber() {
    final now = DateTime.now();
    final unique = now.millisecondsSinceEpoch.toString().substring(6);
    return 'GC-${now.year}-$unique';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingFees(String userId) {
    return _firestore
        .collection('Requests')
        .where('userId', isEqualTo: userId)
        .where('documentType', whereIn: _feeDocumentTypes)
        .where('status', isEqualTo: 'payment_pending')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _recentPayments(String userId) {
    return _firestore
        .collection('Payments')
        .where('userId', isEqualTo: userId)
        .orderBy('paidAt', descending: true)
        .limit(5)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _payRequest(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final docData = doc.data() ?? {};
    final amount =
        (docData['paymentAmount'] as num?)?.toDouble() ??
        (docData['amountDue'] as num?)?.toDouble() ??
        0;
    final userId = docData['userId']?.toString();
    final payerName = docData['fullName']?.toString() ?? 'Citizen';
    setState(() => _processingRequestId = doc.id);
    try {
      await doc.reference.update({
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'amountDue': 0,
        'status': 'processing',
      });

      final paymentPayload = {
        'requestId': doc.id,
        'userId': userId,
        'referenceNumber': _generateReferenceNumber(),
        'documentType': docData['documentType'],
        'purpose': docData['purpose'],
        'paymentAmount': amount,
        'paidAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'GCash',
        'status': 'confirmed',
        'payerName': payerName,
        'payerContact': FirebaseAuth.instance.currentUser?.phoneNumber ??
            docData['contactNumber'],
      };
      final paymentRef =
          await _firestore.collection('Payments').add(paymentPayload);

      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment received for ${doc.id}. Preparing document...'),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      await doc.reference.update({'status': 'ready'});
      return await paymentRef.get();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _processingRequestId = null);
      }
    }
  }

  Future<void> _startPaymentFlow(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data() ?? {};
    final amount = (data['amountDue'] as num?)?.toDouble() ??
        (data['paymentAmount'] as num?)?.toDouble() ??
        0;
    final documentType = data['documentType']?.toString() ?? 'Document Fee';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GcashDialog(
        documentType: documentType,
        amount: amount,
      ),
    );

    if (confirmed == true) {
      final paymentDoc = await _payRequest(doc);
      if (!mounted) return;
      if (paymentDoc != null && paymentDoc.data() != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentReceiptPage(paymentData: paymentDoc.data()!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return _PaymentsScaffold(
        embedded: widget.embedded,
        child: const Center(
          child: Text('Sign in to view and pay your fees.'),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pendingFees(userId),
      builder: (context, pendingSnapshot) {
        if (pendingSnapshot.connectionState == ConnectionState.waiting) {
          return _PaymentsScaffold(
            embedded: widget.embedded,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final pendingDocs = pendingSnapshot.data?.docs ?? [];
        final totalDue = pendingDocs.fold<double>(
          0,
          (runningTotal, doc) =>
              runningTotal + ((doc.data()['amountDue'] as num?)?.toDouble() ?? 0),
        );
        final dueSoon = pendingDocs.fold<double>(0, (runningTotal, doc) {
          final ts = doc.data()['paymentDueDate'];
          final date = ts is Timestamp ? ts.toDate() : null;
          if (date != null &&
              date.isBefore(DateTime.now().add(const Duration(days: 7)))) {
            return runningTotal +
                ((doc.data()['amountDue'] as num?)?.toDouble() ?? 0);
          }
          return runningTotal;
        });

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _recentPayments(userId),
          builder: (context, recentSnapshot) {
            final recentDocs = recentSnapshot.data?.docs ?? [];

            return _PaymentsScaffold(
              embedded: widget.embedded,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BalanceCard(
                      totalDue: totalDue,
                      pendingCount: pendingDocs.length,
                      dueSoonAmount: dueSoon,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Fees Due'),
                    const SizedBox(height: 12),
                    if (pendingDocs.isEmpty)
                      const _EmptyState(message: 'No pending fees at the moment.')
                    else
                      Column(
                        children: pendingDocs
                            .map(
                              (doc) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _FeeCard(
                                  doc: doc,
                                  isProcessing: _processingRequestId == doc.id,
                                  onPay: () => _startPaymentFlow(doc),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 8),
                    const _SectionTitle(title: 'Recent Payments'),
                    const SizedBox(height: 12),
                    if (recentDocs.isEmpty)
                      const _EmptyState(message: 'No payments recorded yet.')
                    else
                      Column(
                        children: recentDocs
                            .map(
                              (doc) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RecentPaymentCard(doc: doc),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentsScaffold extends StatelessWidget {
  const _PaymentsScaffold({required this.embedded, required this.child});

  final bool embedded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return ColoredBox(
        color: const Color(0xFFF5F6FA),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Payments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F1F),
                      ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF1F1F1F),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Payments',
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: child,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.totalDue,
    required this.pendingCount,
    required this.dueSoonAmount,
  });

  final double totalDue;
  final int pendingCount;
  final double dueSoonAmount;

  @override
  Widget build(BuildContext context) {
    String peso(double value) => '₱${value.toStringAsFixed(2)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F75FF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F75FF).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Total Balance Due',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            peso(totalDue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pendingCount payment${pendingCount == 1 ? '' : 's'} pending',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _BalanceStatCard(label: 'Due Soon', value: peso(dueSoonAmount)),
              const SizedBox(width: 12),
              _BalanceStatCard(label: 'This Month', value: '$pendingCount'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStatCard extends StatelessWidget {
  const _BalanceStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F1F1F),
          ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({
    required this.doc,
    required this.isProcessing,
    required this.onPay,
  });

  final DocumentSnapshot<Map<String, dynamic>> doc;
  final bool isProcessing;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final amountDue = (data['amountDue'] as num?)?.toDouble() ?? 0;
    final dueTs = data['paymentDueDate'];
    final dueDate = dueTs is Timestamp ? dueTs.toDate() : null;
    final dueLabel =
        dueDate != null ? DateFormat('MMM d, yyyy').format(dueDate) : '—';
    final status = (data['status'] as String?)?.toLowerCase() ?? 'payment_pending';
    final statusLabel =
        status == 'payment_pending' ? 'Due' : status == 'processing' ? 'Processing' : 'Ready';
    final statusColor = status == 'payment_pending'
        ? const Color(0xFFEB5757)
        : status == 'processing'
            ? const Color(0xFFF1C40F)
            : const Color(0xFF27AE60);
    final canPay = status == 'payment_pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    const Icon(Icons.description_outlined, color: Color(0xFF1F75FF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['documentType'] ?? 'Residency Certificate',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '₱${amountDue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['purpose'] ?? 'Residency certification fee',
                      style: const TextStyle(
                        color: Color(0xFF6B6F7F),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Due: $dueLabel',
                          style: const TextStyle(
                            color: Color(0xFF9AA3B9),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !canPay || isProcessing ? null : onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canPay ? const Color(0xFF1F75FF) : const Color(0xFFE7EBF6),
                foregroundColor:
                    canPay ? Colors.white : const Color(0xFF7A8193),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Pay with GCash',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GcashDialog extends StatelessWidget {
  const _GcashDialog({required this.documentType, required this.amount});

  final String documentType;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final amountLabel = '₱${amount.toStringAsFixed(2)}';
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE6EEFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smartphone, color: Color(0xFF1063FF), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pay with GCash',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Secure payment processing',
              style: TextStyle(color: Color(0xFF7A8193)),
            ),
            const SizedBox(height: 24),
            _PaymentDetailTile(label: 'Payment for', value: documentType),
            const SizedBox(height: 12),
            _PaymentDetailTile(label: 'Amount', value: amountLabel),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F75FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF5A5F6F),
                    fontWeight: FontWeight.w600,
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

class _PaymentDetailTile extends StatelessWidget {
  const _PaymentDetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8A92A6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPaymentCard extends StatelessWidget {
  const _RecentPaymentCard({required this.doc});

  final DocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final amount = (data['paymentAmount'] as num?)?.toDouble() ?? 0;
    final paidTs = data['paidAt'];
    final paidDate = paidTs is Timestamp ? paidTs.toDate() : null;
    final paidLabel =
        paidDate != null ? DateFormat('MMM d, yyyy').format(paidDate) : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.sticky_note_2_outlined,
                color: Color(0xFF27AE60)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['documentType']?.toString() ?? 'Document Fee',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['purpose']?.toString() ?? 'Barangay service payment',
                  style: const TextStyle(
                    color: Color(0xFF6B6F7F),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paid: $paidLabel',
                  style: const TextStyle(
                    color: Color(0xFF9AA3B9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Paid',
                  style: TextStyle(
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
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

