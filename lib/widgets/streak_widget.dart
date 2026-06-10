import 'package:flutter/material.dart';

class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.pink, Colors.deepPurple]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Streak', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('0', style: TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(label: const Text('Best: 0'), backgroundColor: Colors.white24),
              const SizedBox(width: 12),
              Chip(label: const Text('Relapses: 0'), backgroundColor: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }
}
