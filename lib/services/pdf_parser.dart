// pdf_parser_service.dart
import 'dart:developer' as developer;
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/scoring_rules.dart';
import 'section_detector_service.dart';

/// A service for parsing PDF resume files, extracting text, and annotating sections
/// with `==SECTION== <canonical>` markers based on `SectionDetectorService`'s alias map.
/// Enhances section detection with heuristics for contact information, skills, and education,
/// and includes robust error handling and logging for debugging.
class PdfParserService {
  /// Maximum file size (in bytes) to prevent processing overly large PDFs.
  static const int _maxFileSize = 10 * 1024 * 1024; // 10 MB

  /// Maximum number of pages to process to optimize performance.
  static const int _maxPages = 3;

  /// Extracts and structures text from a PDF resume file, annotating sections with
  /// `==SECTION== <canonical>` markers. Applies heuristics to detect contact information,
  /// skills, education, and experience sections, ensuring alignment with `SectionDetectorService`.
  ///
  /// [file] The PDF file to parse.
  /// [enableLogging] If true, logs parsing steps for debugging (default: false).
  ///
  /// Returns a structured text string with section markers and page breaks.
  ///
  /// Throws:
  /// - [Exception] If the file cannot be read, is too large, or is an invalid PDF.
  static Future<String> extractText(File file, {bool enableLogging = false}) async {
    // Validate file
    if (!await file.exists()) {
      throw Exception('File does not exist: ${file.path}');
    }
    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      throw Exception('File size exceeds limit of ${_maxFileSize ~/ (1024 * 1024)} MB');
    }

    // Load PDF document
    PdfDocument doc;
    try {
      final bytes = await file.readAsBytes();
      doc = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw Exception('Failed to parse PDF: $e');
    }

    if (doc.pages.count == 0) {
      doc.dispose();
      throw Exception('PDF contains no pages');
    }

    final buffer = StringBuffer();
    // Build alias→canonical lookup
    final aliasMap = SectionDetectorService.labelAliases();
    final aliasToCanon = <String, String>{};
    aliasMap.forEach((canon, aliases) {
      for (var a in aliases) {
        aliasToCanon[a.toLowerCase()] = canon;
      }
    });

    // Use ScoringRules regex patterns for consistency
    final dateRx = ScoringRules.dateRangeRegex;
    final bulletRx = RegExp(r'^(\s*)([-•]|\d+\.)\s+(.+)$');
    final degreeRx = RegExp(r'\b(university|college|institute|academy|bachelor|master|degree|graduating|school)\b', caseSensitive: false);
    final summaryRx = RegExp(r'\b(summary|objective|profile|overview|dedication|quick learner|passionate)\b', caseSensitive: false);

    // Track whether sections have been explicitly marked
    bool contactSectionStarted = false;
    bool summarySectionStarted = false;
    bool educationSectionStarted = false;
    bool experienceSectionStarted = false;
    bool skillsSectionStarted = false;
    bool projectsSectionStarted = false;

    for (var i = 0; i < doc.pages.count && i < _maxPages; i++) {
      final raw = PdfTextExtractor(doc)
          .extractText(startPageIndex: i, endPageIndex: i)
          .replaceAll('\r', '') // Normalize line endings
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize multiple spaces to single
          .replaceAll(r'$\cdot$', ' | ') // Replace special characters like $\cdot$ with a pipe
          .replaceAll(RegExp(r'[^\x20-\x7E\n]'), ''); // Strip non-ASCII printable characters

      if (enableLogging) {
        developer.log('Raw extracted text for page $i:\n$raw');
      }

      for (var line in raw.split('\n')) {
        final norm = line.trimRight();
        if (norm.isEmpty) {
          buffer.writeln();
          continue;
        }

        // Handle bullet points
        final bulletMatch = bulletRx.firstMatch(line);
        if (bulletMatch != null) {
          final formattedLine = '${bulletMatch.group(1)}${bulletMatch.group(2)} ${bulletMatch.group(3)}';
          // Heuristic: Bullets often indicate skills or projects
          if (!skillsSectionStarted && !projectsSectionStarted) {
            if (line.toLowerCase().contains('project') || line.toLowerCase().contains('developed')) {
              buffer.writeln('==SECTION== projects');
              projectsSectionStarted = true;
              if (enableLogging) {
                developer.log('Detected projects section (bullet): $formattedLine');
              }
            } else {
              buffer.writeln('==SECTION== skills');
              skillsSectionStarted = true;
              if (enableLogging) {
                developer.log('Detected skills section (bullet): $formattedLine');
              }
            }
          }
          buffer.writeln(formattedLine);
          continue;
        }

        final t = norm.trim();
        final lower = t.toLowerCase();

        // Check for contact information using ScoringRules regex patterns
        if (!contactSectionStarted &&
            (ScoringRules.emailRegex.hasMatch(t) ||
                ScoringRules.phoneRegex.hasMatch(t) ||
                ScoringRules.portfolioRegex.hasMatch(t))) {
          buffer.writeln('==SECTION== contact');
          contactSectionStarted = true;
          if (enableLogging) {
            developer.log('Detected contact section: $t');
            if (ScoringRules.emailRegex.hasMatch(t)) {
              developer.log('  Email match: ${ScoringRules.emailRegex.firstMatch(t)!.group(0)}');
            }
            if (ScoringRules.phoneRegex.hasMatch(t)) {
              developer.log('  Phone match: ${ScoringRules.phoneRegex.firstMatch(t)!.group(0)}');
            }
            if (ScoringRules.portfolioRegex.hasMatch(t)) {
              developer.log('  Portfolio match: ${ScoringRules.portfolioRegex.firstMatch(t)!.group(0)}');
            }
          }
          buffer.writeln(norm);
          continue;
        }

        // Check for header alias
        String? match;
        for (var a in aliasToCanon.keys) {
          if (lower == a || lower.startsWith('$a ') || lower.contains(' $a')) {
            match = a;
            break;
          }
        }

        if (match != null) {
          final canonicalSection = aliasToCanon[match]!;
          buffer.writeln('==SECTION== $canonicalSection');
          if (canonicalSection == 'contact') contactSectionStarted = true;
          if (canonicalSection == 'summary') summarySectionStarted = true;
          if (canonicalSection == 'education') educationSectionStarted = true;
          if (canonicalSection == 'experience') experienceSectionStarted = true;
          if (canonicalSection == 'skills') skillsSectionStarted = true;
          if (canonicalSection == 'projects') projectsSectionStarted = true;
          if (enableLogging) {
            developer.log('Detected section header: $match → $canonicalSection');
          }
          continue;
        }

        // Heuristic: Summary detection
        if (!summarySectionStarted && summaryRx.hasMatch(t)) {
          buffer.writeln('==SECTION== summary');
          summarySectionStarted = true;
          if (enableLogging) {
            developer.log('Detected summary section (keyword): $t');
          }
          buffer.writeln(norm);
          continue;
        }

        // Heuristic: Date ranges indicate experience
        if (!experienceSectionStarted && dateRx.hasMatch(t)) {
          buffer.writeln('==SECTION== experience');
          experienceSectionStarted = true;
          if (enableLogging) {
            developer.log('Detected experience section (date): $t');
          }
          buffer.writeln(norm);
          continue;
        }

        // Heuristic: Degree keywords indicate education
        if (!educationSectionStarted && degreeRx.hasMatch(t)) {
          buffer.writeln('==SECTION== education');
          educationSectionStarted = true;
          if (enableLogging) {
            developer.log('Detected education section (degree): $t');
          }
          buffer.writeln(norm);
          continue;
        }

        // Default: Write line as-is
        buffer.writeln(norm);
      }
      buffer.writeln('\n==PAGE_BREAK==\n');
    }

    // Ensure contact section exists at the start if not already marked
    if (!contactSectionStarted && buffer.isNotEmpty) {
      final tempBuffer = StringBuffer('==SECTION== contact\n');
      tempBuffer.write(buffer.toString());
      buffer.clear();
      buffer.write(tempBuffer.toString());
      if (enableLogging) {
        developer.log('Added default contact section at start');
      }
    }

    doc.dispose();
    final result = buffer
        .toString()
        .replaceAll(RegExp(r'[ \t]+$'), '') // Remove trailing whitespace
        .trim();
    if (enableLogging) {
      developer.log('Parsed PDF text length: ${result.length} characters');
      developer.log('Final extracted text:\n$result');
    }
    return result;
  }
}
