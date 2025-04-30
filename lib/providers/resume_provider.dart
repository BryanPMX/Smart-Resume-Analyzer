import 'package:flutter/material.dart';
import '../models/resume.dart';
import '../models/section_score.dart';

/// ViewModel for managing all resume-related state:
/// - raw text & file name
/// - parsed section blocks & offsets
/// - scoring breakdown & overall score
/// - feedback tips
/// - detected major
class ResumeViewModel extends ChangeNotifier {
  Resume _resume = Resume.empty();

  /// Current resume state
  Resume get resume => _resume;

  /// Replace entire resume (e.g., after parsing + scoring)
  void updateResume(Resume newResume) {
    _resume = newResume;
    notifyListeners();
  }

  /// Append additional feedback messages
  void addFeedback(List<String> additional) {
    // feedback is non-nullable, so a plain spread is fine
    final merged = [..._resume.feedback, ...additional];
    _resume = _resume.copyWith(feedback: merged);
    notifyListeners();
  }

  /// Overwrite section-by-section scores
  void setSectionBreakdown(List<SectionScore> sections) {
    _resume = _resume.copyWith(sectionBreakdown: sections);
    notifyListeners();
  }

  /// Set or update the detected academic major
  void setMajor(String? major) {
    _resume = _resume.copyWith(major: major);
    notifyListeners();
  }

  /// Store raw parsed text blocks for each section
  void setParsedSections(Map<String, String> blocks) {
    _resume = _resume.copyWith(parsedSections: blocks);
    notifyListeners();
  }

  /// Store the character offsets of each section header
  void setSectionOffsets(Map<String, int> offsets) {
    _resume = _resume.copyWith(sectionOffsets: offsets);
    notifyListeners();
  }

  /// Reset everything back to initial empty state
  void clearResume() {
    _resume = Resume.empty();
    notifyListeners();
  }
}
