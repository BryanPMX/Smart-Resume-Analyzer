import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for extracting and preprocessing text content from a PDF file using Syncfusion.
///
/// Enhances the output by retaining layout indicators (line breaks, indentation)
/// and standardizing section markers for better downstream parsing.
class PdfParserService {
  /// Extracts and preprocesses the full text from [file].
  ///
  /// - Reads each page via Syncfusion’s PdfTextExtractor
  /// - Splits into lines to preserve structure
  /// - Normalizes whitespace and line breaks
  /// - Detects known section headers and prefixes them with `==SECTION==`
  /// - Preserves indentation and bullet markers for lists
  static Future<String> extractText(File file) async {
    PdfDocument document;
    try {
      final bytes = await file.readAsBytes();
      document = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw Exception('Could not open PDF: ${e.toString()}');
    }

    final buffer = StringBuffer();

    // Canonical list of known section headers
    final knownHeaders = <String>{
      'SUMMARY', 'OBJECTIVE',
      'EXPERIENCE', 'EMPLOYMENT', 'WORK HISTORY',
      'EDUCATION', 'ACADEMIC BACKGROUND', 'STUDIES',
      'SKILLS', 'TECHNOLOGIES', 'TOOLS', 'PROFICIENCIES',
      'PROJECTS', 'PORTFOLIO', 'CASE STUDIES',
      'CERTIFICATIONS', 'LICENSES', 'CREDENTIALS',
    };

    // Process each page of the PDF
    for (int i = 0; i < document.pages.count; i++) {
      final raw = PdfTextExtractor(document)
          .extractText(startPageIndex: i, endPageIndex: i);
      final lines = raw.split('\n');

      for (final line in lines) {
        final normalized = line.replaceAll(RegExp(r'\s+'), ' ').trimRight();

        if (normalized.isEmpty) {
          buffer.writeln(); // Preserve blank lines
          continue;
        }

        // Detect bullets or numbered lists
        final bulletMatch = RegExp(r'^(\s*)([-•\u2022]|\d+\.)\s+(.+)$')
            .firstMatch(line);
        if (bulletMatch != null) {
          buffer.writeln('${bulletMatch.group(1)}${bulletMatch.group(2)} ${bulletMatch.group(3)}');
          continue;
        }

        final trimmed = normalized.trim();
        final upper = trimmed.toUpperCase();

        // Mark section headers using known list
        if (knownHeaders.contains(upper)) {
          buffer.writeln('==SECTION== $trimmed');
        } else {
          final indent = RegExp(r'^\s*').firstMatch(line)?.group(0) ?? '';
          buffer.writeln('$indent$normalized');
        }
      }

      buffer.writeln('\n==PAGE_BREAK==\n');
    }

    document.dispose();

    // Cleanup
    return buffer.toString()
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'[ \t]+$'), '')
        .trim();
  }
}




