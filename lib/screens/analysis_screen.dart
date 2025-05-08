import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/resume_provider.dart';
import '../widgets/section_feedback_card.dart';

/// After the upload‐screen has performed scanning and analysis,
/// this screen simply reveals the final results with smooth animations.
class AnalysisScreen extends StatefulWidget {
  /// Creates an [AnalysisScreen].
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ResumeViewModel>();
    final resume = viewModel.resume;

    // If resume data hasn't arrived yet, show a spinner.
    if (resume == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final sections = resume.sectionBreakdown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _revealController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Complete!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: ${resume.score}/100',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Section-by-section feedback cards
                if (sections.isEmpty)
                  Text(
                    'No section analysis available.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey),
                  )
                else ...[
                  for (var s in sections)
                    SectionFeedbackCard(
                      title: s.sectionName,
                      score: s.achievedScore,
                      maxScore: s.maxScore,
                      suggestions: s.feedback,
                      skills: s.matchedContent,
                    ),
                ],

                const SizedBox(height: 32),
                Text(
                  'Final Suggestions',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Final feedback bullet list
                if (resume.feedback.isEmpty)
                  Text(
                    'No final suggestions available.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey),
                  )
                else ...[
                  for (var tip in resume.feedback)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              tip,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

