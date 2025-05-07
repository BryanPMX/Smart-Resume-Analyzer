import '../utils/scoring_rules.dart';

/// A service that splits resume text tagged with `==SECTION==` markers into named
/// blocks and infers missing sections using heuristics. Ensures all expected sections
/// are included in the output map, aligning with `PdfParserService` and `ScoringService`.
class SectionDetectorService {
  /// Maximum text length to process to prevent excessive memory usage.
  static const int _maxTextLength = 100 * 1024; // 100 KB

  /// Canonical section names expected by dependent services.
  static const List<String> _canonicalSections = [
    'contact',
    'summary',
    'experience',
    'education',
    'skills',
    'projects',
    'certifications',
    'miscellaneous',
  ];

  /// Provides a map of canonical section names to their possible aliases for header matching.
  static Map<String, List<String>> labelAliases() => {
    'summary': [
      'summary',
      'objective',
      'professional summary',
      'profile',
      'overview',
    ],
    'experience': [
      'experience',
      'employment',
      'work history',
      'work experience',
      'internships',
    ],
    'education': [
      'education',
      'academic background',
      'degrees',
    ],
    'skills': [
      'skills',
      'technologies',
      'proficiencies',
      'abilities',
    ],
    'projects': [
      'projects',
      'portfolio',
      'works',
    ],
    'certifications': [
      'certifications',
      'licenses',
      'awards',
    ],
    'miscellaneous': [
      'miscellaneous',
      'other',
      'hobbies',
    ],
  };

  /// Extracts named sections from structured resume [text] containing `==SECTION==` markers.
  static Map<String, String> detectSections(String text, {bool enableLogging = false}) {
    if (text.length > _maxTextLength) {
      throw ArgumentError('Input text exceeds maximum length of $_maxTextLength characters');
    }

    final sectionRx = RegExp(r'^==SECTION==\s+(.+)$', multiLine: true);
    final contactRx = RegExp(
      '(?:' + ScoringRules.emailRegex.pattern + '|' + ScoringRules.phoneRegex.pattern + '|' + ScoringRules.portfolioRegex.pattern + ')',
      caseSensitive: false,
    );
    final dateRx = ScoringRules.dateRangeRegex;
    final bulletRx = RegExp(r'^\s*(?:[-•]\s+|[A-Za-z\s]+:\s*|[\w\s]+,\s*)');
    final degreeRx = RegExp(r'\b(university|college|degree|education)\b', caseSensitive: false);
    final summaryRx = RegExp(r'\b(summary|objective|professional|profile)\b', caseSensitive: false);
    final skillsRx = RegExp(r'\b(skills|python|java|communication)\b', caseSensitive: false);

    final aliases = labelAliases();
    final out = <String, String>{};
    for (var section in _canonicalSections) {
      out[section] = '';
    }

    String current = 'contact';
    final buf = StringBuffer();
    final matches = sectionRx.allMatches(text).toList();

    // Process content before the first marker (likely Contact or Summary)
    if (matches.isNotEmpty && matches.first.start > 0) {
      final preMarkerText = text.substring(0, matches.first.start).trim();
      final preMarkerLines = preMarkerText.split('\n');
      for (final line in preMarkerLines) {
        final trimmedLine = line.trim();
        if (contactRx.hasMatch(trimmedLine)) {
          out['contact'] = (out['contact']! + '\n' + trimmedLine).trim();
        } else if (summaryRx.hasMatch(trimmedLine)) {
          out['summary'] = trimmedLine;
        }
      }
    }

    // Process explicitly marked sections
    for (var i = 0; i < matches.length; i++) {
      final rawHeader = matches[i].group(1)!.toLowerCase().trim();
      final canon = aliases.entries
          .firstWhere(
            (e) => e.value.contains(rawHeader),
        orElse: () => const MapEntry('miscellaneous', []),
      )
          .key;
      final start = matches[i].end;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      out[canon] = text.substring(start, end).trim();
    }

    // Fallback inference for unmarked content
    final lines = text.split('\n');
    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final m = sectionRx.firstMatch(trimmedLine);
      if (m != null) {
        out[current] = buf.toString().trim();
        buf.clear();
        final hdr = m.group(1)!.toLowerCase().trim();
        current = aliases.entries
            .firstWhere(
              (e) => e.value.contains(hdr),
          orElse: () => const MapEntry('miscellaneous', []),
        )
            .key;
        continue;
      }

      if (degreeRx.hasMatch(trimmedLine)) {
        current = 'education';
      } else if (contactRx.hasMatch(trimmedLine)) {
        current = 'contact';
      } else if (summaryRx.hasMatch(trimmedLine)) {
        current = 'summary';
      } else if (dateRx.hasMatch(trimmedLine)) {
        current = 'experience';
      } else if (bulletRx.hasMatch(trimmedLine) || skillsRx.hasMatch(trimmedLine)) {
        current = 'skills';
      }
      buf.writeln(trimmedLine);
    }
    out[current] = buf.toString().trim();

    return out;
  }
}
