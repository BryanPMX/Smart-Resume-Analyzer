/// Model representing the evaluation result of a specific section in the resume.
class SectionScore {
  /// Name of the resume section (e.g., "Experience", "Skills", "Education").
  final String sectionName;

  /// Maximum possible points for this section.
  final int maxScore;

  /// Actual score assigned during evaluation.
  final int achievedScore;

  /// List of feedback tips or suggestions related to this section.
  final List<String> feedback;

  /// Optional list of matched keywords, skills, or items in the section.
  final List<String>? matchedContent;

  /// Optional raw block of text extracted from the resume for this section.
  final String? rawContent;

  /// Constructs a new [SectionScore] instance.
  SectionScore({
    required this.sectionName,
    required this.maxScore,
    required this.achievedScore,
    required this.feedback,
    this.matchedContent,
    this.rawContent,
  });

  /// Returns true if this section earned full points.
  bool get isPerfectScore => achievedScore >= maxScore;

  /// Returns true if this section earned no points.
  bool get isEmpty => achievedScore == 0;

  /// Returns a normalized score out of 100 for visualization or analytics.
  double get normalized => maxScore > 0 ? (achievedScore / maxScore) * 100 : 0;

  @override
  String toString() => '$sectionName: $achievedScore/$maxScore';

  /// Creates a copy of the current score with optional overrides.
  SectionScore copyWith({
    String? sectionName,
    int? maxScore,
    int? achievedScore,
    List<String>? feedback,
    List<String>? matchedContent,
    String? rawContent,
  }) {
    return SectionScore(
      sectionName: sectionName ?? this.sectionName,
      maxScore: maxScore ?? this.maxScore,
      achievedScore: achievedScore ?? this.achievedScore,
      feedback: feedback ?? this.feedback,
      matchedContent: matchedContent ?? this.matchedContent,
      rawContent: rawContent ?? this.rawContent,
    );
  }
}

