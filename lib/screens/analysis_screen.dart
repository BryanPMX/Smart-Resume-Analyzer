// analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/resume_provider.dart';
import '../widgets/scanning_animation.dart';
import '../widgets/section_feedback_card.dart';

/// Screen that runs a scanning animation with a resume preview, then reveals detailed analysis results.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _revealController;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    // 3s scanning animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward().whenComplete(() {
      setState(() => _isAnalyzing = false);
      _revealController.forward();
    });

    // Reveal controller for fade/slide transitions
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resume = context.watch<ResumeViewModel>().resume;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzing Resume'),
        elevation: 0,
      ),
      body: _isAnalyzing
          ? Stack(
        children: [
          ResumePreview(text: resume.fullText),
          ScanningAnimation(controller: _scanController),
        ],
      )
          : FadeTransition(
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
                ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _revealController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Text(
                    'Score: ${resume.score}/100',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section cards: slide in one by one
                for (var i = 0; i < resume.sectionBreakdown.length; i++)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _revealController,
                        curve: Interval(
                          0.2 + i * 0.1,
                          1.0,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: SectionFeedbackCard(
                      title: resume.sectionBreakdown[i].sectionName,
                      score: resume.sectionBreakdown[i].achievedScore,
                      maxScore: resume.sectionBreakdown[i].maxScore,
                      suggestions: resume.sectionBreakdown[i].feedback,
                      skills: resume.sectionBreakdown[i].matchedContent,
                    ),
                  ),

                const SizedBox(height: 32),
                Text(
                  'Final Suggestions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Final feedback bullets: fade in staggered
                for (var i = 0; i < resume.feedback.length; i++)
                  FadeTransition(
                    opacity: Tween(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _revealController,
                        curve: Interval(
                          0.6 + i * 0.05,
                          1.0,
                          curve: Curves.easeIn,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              resume.feedback[i],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget that displays a preview of the raw resume text with a subtle background.
class ResumePreview extends StatelessWidget {
  final String text;

  const ResumePreview({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Clean text by removing section markers
    final cleanedText = text.replaceAll(RegExp(r'==SECTION==.*?\n|==PAGE_BREAK==\n'), '').trim();

    return Container(
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // Lock scrolling during animation
        padding: const EdgeInsets.all(24),
        child: Text(
          cleanedText.isEmpty ? 'No content available' : cleanedText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
