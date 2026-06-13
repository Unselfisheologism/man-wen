import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Current streak display — editorial / faded almanac register.
///
/// Composition:
///   - Section header in mono:  "02 // CURRENT STREAK"
///   - Hairline rule below
///   - Big thin sans number, mono "days" suffix
///   - Hairline rule
///   - Two stat cells (Best / Relapses) with mono micro-labels
class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 02 // CURRENT STREAK ──────────────────────────────────
          const SectionHeader(number: '02', label: 'CURRENT STREAK'),
          Container(height: 1, color: AppTheme.rule),
          const SizedBox(height: 12),

          // Colored top-bar accent (matches the catBlocker brick —
          // "streak" is the goal / protection, not a separate category)
          Container(
            height: 4,
            color: AppTheme.catBlocker,
          ),
          const SizedBox(height: 16),

          // The streak number ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text('0', style: AppTheme.display),
              SizedBox(width: 12),
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('DAYS', style: AppTheme.label),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: AppTheme.rule),
          const SizedBox(height: 16),

          // Best / Relapses ──────────────────────────────────────
          Row(
            children: const [
              Expanded(child: _StatCell(label: 'BEST', value: '0')),
              SizedBox(width: 16),
              Expanded(child: _StatCell(label: 'RELAPSES', value: '0')),
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
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.label),
        const SizedBox(height: 6),
        Text(value, style: AppTheme.displaySmall),
      ],
    );
  }
}

/// `01 // LABEL` — the recurring editorial pattern. Mono throughout,
/// uppercase, letter-spaced. Used at the top of every section.
class SectionHeader extends StatelessWidget {
  final String number;
  final String label;
  final String? trailing;

  const SectionHeader({
    super.key,
    required this.number,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$number //',
            style: AppTheme.label.copyWith(color: AppTheme.inkSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: AppTheme.label),
          ),
          if (trailing != null)
            Text(trailing!, style: AppTheme.labelSoft),
        ],
      ),
    );
  }
}
