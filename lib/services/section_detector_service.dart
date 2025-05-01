// section_detector_service.dart
import 'dart:developer' as developer;
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
  /// Used by services like `PdfParserService` to map headers to canonical names.
  ///
  /// Returns a map where keys are canonical names (e.g., 'experience') and values are lists
  /// of aliases (e.g., ['experience', 'employment', 'work history']).
  static Map<String, List<String>> labelAliases() => {
        'summary': [
          'summary',
          'objective',
          'professional summary',
          'dedication',
          'profile',
          'goals',
        ],
        'experience': [
          'experience',
          'employment',
          'work history',
          'professional experience',
          'work experience',
        ],
        'education': [
          'education',
          'academic background',
          'studies',
          'academic history',
        ],
        'skills': [
          'skills',
          'technologies',
          'tools',
          'proficiencies',
          'languages',
          'coursework',
          'relevant coursework',
        ],
        'projects': [
          'projects',
          'portfolio',
          'case studies',
          'works',
        ],
        'certifications': [
          'certifications',
          'licenses',
          'credentials',
          'achievements',
        ],
        'miscellaneous': [
          'miscellaneous',
          'other',
          'additional information',
          'hobbies',
        ],
      };

  /// Extracts named sections from structured resume [text] containing `==SECTION==` markers.
  /// Applies heuristics to infer sections for unmarked content and ensures all expected
  /// sections are included in the output, defaulting to empty strings for missing sections.
  ///
  /// [text] The resume text to parse, typically preprocessed by `PdfParserService`.
  /// [enableLogging] If true, logs parsing steps for debugging (default: false).
  ///
  /// Returns a map of canonical section names to their content, including:
  /// - 'contact': Content before the first marker or inferred contact information.
  /// - 'summary', 'experience', 'education', 'skills', 'projects', 'certifications', 'miscellaneous'.
  ///
  /// Throws:
  /// - [ArgumentError] If [text] exceeds the maximum length or is malformed.
  static Map<String, String> detectSections(String text,
      {bool enableLogging = false}) {
    // Validate input
    if (text.length > _maxTextLength) {
      throw ArgumentError(
          'Input text exceeds maximum length of $_maxTextLength characters');
    }

    // Compile regex patterns once for performance, aligning with ScoringRules
    final sectionRx = RegExp(r'^==SECTION==\s+(.+)$', multiLine: true);
    final contactRx = RegExp(
      r'(?:${ScoringRules.emailRegex.pattern}|${ScoringRules.phoneRegex.pattern}|${ScoringRules.portfolioRegex.pattern})(?:[\s$\cdot|]*)',
      caseSensitive: false,
    );
    final dateRx = ScoringRules.dateRangeRegex;
    final bulletRx =
        RegExp(r'^\s*(?:[-•\u2022]\s+|[A-Za-z\s]+:\s*|[\w\s]+,\s*)');
    final degreeRx = RegExp(
      r'\b(university|college|institute|academy|bachelor|master|degree|graduating)\b',
      caseSensitive: false,
    );
    final summaryRx = RegExp(
      r'^(?:dedication|objective|passionate|quick learner|professional|summary|profile|goals)\b.*?(?=\n|$)',
      caseSensitive: false,
    );
    final skillsRx = RegExp(
      r'\b(python|java|golang|javascript|sql|html|css|git|github|machine learning|database|software|programming)\b',
      caseSensitive: false,
    );
    final projectRx = ScoringRules.projectSectionRegex;

    final aliases = labelAliases();
    final out = <String, String>{};
    final matches = sectionRx.allMatches(text).toList();

    // Initialize all canonical sections with empty strings
    for (var section in _canonicalSections) {
      out[section] = '';
    }

    // Track current section and contact detection
    String current = 'contact';
    final buf = StringBuffer();
    bool contactDetected = false;
    bool summaryDetected = false;
    int contactElements = 0;

    // 1) Process contact and summary blocks: everything before first marker
    if (matches.isNotEmpty && matches.first.start > 0) {
      final preMarkerText = text.substring(0, matches.first.start).trim();
      final preMarkerLines = preMarkerText.split('\n');
      for (final line in preMarkerLines) {
        final trimmedLine = line.trim();
        if (contactRx.hasMatch(trimmedLine)) {
          out['contact'] = (out['contact']! + '\n' + trimmedLine).trim();
          contactElements += contactRx.allMatches(trimmedLine).length;
          if (contactElements >= 2) {
            contactDetected = true;
          }
          if (enableLogging) {
            developer.log(
                'Detected contact info: $trimmedLine, elements: $contactElements');
          }
        } else if (!summaryDetected && summaryRx.hasMatch(trimmedLine)) {
          out['summary'] = trimmedLine;
          summaryDetected = true;
          if (enableLogging) {
            developer.log(
                'Detected summary section before first marker: $trimmedLine');
          }
        }
      }
    }

    // 2) Process explicitly marked sections
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
      final content = text.substring(start, end).trim();
      out[canon] = content;
      if (enableLogging) {
        developer.log(
            'Processed section: $canon with content length: ${content.length}');
      }
    }

    // 3) Fallback inference for unmarked lines
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final m = sectionRx.firstMatch(line);
      if (m != null) {
        // Flush previous buffer
        out[current] = buf.toString().trim();
        buf.clear();
        // Switch to new section
        final hdr = m.group(1)!.toLowerCase().trim();
        current = aliases.entries
            .firstWhere(
              (e) => e.value.contains(hdr),
              orElse: () => const MapEntry('miscellaneous', []),
            )
            .key;
        if (enableLogging) {
          developer.log('Switched to section: $current');
        }
        continue;
      }

      // Heuristic: Detect section headers in unmarked text
      bool headerDetected = false;
      for (final entry in aliases.entries) {
        if (entry.value.any((alias) => line.toLowerCase() == alias)) {
          out[current] = buf.toString().trim();
          buf.clear();
          current = entry.key;
          headerDetected = true;
          if (enableLogging) {
            developer.log('Inferred section header: $current from line: $line');
          }
          break;
        }
      }
      if (headerDetected) continue;

      // Heuristic: Contact information (email, phone, URLs)
      if (!contactDetected && contactRx.hasMatch(line)) {
        if (current != 'contact') {
          out[current] = buf.toString().trim();
          buf.clear();
          current = 'contact';
          contactElements += contactRx.allMatches(line).length;
          if (contactElements >= 2) {
            contactDetected = true;
          }
          if (enableLogging) {
            developer.log(
                'Inferred contact section: $line, elements: $contactElements');
          }
        }
      }
      // Heuristic: Summary (short line with summary-like keywords)
      else if (!summaryDetected && summaryRx.hasMatch(line)) {
        if (current != 'summary') {
          out[current] = buf.toString().trim();
          buf.clear();
          current = 'summary';
          summaryDetected = true;
          if (enableLogging) {
            developer.log('Inferred summary section: $line');
          }
        }
      }
      // Heuristic: Date ranges → experience
      else if (dateRx.hasMatch(line)) {
        if (current != 'experience') {
          out[current] = buf.toString().trim();
          buf.clear();
          current = 'experience';
          if (enableLogging) {
            developer.log('Inferred experience section (date): $line');
          }
        }
      }
      // Heuristic: List formats → skills
      else if (bulletRx.hasMatch(line) || skillsRx.hasMatch(line)) {
        if (current != 'skills') {
          out[current] = buf.toString().trim();
          buf.clear();
          current = 'skills';
          if (enableLogging) {
            developer.log('Inferred skills section (list or keyword): $line');
          }
        }
      }
      // Heuristic: Degree keywords → education
      else if (degreeRx.hasMatch(line)) {
        if (current != 'education') {
          out[current] = buf.toString().trim();
          buf.clear();
          current = 'education';
          if (enableLogging) {
            developer.log('Inferred education section (degree): $line');
          }
        }
      }
      // Heuristic: Project keywords → projects
      else if (projectRx.hasMatch(line) ||
          line.toLowerCase().contains('developed') ||
          line.toLowerCase().contains('built')) {
        if (current != 'projects') {
          out[current] = buf.toString().trim();
          buf.clear();
          current = 'projects';
          if (enableLogging) {
            developer.log('Inferred projects section (keyword): $line');
          }
        }
      }

      buf.writeln(line);
    }

    // Flush remaining buffer
    out[current] = buf.toString().trim();
    if (enableLogging && buf.isNotEmpty) {
      developer.log('Flushed remaining content to section: $current');
    }

    // 4) Validate and log missing sections
    for (var section in _canonicalSections) {
      if (out[section]!.isEmpty && enableLogging) {
        developer.log('Warning: Section $section is empty');
      }
    }

    // 5) Log final section map for debugging
    if (enableLogging) {
      developer.log('Final section map:');
      for (var entry in out.entries) {
        developer.log('  ${entry.key}: ${entry.value.length} characters');
      }
    }

    return out;
  }
}
