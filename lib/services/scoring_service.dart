// scoring_service.dart
import 'dart:developer' as developer;
import '../models/resume.dart';
import '../models/section_score.dart';
import '../services/section_detector_service.dart';
import '../services/major_detector.dart';
import '../utils/scoring_rules.dart';

/// A service that analyzes resume text to compute a normalized score (0–100),
/// detailed per-section feedback, and a breakdown of section scores. Integrates
/// with `SectionDetectorService` for section parsing, `MajorDetector` for major
/// identification, and `ScoringRules` for scoring criteria.
class ScoringService {
  /// Maximum text length to process to prevent excessive memory usage.
  static const int _maxTextLength = 100 * 1024; // 100 KB

  /// Expected section names to ensure all are present in the section map.
  static const List<String> _expectedSections = [
    'contact',
    'summary',
    'experience',
    'education',
    'skills',
    'projects',
    'certifications',
  ];

  /// Analyzes a [input] resume and returns a new [Resume] with computed score,
  /// detected major, feedback list, and section-by-section breakdown.
  ///
  /// [input] The resume to analyze, containing the full text to process.
  /// [enableLogging] If true, logs analysis steps for debugging (default: false).
  ///
  /// Returns a new [Resume] with updated score, major, feedback, and section breakdown.
  ///
  /// Throws:
  /// - [ArgumentError] If [input.fullText] is empty or exceeds the maximum length.
  static Resume analyze(Resume input, {bool enableLogging = false}) {
    // Validate input
    if (input.fullText.isEmpty) {
      throw ArgumentError('Resume text cannot be empty');
    }
    if (input.fullText.length > _maxTextLength) {
      throw ArgumentError(
          'Resume text exceeds maximum length of $_maxTextLength characters');
    }

    final rawText = input.fullText;
    final sections = SectionDetectorService.detectSections(rawText,
        enableLogging: enableLogging);

    // Ensure all expected sections are present
    final sectionMap = <String, String>{};
    for (var section in _expectedSections) {
      sectionMap[section] = sections[section] ?? '';
      if (enableLogging && sectionMap[section]!.isEmpty) {
        developer.log('Section $section is empty');
      }
    }

    // Major detection (focused on education section for accuracy)
    final detectedMajor = MajorDetector.detectMajor(
        sectionMap['education']!.isNotEmpty
            ? sectionMap['education']!
            : rawText);
    if (enableLogging) {
      developer.log('Detected major: ${detectedMajor ?? "none"}');
    }

    // Validate major and choose skill list
    final relevantSkills = (detectedMajor != null &&
            ScoringRules.majorRelevantSkills.containsKey(detectedMajor))
        ? ScoringRules.majorRelevantSkills[detectedMajor]!
        : ScoringRules.generalRelevantSkills;

    // Build per-section scores
    final breakdown = <SectionScore>[
      _analyzeContact(sectionMap['contact']!, enableLogging),
      _analyzeSummary(sectionMap['summary']!, enableLogging),
      _analyzeExperience(sectionMap['experience']!, enableLogging),
      _analyzeEducation(sectionMap['education']!, enableLogging),
      _analyzeSkills(
          sectionMap['skills']!, relevantSkills, detectedMajor, enableLogging),
      _analyzeProjects(sectionMap['projects']!, enableLogging),
      _analyzeCertifications(sectionMap['certifications']!, enableLogging),
    ];

    // Calculate total score using ScoringRules.totalMaxScore
    final rawSum =
        breakdown.fold<int>(0, (sum, sec) => sum + sec.achievedScore);
    final totalScore =
        (rawSum * 100 ~/ ScoringRules.totalMaxScore).clamp(0, 100);
    if (enableLogging) {
      developer.log(
          'Total score: $totalScore/100 (raw: $rawSum, breakdown: ${breakdown.map((s) => "${s.sectionName}: ${s.achievedScore}/${s.maxScore}").join(", ")})');
    }

    // Compile and prioritize feedback
    final feedback = <String>[];
    for (var sec in breakdown) {
      for (var msg in sec.feedback) {
        feedback.add('${sec.sectionName}: $msg');
      }
    }
    feedback.sort((a, b) {
      final aSection = a.split(':').first.toLowerCase();
      final bSection = b.split(':').first.toLowerCase();
      final aPriority = ScoringRules.sectionPriorities[aSection] ?? 0;
      final bPriority = ScoringRules.sectionPriorities[bSection] ?? 0;
      final aIsMissing = a.contains('Include') || a.contains('Add');
      final bIsMissing = b.contains('Include') || a.contains('Add');
      if (aIsMissing && !bIsMissing) return -1;
      if (!aIsMissing && bIsMissing) return 1;
      return aPriority.compareTo(bPriority); // Lower priority value first
    });

    // Add general tip about detected major
    if (detectedMajor != null) {
      feedback.add(
          'General: Tailor your resume to highlight $detectedMajor-specific achievements.');
    }

    return input.copyWith(
      score: totalScore,
      major: detectedMajor,
      feedback: feedback,
      sectionBreakdown: breakdown,
    );
  }

  /// Analyzes the contact section for required elements (email, phone, etc.).
  static SectionScore _analyzeContact(String s, bool enableLogging) {
    final fb = <String>[];
    var pts = 0;
    bool hasLinkedIn = false;
    bool hasGitHub = false;
    bool hasPortfolio = false;
    final detectedElements = <String>[];

    if (ScoringRules.emailRegex.hasMatch(s)) {
      pts += ScoringRules.contactEmailScore;
      detectedElements.add('email');
      if (enableLogging) developer.log('Contact: Email detected');
    } else {
      fb.add('Include a professional email address.');
    }

    if (ScoringRules.phoneRegex.hasMatch(s)) {
      pts += ScoringRules.contactPhoneScore;
      detectedElements.add('phone');
      if (enableLogging) developer.log('Contact: Phone detected');
    } else {
      fb.add('Add a contact phone number.');
    }

    final portfolioMatches = ScoringRules.portfolioRegex.allMatches(s).toList();
    for (var match in portfolioMatches) {
      final url = match.group(0)!.toLowerCase();
      if (url.contains('linkedin.com') && !hasLinkedIn) {
        pts += ScoringRules.contactLinkedInScore;
        hasLinkedIn = true;
        detectedElements.add('LinkedIn');
        if (enableLogging) developer.log('Contact: LinkedIn detected');
      } else if (url.contains('github.com') && !hasGitHub) {
        pts += ScoringRules.contactGitHubScore;
        hasGitHub = true;
        detectedElements.add('GitHub');
        if (enableLogging) developer.log('Contact: GitHub detected');
      } else if (!hasPortfolio) {
        pts += ScoringRules.contactPortfolioScore;
        hasPortfolio = true;
        detectedElements.add('portfolio');
        if (enableLogging) developer.log('Contact: Portfolio detected');
      }
    }

    if (detectedElements.isNotEmpty) {
      fb.add('Detected: ${detectedElements.join(", ")}.');
    }

    final missingLinks = <String>[];
    if (!hasLinkedIn) missingLinks.add('LinkedIn');
    if (!hasGitHub) missingLinks.add('GitHub');
    if (!hasPortfolio) missingLinks.add('portfolio');
    if (missingLinks.isNotEmpty) {
      fb.add(
          'Consider adding ${missingLinks.join(", ")} link${missingLinks.length > 1 ? "s" : ""}.');
    }

    final score = SectionScore(
      sectionName: 'Contact Info',
      maxScore: ScoringRules.contactMax,
      achievedScore: pts.clamp(0, ScoringRules.contactMax),
      feedback: fb,
      rawContent: s,
    );
    if (enableLogging) {
      developer.log(
          'Contact score: ${score.achievedScore}/${score.maxScore}, feedback: $fb');
    }
    return score;
  }

  /// Analyzes the summary section for presence and length.
  static SectionScore _analyzeSummary(String s, bool enableLogging) {
    final trimmed = s.trim();
    final fb = <String>[];

    if (trimmed.isEmpty) {
      fb.add('Include a professional summary to highlight your goals.');
      final score = SectionScore(
        sectionName: 'Summary',
        maxScore: ScoringRules.summaryMax,
        achievedScore: 0,
        feedback: fb,
        rawContent: s,
      );
      if (enableLogging) {
        developer
            .log('Summary score: 0/${ScoringRules.summaryMax}, feedback: $fb');
      }
      return score;
    }

    final wc = trimmed.split(RegExp(r'\s+')).length;
    final pts = wc < ScoringRules.summaryWordThreshold
        ? ScoringRules.summaryPartialScore
        : ScoringRules.summaryMax;

    if (wc < ScoringRules.summaryWordThreshold) {
      fb.add(
          'Expand summary to at least ${ScoringRules.summaryWordThreshold} words for better impact.');
    }

    final score = SectionScore(
      sectionName: 'Summary',
      maxScore: ScoringRules.summaryMax,
      achievedScore: pts,
      feedback: fb,
      rawContent: s,
    );
    if (enableLogging) {
      developer.log(
          'Summary score: $pts/${ScoringRules.summaryMax}, word count: $wc, feedback: $fb');
    }
    return score;
  }

  /// Analyzes the experience section for action verbs, date ranges, and detail.
  static SectionScore _analyzeExperience(String s, bool enableLogging) {
    final trimmed = s.trim();
    final fb = <String>[];
    var pts = 0;

    if (trimmed.isEmpty) {
      fb.add('Add detailed Work Experience section.');
      final score = SectionScore(
        sectionName: 'Work Experience',
        maxScore: ScoringRules.experienceMax,
        achievedScore: 0,
        feedback: fb,
        rawContent: s,
      );
      if (enableLogging) {
        developer.log(
            'Experience score: 0/${ScoringRules.experienceMax}, feedback: $fb');
      }
      return score;
    }

    pts += ScoringRules.experiencePartialScore;

    final verbs = ScoringRules.actionVerbs
        .where((v) => trimmed.toLowerCase().contains(v))
        .toList();
    final verbPoints = (verbs.length * ScoringRules.experienceVerbScore).clamp(
        0,
        ScoringRules.experienceVerbThreshold *
            ScoringRules.experienceVerbScore);
    pts += verbPoints;
    if (verbs.length < ScoringRules.experienceVerbThreshold) {
      fb.add(
          'Use more action verbs (e.g., developed, managed) to strengthen descriptions.');
    }

    final dateMatches =
        ScoringRules.dateRangeRegex.allMatches(trimmed).toList();
    if (dateMatches.isNotEmpty) {
      pts += ScoringRules.experienceDateRangeScore;
      if (enableLogging)
        developer.log(
            'Experience: Date range detected: ${dateMatches.map((m) => m.group(0)).join(", ")}');
    } else {
      fb.add('Include clear date ranges (e.g., 2020-2022).');
    }

    final wc = trimmed.split(RegExp(r'\s+')).length;
    if (wc < 50) {
      fb.add('Expand role descriptions with quantifiable achievements.');
    }

    final score = SectionScore(
      sectionName: 'Work Experience',
      maxScore: ScoringRules.experienceMax,
      achievedScore: pts.clamp(0, ScoringRules.experienceMax),
      feedback: fb,
      matchedContent: verbs,
      rawContent: s,
    );
    if (enableLogging) {
      developer.log(
          'Experience score: ${score.achievedScore}/${score.maxScore}, verbs: ${verbs.length}, dates: ${dateMatches.length}, words: $wc, feedback: $fb');
    }
    return score;
  }

  /// Analyzes the education section for institution, degree, and graduation year.
  static SectionScore _analyzeEducation(String s, bool enableLogging) {
    final lower = s.toLowerCase();
    final fb = <String>[];
    var pts = 0;

    if (s.trim().isEmpty) {
      fb.add('Include your education history with institution names.');
    } else {
      pts += ScoringRules.educationBaseScore;
    }

    if (RegExp(r'\b(bachelor|master|associate|ph\.?d)\b.*\b(of|in)\b',
            caseSensitive: false)
        .hasMatch(s)) {
      pts += ScoringRules.educationDegreeScore;
      if (enableLogging) developer.log('Education: Degree detected');
    } else {
      fb.add('Specify your degree (e.g., Bachelor’s).');
    }

    if (ScoringRules.gradYearRegex.hasMatch(s)) {
      pts += ScoringRules.educationYearScore;
      if (enableLogging) developer.log('Education: Graduation year detected');
    } else {
      fb.add('Include graduation year.');
    }

    final score = SectionScore(
      sectionName: 'Education',
      maxScore: ScoringRules.educationMax,
      achievedScore: pts.clamp(0, ScoringRules.educationMax),
      feedback: fb,
      rawContent: s,
    );
    if (enableLogging) {
      developer.log(
          'Education score: ${score.achievedScore}/${score.maxScore}, feedback: $fb');
    }
    return score;
  }

  /// Analyzes the skills section for relevant skills based on the detected major.
  static SectionScore _analyzeSkills(String s, List<String> relevant,
      String? detectedMajor, bool enableLogging) {
    final fb = <String>[];
    final found = <String>[];
    var pts = 0;

    if (s.trim().isNotEmpty) {
      pts += ScoringRules.skillsBaseScore;
    } else {
      fb.add('List relevant skills, e.g., ${relevant.take(3).join(", ")}.');
    }

    // Tokenize the skills section to match individual skills
    final tokens =
        s.toLowerCase().split(RegExp(r'[,\s]+')).map((t) => t.trim()).toList();
    final skillMatches = <String>{};

    for (final token in tokens) {
      // Check if the token maps to a relevant skill category via ScoringRules.skillToCategory
      final category = ScoringRules.skillToCategory[token];
      if (category != null &&
          relevant.contains(category) &&
          !skillMatches.contains(category)) {
        skillMatches.add(category);
        found.add(category);
      }
      // Direct match against relevant skills
      if (relevant.any((skill) => skill.toLowerCase() == token) &&
          !skillMatches.contains(token)) {
        skillMatches.add(token);
        found.add(token);
      }
    }

    final skillPoints = (found.length * ScoringRules.pointsPerSkill)
        .clamp(0, ScoringRules.skillsCap);
    pts += skillPoints;

    if (found.isEmpty && s.trim().isNotEmpty) {
      fb.add(
          'List relevant skills for your field, e.g., ${relevant.take(3).join(", ")}.');
    } else if (found.length < 3 && detectedMajor != null) {
      final missing = ScoringRules.majorRelevantSkills[detectedMajor]!
          .where((sk) => !found.contains(sk))
          .take(2);
      if (missing.isNotEmpty) {
        fb.add('Consider adding $detectedMajor skills: ${missing.join(", ")}.');
      }
    }

    final score = SectionScore(
      sectionName: 'Skills',
      maxScore: ScoringRules.skillsMax,
      achievedScore: pts.clamp(0, ScoringRules.skillsMax),
      feedback: fb,
      matchedContent: found,
      rawContent: s,
    );
    if (enableLogging) {
      developer.log(
          'Skills score: ${score.achievedScore}/${score.maxScore}, found: $found, feedback: $fb');
    }
    return score;
  }

  /// Analyzes the projects section for presence and detail.
  static SectionScore _analyzeProjects(String s, bool enableLogging) {
    final trimmed = s.trim();
    final fb = <String>[];

    if (trimmed.isEmpty) {
      fb.add('List projects with detailed descriptions.');
      final score = SectionScore(
        sectionName: 'Projects',
        maxScore: ScoringRules.projectsMax,
        achievedScore: 0,
        feedback: fb,
        rawContent: s,
      );
      if (enableLogging) {
        developer.log(
            'Projects score: 0/${ScoringRules.projectsMax}, feedback: $fb');
      }
      return score;
    }

    final wc = trimmed.split(RegExp(r'\s+')).length;
    if (wc < 20) {
      fb.add('Expand project descriptions with more details.');
    }

    final score = SectionScore(
      sectionName: 'Projects',
      maxScore: ScoringRules.projectsMax,
      achievedScore: ScoringRules.projectsMax,
      feedback: fb,
      rawContent: s,
    );
    if (enableLogging) {
      developer.log(
          'Projects score: ${score.achievedScore}/${score.maxScore}, word count: $wc, feedback: $fb');
    }
    return score;
  }

  /// Analyzes the certifications section for relevant certifications.
  static SectionScore _analyzeCertifications(String s, bool enableLogging) {
    final matches = ScoringRules.certificationRegex
        .allMatches(s)
        .map((m) => m.group(0)!.trim())
        .toList();
    final fb = <String>[];

    var pts = 0;
    if (matches.isNotEmpty) {
      pts = ScoringRules.certificationsMax;
      if (enableLogging)
        developer.log('Certifications: Matches detected: $matches');
    } else {
      fb.add('Include any relevant certifications you have earned.');
    }

    final score = SectionScore(
      sectionName: 'Certifications',
      maxScore: ScoringRules.certificationsMax,
      achievedScore: pts,
      feedback: fb,
      matchedContent: matches,
      rawContent: s,
    );
    if (enableLogging) {
      developer.log(
          'Certifications score: ${score.achievedScore}/${score.maxScore}, matches: $matches, feedback: $fb');
    }
    return score;
  }
}
