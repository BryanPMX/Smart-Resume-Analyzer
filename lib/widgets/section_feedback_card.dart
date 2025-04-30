import 'package:flutter/material.dart';

/// A card that presents the analysis of a single resume section,
/// including the achieved score, suggestions, and any extracted keywords or skills.
class SectionFeedbackCard extends StatelessWidget {
  /// Section name (e.g., "Experience", "Skills", "Education").
  final String title;

  /// The number of points earned in this section.
  final int score;

  /// List of improvement suggestions or feedback tips.
  final List<String> suggestions;

  /// Optional list of related skills or keywords to display as chips.
  final List<String>? skills;

  /// Maximum possible points for this section.
  final int maxScore;

  const SectionFeedbackCard({
    super.key,
    required this.title,
    required this.score,
    required this.suggestions,
    this.skills,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = maxScore > 0 ? score / maxScore : 0.0;
    final progressColor = Color.lerp(Colors.red, Colors.green, ratio)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title and numeric score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score / $maxScore',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Horizontal progress bar indicating relative performance
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(progressColor),
                semanticsLabel: '$title score: $score out of $maxScore',
              ),
            ),
            const SizedBox(height: 12),

            // Suggestions list
            ...suggestions.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Optional skill/keyword chips
            if (skills != null && skills!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: skills!.map((label) {
                  return Chip(
                    label: Text(label),
                    backgroundColor: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
