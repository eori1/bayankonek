import 'package:flutter/widgets.dart';

Route<T> slideFromRight<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero).chain(
        CurveTween(curve: Curves.easeOutCubic),
      );
      final fadeTween = Tween(begin: 0.85, end: 1.0).chain(
        CurveTween(curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(tween),
          child: child,
        ),
      );
    },
  );
}

