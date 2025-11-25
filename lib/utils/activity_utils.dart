import 'package:flutter/material.dart';

String formatTimeAgo(DateTime date) {
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

Color requestStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'ready':
    case 'ready for pickup':
      return const Color(0xFF3DBE8B);
    case 'processing':
    case 'submitted':
      return const Color(0xFFF1C850);
    case 'payment_pending':
      return const Color(0xFFEE3E4F);
    default:
      return const Color(0xFF7A8193);
  }
}

String requestStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return 'Completed';
    case 'ready':
    case 'ready for pickup':
      return 'Ready for Pickup';
    case 'processing':
      return 'Processing';
    case 'payment_pending':
      return 'Pending Payment';
    default:
      return 'Submitted';
  }
}

Color issueStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'resolved':
    case 'completed':
      return const Color(0xFF3DBE8B);
    case 'in_progress':
      return const Color(0xFFFFA63F);
    case 'under_review':
    case 'approved':
      return const Color(0xFF4C8DFF);
    default:
      return const Color(0xFF7A8193);
  }
}

String issueStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'resolved':
    case 'completed':
      return 'Resolved';
    case 'in_progress':
      return 'In Progress';
    case 'under_review':
      return 'Under Review';
    case 'approved':
      return 'Approved';
    default:
      return 'Submitted';
  }
}

Color paymentStatusColor(String status) => const Color(0xFF30C38C);

String paymentStatusLabel(String status) => 'Completed';
