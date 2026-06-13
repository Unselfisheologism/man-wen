import 'package:flutter/material.dart';

/// Big-number "Current Streak" display. Flat surface, no gradient —
/// matches the rest of the app's design language. Big editorial
/// typography, single accent rule on the left edge for hierarchy.
class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC), // pink.shade50 equivalent, flat
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: color.primary, width: 4),
          top: BorderSide(color: Colors.black.withOpacity(0.06)),
          right: BorderSide(color: Colors.black.withOpacity(0.06)),
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT STREAK',
            style: TextStyle(
              color: color.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '0',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  height: 1,
                  letterSpacing: -2,
                  // Explicit dark — the surface is always a light pink, so
                  // default theme text would be white in dark mode and
                  // disappear into the background.
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.black.withOpacity(0.08)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCell(label: 'Best', value: '0', context: context),
              ),
              Container(width: 1, height: 32, color: Colors.black.withOpacity(0.08)),
              Expanded(
                child: _StatCell(label: 'Relapses', value: '0', context: context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;
  const _StatCell({required this.label, required this.value, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            // Same reasoning as the big '0' — explicit dark on the
            // always-light-pink surface.
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
