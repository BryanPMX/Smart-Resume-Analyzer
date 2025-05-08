// The University of Texas at El Paso: Bryan Perez

import 'package:flutter/foundation.dart';
import 'scoring_rules.dart';

/// Centralized configuration for section detection:
/// - Canonical section names
/// - Header aliases for each section
/// - Regular expressions and heuristics
/// Used by [SectionDetectorService].
class SectionRules {
  /// Maximum text length to process.
  static const int maxTextLength = 100 * 1024;

  /// All section keys your app relies on.
  static const List<String> canonicalSections = [
    'contact',
    'summary',
    'experience',
    'education',
    'skills',
    'projects',
    'certifications',
    'miscellaneous',
  ];

  /// Case-insensitive marker for explicit sections: e.g. `== SECTION == Education`.
  static final RegExp sectionMarker = RegExp(
    r'^==\s*SECTION\s*==\s*(.+)$',
    multiLine: true,
    caseSensitive: false,
  );

  /// Raw aliases for each canonical section.
  static const Map<String, List<String>> _aliases = {
    'contact': ['contact', 'contact info', 'personal details', 'get in touch'],
    'summary': ['summary', 'objective', 'profile', 'overview'],
    'experience': ['experience', 'work history', 'employment', 'internships'],
    'education': ['education', 'academic background', 'degrees'],
    'skills': ['skills', 'technologies', 'proficiencies', 'abilities'],
    'projects': ['projects', 'portfolio', 'works', 'case studies'],
    'certifications': ['certifications', 'licenses', 'awards', 'certificates'],
    'miscellaneous': ['miscellaneous', 'other', 'additional', 'hobbies'],
  };

  /// Lowercase alias → canonical section.
  static final Map<String, String> aliasToSection = _buildAliasMap();
  static Map<String, String> _buildAliasMap() {
    final map = <String, String>{};
    _aliases.forEach((section, list) {
      for (final alias in list) {
        map[alias.toLowerCase()] = section;
      }
    });
    return map;
  }

  /// Reuse contact patterns from ScoringRules.
  static final RegExp contactPattern = RegExp(
    '(?:${ScoringRules.emailRegex.pattern}|'
        '${ScoringRules.phoneRegex.pattern}|'
        '${ScoringRules.portfolioRegex.pattern})',
    caseSensitive: false,
  );

  /// Date‐range pattern.
  static final RegExp datePattern = ScoringRules.dateRangeRegex;

  /// Bullet points (strict).
  static final RegExp bulletPattern = RegExp(r'^\s*[-•]\s+');

  /// Education keywords.
  static final RegExp educationPattern =
  RegExp(r'\b(university|college|degree|education)\b', caseSensitive: false);

  /// Summary/profile keywords.
  static final RegExp summaryPattern =
  RegExp(r'\b(summary|objective|profile)\b', caseSensitive: false);

  /// Skills keywords.
  static final RegExp skillsPattern =
  RegExp(r'\b(skills|python|java|communication)\b', caseSensitive: false);

  /// Validate that every canonical section has aliases.
  static void validate({bool log = false}) {
    final missing = canonicalSections.where((s) => !_aliases.containsKey(s)).toList();
    if (missing.isNotEmpty) {
      final msg = 'SectionRules missing aliases for: $missing';
      if (log) debugPrint(msg);
      throw StateError(msg);
    }
    if (log) debugPrint('SectionRules validated');
  }

  /// Call once at startup.
  static void initialize({bool log = false}) {
    validate(log: log);
    if (log) debugPrint('SectionRules initialized');
  }
}

