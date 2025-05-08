import 'dart:developer' as developer;
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../utils/scoring_rules.dart';
import '../utils/section_rules.dart';

/// A service for parsing PDF resume files, extracting text, and
/// annotating sections with `==SECTION== <canonical>` markers based on
/// [SectionRules.aliasToSection]. Enhances section detection with
/// heuristics for contact information, skills, education, and experience.
class PdfParserService {
  static const int _maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int _maxPages = 3;

  /// Extracts and structures text from a PDF resume file, annotating sections
  /// with `==SECTION== <canonical>` markers and inserting page breaks.
  static Future<String> extractText(
      File file, {
        bool enableLogging = false,
      }) async {
    if (!await file.exists()) {
      throw Exception('File does not exist: ${file.path}');
    }
    final size = await file.length();
    if (size > _maxFileSize) {
      throw Exception('PDF too large (${size ~/ (1024 * 1024)}MB)');
    }

    // Load PDF
    late PdfDocument doc;
    try {
      final bytes = await file.readAsBytes();
      doc = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw Exception('Failed to parse PDF: $e');
    }

    // Prepare regexes & alias map
    final dateRx = ScoringRules.dateRangeRegex;
    final bulletRx = RegExp(r'^(\s*)([-•]|\d+\.)\s+(.+)$');
    final degreeRx = RegExp(
      r'\b(university|college|institute|academy|bachelor|master|degree|graduating|school)\b',
      caseSensitive: false,
    );
    final summaryRx = RegExp(
      r'\b(summary|objective|profile|overview)\b',
      caseSensitive: false,
    );

    // aliasToSection from SectionRules
    final aliasToCanon = SectionRules.aliasToSection;

    final buffer = StringBuffer();
    var contactStarted = false;

    // Process pages
    for (var i = 0; i < doc.pages.count && i < _maxPages; i++) {
      final raw = PdfTextExtractor(doc)
          .extractText(startPageIndex: i, endPageIndex: i)
          .replaceAll('\r', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(r'$\cdot$', ' | ')
          .replaceAll(RegExp(r'[^\x20-\x7E\n]'), '');

      if (enableLogging) developer.log('Page $i raw text:\n$raw');

      for (final line in raw.split('\n')) {
        final trimmed = line.trimRight();
        if (trimmed.isEmpty) {
          buffer.writeln();
          continue;
        }

        // 1) Bullets → skills or projects
        final b = bulletRx.firstMatch(line);
        if (b != null) {
          final content = '${b.group(1)}${b.group(2)} ${b.group(3)}';
          final low = content.toLowerCase();
          final section = low.contains('project') || low.contains('developed')
              ? 'projects'
              : 'skills';
          buffer.writeln('==SECTION== $section');
          if (enableLogging) {
            developer.log('Bullet inferred section=$section: $content');
          }
          buffer.writeln(content);
          continue;
        }

        final textLower = trimmed.toLowerCase();

        // 2) Contact
        if (!contactStarted &&
            (ScoringRules.emailRegex.hasMatch(trimmed) ||
                ScoringRules.phoneRegex.hasMatch(trimmed) ||
                ScoringRules.portfolioRegex.hasMatch(trimmed))) {
          buffer.writeln('==SECTION== contact');
          contactStarted = true;
          if (enableLogging) developer.log('Detected contact: $trimmed');
          buffer.writeln(trimmed);
          continue;
        }

        // 3) Explicit header alias
        final aliasMatch = aliasToCanon.keys.firstWhere(
              (a) =>
          textLower == a ||
              textLower.startsWith('$a ') ||
              textLower.contains(' $a'),
          orElse: () => '',
        );
        if (aliasMatch.isNotEmpty) {
          final canon = aliasToCanon[aliasMatch]!;
          buffer.writeln('==SECTION== $canon');
          if (enableLogging) {
            developer.log('Header alias $aliasMatch → $canon');
          }
          continue;
        }

        // 4) Heuristic: summary, experience, education
        if (summaryRx.hasMatch(trimmed)) {
          buffer.writeln('==SECTION== summary');
          if (enableLogging) developer.log('Heuristic summary: $trimmed');
          buffer.writeln(trimmed);
          continue;
        }
        if (dateRx.hasMatch(trimmed)) {
          buffer.writeln('==SECTION== experience');
          if (enableLogging) developer.log('Heuristic experience: $trimmed');
          buffer.writeln(trimmed);
          continue;
        }
        if (degreeRx.hasMatch(trimmed)) {
          buffer.writeln('==SECTION== education');
          if (enableLogging) developer.log('Heuristic education: $trimmed');
          buffer.writeln(trimmed);
          continue;
        }

        // 5) Default: write as-is
        buffer.writeln(trimmed);
      }

      buffer.writeln('\n==PAGE_BREAK==\n');
    }

    // Ensure contact appears first if never detected
    if (!contactStarted && buffer.isNotEmpty) {
      final prefixed = '==SECTION== contact\n${buffer.toString()}';
      buffer.clear();
      buffer.write(prefixed);
      if (enableLogging) developer.log('Prepended contact section.');
    }

    doc.dispose();
    final result = buffer.toString().trim();
    if (enableLogging) {
      developer.log('Final parsed text length=${result.length}');
      developer.log(result);
    }
    return result;
  }
}

