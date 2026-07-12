import 'package:flutter/material.dart';

class AppDecorations {
  static BoxDecoration skeuomorphicCard({
    Color color = Colors.white,
    double radius = 16,
    bool pressed = false,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE7EBF2), width: 1.2),
      boxShadow: pressed
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(1, 1),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                offset: const Offset(-1, -1),
                blurRadius: 4,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                offset: const Offset(0, 12),
                blurRadius: 24,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                offset: const Offset(-4, -4),
                blurRadius: 18,
              ),
            ],
    );
  }

  static BoxDecoration softPanel({
    Color color = Colors.white,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE8EDF5), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          offset: const Offset(0, 12),
          blurRadius: 24,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.92),
          offset: const Offset(-5, -5),
          blurRadius: 18,
        ),
      ],
    );
  }
}
