import 'dart:developer' as developer;
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
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
  static Future<String> extractText(File file,
      {bool enableLogging = false}) async {
    // Validate file
    if (!await file.exists()) {
      throw Exception('File does not exist: ${file.path}');
    }
    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      throw Exception(
          'File size exceeds limit of ${_maxFileSize ~/ (1024 * 1024)} MB');
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

    // Compile regex patterns once for performance
    final dateRx =
        RegExp(r'\d{4}[-–]\d{4}|Present|\d{1,2}/\d{4}', caseSensitive: false);
    final bulletRx = RegExp(r'^(\s*)([-•\u2022]|\d+\.)\s+(.+)$');
    final degreeRx =
        RegExp(r'\b(university|bachelor|master)\b', caseSensitive: false);
    final emailRx =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final phoneRx =
        RegExp(r'\b(\+\d{1,3}[-.\s]?)?(\d{3}[-.\s]?\d{3}[-.\s]?\d{4})\b');
    final urlRx =
        RegExp(r'\b(https?://)?((www\.)?(linkedin|github)\.com/[^\s]+)\b');

    // Track whether contact section has been explicitly marked
    bool contactSectionStarted = false;

    for (var i = 0; i < doc.pages.count && i < _maxPages; i++) {
      final raw = PdfTextExtractor(doc)
          .extractText(startPageIndex: i, endPageIndex: i)
          .replaceAll('\r', ''); // Normalize line endings
      for (var line in raw.split('\n')) {
        final norm = line.replaceAll(RegExp(r'\s+'), ' ').trimRight();
        if (norm.isEmpty) {
          buffer.writeln();
          continue;
        }

        // Handle bullet points
        final bulletMatch = bulletRx.firstMatch(line);
        if (bulletMatch != null) {
          final formattedLine =
              '${bulletMatch.group(1)}${bulletMatch.group(2)} ${bulletMatch.group(3)}';
          // Heuristic: Bullets often indicate skills
          if (!contactSectionStarted) {
            buffer.writeln('==SECTION== skills');
            if (enableLogging) {
              developer.log('Detected skills section (bullet): $formattedLine');
            }
          }
          buffer.writeln(formattedLine);
          continue;
        }

        final t = norm.trim();
        final lower = t.toLowerCase();

        // Check for contact information (email, phone, LinkedIn/GitHub)
        if (!contactSectionStarted &&
            (emailRx.hasMatch(t) || phoneRx.hasMatch(t) || urlRx.hasMatch(t))) {
          buffer.writeln('==SECTION== contact');
          contactSectionStarted = true;
          if (enableLogging) {
            developer.log('Detected contact section: $t');
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
          if (canonicalSection == 'contact') {
            contactSectionStarted = true;
          }
          if (enableLogging) {
            developer
                .log('Detected section header: $match → $canonicalSection');
          }
          continue;
        }

        // Heuristic: Date ranges indicate experience
        if (dateRx.hasMatch(t)) {
          buffer.writeln('==SECTION== experience');
          if (enableLogging) {
            developer.log('Detected experience section (date): $t');
          }
          buffer.writeln(norm);
          continue;
        }

        // Heuristic: Degree keywords indicate education
        if (degreeRx.hasMatch(t)) {
          buffer.writeln('==SECTION== education');
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
    }
    return result;
  }
}
