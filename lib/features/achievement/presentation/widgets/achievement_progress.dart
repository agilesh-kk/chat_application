import 'package:flutter/material.dart';
import '../../domain/entity/achievement.dart';

class AchievementProgress extends StatelessWidget {
  final Achievement data;

  const AchievementProgress({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = data.percentage.clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Level Title
          Text(
            data.level,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // 📊 Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 8),

          // 📊 Percentage Text
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${percentage.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}