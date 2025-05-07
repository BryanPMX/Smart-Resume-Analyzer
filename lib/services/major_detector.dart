// major_detector.dart
import 'dart:developer' as developer;
import '../utils/scoring_rules.dart';

/// A service that auto-detects a candidate’s academic major from resume text by matching
/// against a predefined list of known majors and their aliases. Designed to work with
/// `ScoringService` to tailor skill scoring and feedback.
class MajorDetector {
  /// Maximum text length to process to prevent excessive memory usage.
  static const int _maxTextLength = 100 * 1024; // 100 KB

  /// Map of canonical majors to their possible aliases or abbreviations for detection.
  /// Keys are canonical major names (e.g., 'Computer Science'), and values are lists of
  /// aliases (e.g., ['Computer Science', 'CS', 'Comp Sci']).
  static const Map<String, List<String>> _majorAliases = {
    'Computer Science': ['Computer Science', 'CS', 'Comp Sci'],
    'Business Administration': ['Business Administration', 'Business Admin', 'Biz Admin'],
    'Mechanical Engineering': ['Mechanical Engineering', 'Mech Eng', 'Mechanical Eng'],
    'Nursing': ['Nursing'],
    'Electrical Engineering': ['Electrical Engineering', 'EE', 'Electrical Eng'],
    'Psychology': ['Psychology', 'Psych'],
    'Biology': ['Biology', 'Bio'],
    'Economics': ['Economics', 'Econ'],
    'Accounting': ['Accounting', 'Acct'],
    'Civil Engineering': ['Civil Engineering', 'Civil Eng'],
    'Education': ['Education', 'Edu'],
    'Finance': ['Finance', 'Fin'],
    'Political Science': ['Political Science', 'Poli Sci'],
    'Marketing': ['Marketing', 'Mktg'],
    'Communications': ['Communications', 'Comm'],
    'Chemistry': ['Chemistry', 'Chem'],
    'Information Technology': ['Information Technology', 'IT', 'Info Tech'],
    'Graphic Design': ['Graphic Design', 'GD', 'Design'],
    'Mathematics': ['Mathematics', 'Math', 'Maths'],
    'Environmental Science': ['Environmental Science', 'Env Sci', 'Environmental Sci'],
  };

  /// Provides the list of canonical majors for validation purposes.
  static Iterable<String> get knownMajors => _majorAliases.keys;

  /// Precomputed lowercase aliases for efficient matching.
  static final Map<String, String> _lowercaseToCanonical = _precomputeAliases();

  /// Precomputes lowercase aliases mapped to their canonical major names for efficient lookup.
  static Map<String, String> _precomputeAliases() {
    final map = <String, String>{};
    _majorAliases.forEach((canonical, aliases) {
      for (var alias in aliases) {
        map[alias.toLowerCase()] = canonical;
      }
    });
    return map;
  }

  /// Detects the candidate’s academic major from the provided [text].
  ///
  /// [text] The resume text to analyze, typically the `education` section or full text.
  /// [enableLogging] If true, logs detection steps for debugging (default: false).
  ///
  /// Returns the detected major as a canonical name (e.g., 'Computer Science') if exactly
  /// one unique major is found, or `null` if no major or multiple distinct majors are detected.
  ///
  /// Throws:
  /// - [ArgumentError] If [text] is empty or exceeds the maximum length.
  static String? detectMajor(String text, {bool enableLogging = false}) {
    // Validate input
    if (text.isEmpty) {
      throw ArgumentError('Input text cannot be empty');
    }
    if (text.length > _maxTextLength) {
      throw ArgumentError('Input text exceeds maximum length of $_maxTextLength characters');
    }

    final norm = text.toLowerCase();
    final matchedMajors = <String>{}; // Use a set to track unique canonical majors

    // Search for each alias in the text
    for (var entry in _lowercaseToCanonical.entries) {
      final alias = entry.key;
      final canonical = entry.value;
      if (norm.contains(alias)) {
        matchedMajors.add(canonical);
      }
    }

    // Validate against ScoringRules.majorRelevantSkills
    final validMajors = matchedMajors.where((major) {
      final isValid = ScoringRules.majorRelevantSkills.containsKey(major);
      if (!isValid && enableLogging) {
        developer.log('Warning: Detected major "$major" not found in ScoringRules.majorRelevantSkills');
      }
      return isValid;
    }).toList();

    if (enableLogging) {
      if (validMajors.isEmpty) {
        developer.log('No valid majors detected in text');
      } else if (validMajors.length > 1) {
        developer.log('Multiple majors detected: $validMajors, returning null');
      } else {
        developer.log('Detected major: ${validMajors.first}');
      }
    }

    // Return the major if exactly one is found, otherwise null
    return validMajors.length == 1 ? validMajors.first : null;
  }
}



