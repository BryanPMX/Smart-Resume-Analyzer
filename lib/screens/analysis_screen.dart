// analysis_screen.dart
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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

    // No need to filter for null since sectionBreakdown elements are non-nullable
    final validSections = resume.sectionBreakdown.asMap().entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzing Resume'),
        elevation: 0,
      ),
      body: _isAnalyzing
          ? Stack(
        children: [
          ResumePreview(file: resume.file),
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
                if (validSections.isEmpty)
                  const Text(
                    'No section analysis available.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  )
                else
                  for (var entry in validSections)
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _revealController,
                          curve: Interval(
                            0.2 + entry.key * 0.1,
                            1.0,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: SectionFeedbackCard(
                        title: entry.value.sectionName,
                        score: entry.value.achievedScore,
                        maxScore: entry.value.maxScore,
                        suggestions: entry.value.feedback,
                        skills: entry.value.matchedContent,
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

/// Stateful widget to handle resume preview with error states.
class ResumePreview extends StatefulWidget {
  final File? file;

  const ResumePreview({super.key, required this.file});

  @override
  ResumePreviewState createState() => ResumePreviewState();
}

/// State class for ResumePreview, managing error states.
class ResumePreviewState extends State<ResumePreview> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (widget.file == null) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Text(
            'No file available for preview',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    final isPdf = widget.file!.path.toLowerCase().endsWith('.pdf');

    return Container(
      color: Colors.grey.shade100,
      child: _error != null
          ? Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : isPdf
          ? PDFView(
        filePath: widget.file!.path,
        enableSwipe: false, // Disable swipe during animation
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: false,
        onError: (error) {
          developer.log('PDF rendering error: $error');
          setState(() {
            _error = 'Error loading PDF: $error';
          });
        },
        onRender: (pages) {
          debugPrint('PDF rendered with $pages pages');
        },
      )
          : Image.file(
        widget.file!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          developer.log('Image rendering error: $error');
          return Center(
            child: Text(
              'Error loading image',
              style: const TextStyle(color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
