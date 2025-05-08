// lib/models/resume.dart

import 'dart:io';
import '../models/section_score.dart';
import '../models/major.dart';

/// Represents a fully parsed and scored resume.
class Resume {
  static const int _maxTextLength = 100 * 1024; // 100 KB

  final String fileName;
  final String fullText;
  final File? file;
  final Major? major;
  final int score;
  final List<String> feedback;
  final List<SectionScore> sectionBreakdown;
  final Map<String, String> parsedSections;
  final Map<String, int> sectionOffsets;

  /// Main constructor, validates [fileName] and [fullText].
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
    if (fileName.isEmpty) {
      if (enableLogging) {
        // ignore: avoid_print
        print('Validation Error: fileName cannot be empty');
      }
      throw ArgumentError('fileName cannot be empty');
    }
    if (fullText.isEmpty) {
      if (enableLogging) {
        // ignore: avoid_print
        print('Validation Error: fullText cannot be empty');
      }
      throw ArgumentError('fullText cannot be empty');
    }
    if (fullText.length > _maxTextLength) {
      if (enableLogging) {
        // ignore: avoid_print
        print('Validation Error: fullText exceeds $_maxTextLength characters');
      }
      throw ArgumentError('fullText exceeds maximum length ($_maxTextLength)');
    }
  }

  /// An “empty” placeholder resume. Uses a single space so it passes validation.
  factory Resume.empty() => Resume(
    fileName: 'empty_resume',
    fullText: ' ',
  );

  /// Creates a copy with updated fields. Runs the same validations.
  Resume copyWith({
    String? fileName,
    String? fullText,
    File? file,
    Major? major,
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
      feedback: feedback != null ? List.from(feedback) : List.from(this.feedback),
      sectionBreakdown: sectionBreakdown != null
          ? List.from(sectionBreakdown)
          : List.from(this.sectionBreakdown),
      parsedSections: parsedSections != null
          ? Map.from(parsedSections)
          : Map.from(this.parsedSections),
      sectionOffsets: sectionOffsets != null
          ? Map.from(sectionOffsets)
          : Map.from(this.sectionOffsets),
      enableLogging: enableLogging,
    );
  }

  @override
  String toString() =>
      'Resume(fileName: $fileName, score: $score, major: $major)';
}


