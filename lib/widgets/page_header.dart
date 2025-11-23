import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF122142),
    );

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF122142),
        ),
        Expanded(
          child: Center(
            child: Text(title, textAlign: TextAlign.center, style: textStyle),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}
