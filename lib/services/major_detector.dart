import '../services/section_detector_service.dart';

/// Service responsible for automatically detecting the candidate’s academic major
/// from the raw resume text, based on a predefined list of top 20 majors.
class MajorDetector {
  /// Top 20 academic majors for personalized feedback.
  static const List<String> knownMajors = [
    'Computer Science',
    'Business Administration',
    'Mechanical Engineering',
    'Nursing',
    'Electrical Engineering',
    'Psychology',
    'Biology',
    'Economics',
    'Accounting',
    'Civil Engineering',
    'Education',
    'Finance',
    'Political Science',
    'Marketing',
    'Communications',
    'Chemistry',
    'Information Technology',
    'Graphic Design',
    'Mathematics',
    'Environmental Science',
  ];

  /// Attempts to detect the candidate’s major from the resume [text].
  ///
  /// 1. Extracts the “education” section via [SectionDetectorService].
  /// 2. Scans that block with word‑boundary regexes for each known major.
  /// 3. If exactly one match → returns it; otherwise falls back to entire [text].
  /// 4. If still ambiguous or none → returns null.
  static String? detectMajor(String text) {
    if (text.trim().isEmpty) return null;

    // 1) Try the education block first
    final sections = SectionDetectorService.detectSections(text.toLowerCase());
    final eduBlock = sections['education'] ?? '';

    final foundInEdu = _findMajorsIn(eduBlock);
    if (foundInEdu.length == 1) {
      return foundInEdu.first;
    }

    // 2) Fall back to scanning full text
    final foundInAll = _findMajorsIn(text.toLowerCase());
    if (foundInAll.length == 1) {
      return foundInAll.first;
    }

    // 3) Ambiguous or none
    return null;
  }

  /// Helper: returns the list of known majors whose lowercase form
  /// appears as a whole‐word match in [block].
  static List<String> _findMajorsIn(String block) {
    final matches = <String>[];
    for (final major in knownMajors) {
      final pat = RegExp(r'\b' + RegExp.escape(major.toLowerCase()) + r'\b');
      if (pat.hasMatch(block)) {
        matches.add(major);
      }
    }
    return matches;
  }
}
