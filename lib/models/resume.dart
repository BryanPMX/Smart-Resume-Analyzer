import 'dart:developer' as developer;
import 'dart:io';
import 'section_score.dart';

/// Represents a fully parsed and scored resume, containing the raw text, parsed sections,
/// scoring results, and feedback. Used as the primary data model for the resume analysis pipeline.
class Resume {
  /// Maximum text length to process, aligned with `ScoringService` and `MajorDetector`.
  static const int _maxTextLength = 100 * 1024; // 100 KB

  final String fileName;
  final String fullText;
  final File? file; // Add file field to store the original file
  final String? major;
  final int score;
  final List<String> feedback;
  final List<SectionScore> sectionBreakdown;
  final Map<String, String> parsedSections;
  final Map<String, int> sectionOffsets;

  /// Creates a new `Resume` instance with the provided fields.
  ///
  /// [fileName] The name of the resume file.
  /// [fullText] The full text content of the resume.
  /// [file] The original file (PDF or image) of the resume.
  /// [major] The detected academic major, typically set by `ScoringService`.
  /// [score] The overall score (0–100), computed by `ScoringService`.
  /// [feedback] A list of feedback messages, populated by `ScoringService`.
  /// [sectionBreakdown] A list of per-section scores and feedback, populated by `ScoringService`.
  /// [parsedSections] A map of section names to their raw text content, populated by `SectionDetectorService`.
  /// [sectionOffsets] A map of section names to their starting offsets in `fullText`, populated by `SectionDetectorService`.
  /// [enableLogging] If true, logs validation errors for debugging (default: false).
  ///
  /// Throws:
  /// - [ArgumentError] If [fileName] or [fullText] is empty, or if [fullText] exceeds the maximum length.
  Resume({
    required this.fileName,
    required this.fullText,
    this.file,
    this.major,
    this.score = 0,
    List<String>? feedback,
    List<SectionScore>? sectionBreakdown,
    Map<String, String>? parsedSections,
    Map<String, int>? sectionOffsets,
    bool enableLogging = false,
  })  : feedback = feedback ?? [],
        sectionBreakdown = sectionBreakdown ?? [],
        parsedSections = parsedSections ?? {},
        sectionOffsets = sectionOffsets ?? {} {
    // Validate inputs
    if (fileName.isEmpty) {
      if (enableLogging) {
        developer.log('Validation Error: fileName cannot be empty');
      }
      throw ArgumentError('fileName cannot be empty');
    }
    if (fullText.isEmpty) {
      if (enableLogging) {
        developer.log('Validation Error: fullText cannot be empty');
      }
      throw ArgumentError('fullText cannot be empty');
    }
    if (fullText.length > _maxTextLength) {
      if (enableLogging) {
        developer.log('Validation Error: fullText exceeds maximum length of $_maxTextLength characters');
      }
      throw ArgumentError('fullText exceeds maximum length of $_maxTextLength characters');
    }
  }

  /// Creates an empty `Resume` instance with default values.
  factory Resume.empty() => Resume(fileName: 'empty_resume', fullText: ' ');

  /// Creates a copy of this `Resume` with the specified fields updated.
  ///
  /// Returns a new `Resume` instance with the updated values, ensuring immutability.
  /// Performs a defensive copy of lists and maps to prevent unintended modifications.
  Resume copyWith({
    String? fileName,
    String? fullText,
    File? file,
    String? major,
    int? score,
    List<String>? feedback,
    List<SectionScore>? sectionBreakdown,
    Map<String, String>? parsedSections,
    Map<String, int>? sectionOffsets,
    bool enableLogging = false,
  }) {
    return Resume(
      fileName: fileName ?? this.fileName,
      fullText: fullText ?? this.fullText,
      file: file ?? this.file,
      major: major ?? this.major,
      score: score ?? this.score,
      feedback: feedback != null ? List<String>.from(feedback) : List<String>.from(this.feedback),
      sectionBreakdown: sectionBreakdown != null
          ? List<SectionScore>.from(sectionBreakdown)
          : List<SectionScore>.from(this.sectionBreakdown),
      parsedSections: parsedSections != null
          ? Map<String, String>.from(parsedSections)
          : Map<String, String>.from(this.parsedSections),
      sectionOffsets: sectionOffsets != null
          ? Map<String, int>.from(sectionOffsets)
          : Map<String, int>.from(this.sectionOffsets),
      enableLogging: enableLogging,
    );
  }

  @override
  String toString() =>
      'Resume(fileName: $fileName, score: $score, major: $major)';
}
