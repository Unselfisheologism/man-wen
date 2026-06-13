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
          // 7-day progress bar — 7 equal segments
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: AppTheme.rule,
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
