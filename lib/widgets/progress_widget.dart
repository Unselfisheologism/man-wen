import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Protection stats — small editorial data panel. Sits between the
/// streak and the action list. Shows weekly block progress.
class ProgressWidget extends StatelessWidget {
  const ProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.rule, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('THIS WEEK', style: AppTheme.label),
              Text('00/00', style: AppTheme.data),
            ],
          ),
          const SizedBox(height: 12),
          // 7-day progress bar — 7 equal segments, each in a
          // different category color so the week reads as a
          // mini spectrum (matches the user's library grid pattern
          // where each card is its own color).
          Row(
            children: List.generate(7, (i) {
              final colors = [
                AppTheme.catBlocker,
                Color(0xFFC4631F), // amber
                Color(0xFFD4A035), // gold
                Color(0xFF3F6B4F), // forest
                Color(0xFF4A7E9B), // teal
                Color(0xFF2E3D6B), // indigo
                Color(0xFF7A3F6B), // plum
              ];
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: colors[i],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('MO TU WE TH FR SA SU', style: AppTheme.labelSoft),
            ],
          ),
        ],
      ),
    );
  }
}
