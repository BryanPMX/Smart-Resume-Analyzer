import '../models/resume.dart';
import '../models/section_score.dart';
import '../services/section_detector_service.dart';
import '../services/major_detector.dart';
import '../utils/scoring_rules.dart';

/// Service that analyzes resume text and computes a score with detailed section feedback.
class ScoringService {
  static Resume analyze(Resume input) {
    final rawText = input.fullText;
    final sections = SectionDetectorService.detectSections(rawText);
    final detectedMajor = MajorDetector.detectMajor(rawText);

    final relevantSkills = (detectedMajor != null &&
        ScoringRules.majorRelevantSkills.containsKey(detectedMajor))
        ? ScoringRules.majorRelevantSkills[detectedMajor]!
        : ScoringRules.generalRelevantSkills;

    final breakdown = <SectionScore>[
      _analyzeContact(sections['contact'] ?? ''),
      _analyzeSummary(sections['summary'] ?? ''),
      _analyzeExperience(sections['experience'] ?? ''),
      _analyzeEducation(sections['education'] ?? ''),
      _analyzeSkills(sections['skills'] ?? '', relevantSkills),
      _analyzeProjects(sections['projects'] ?? ''),
      _analyzeCertifications(sections['certifications'] ?? ''),
    ];

    final totalScore =
    breakdown.fold(0, (sum, sec) => sum + sec.achievedScore).clamp(0, 100);
    final feedback = breakdown.expand((sec) => sec.feedback).toList();

    return input.copyWith(
      score: totalScore,
      major: detectedMajor,
      feedback: feedback,
      sectionBreakdown: breakdown,
    );
  }

  static SectionScore _analyzeContact(String section) {
    final feedback = <String>[];
    int score = 0;

    if (ScoringRules.emailRegex.hasMatch(section)) {
      score += ScoringRules.contactEmailScore;
    }
    if (ScoringRules.phoneRegex.hasMatch(section)) {
      score += ScoringRules.contactPhoneScore;
    }
    if (section.contains('linkedin.com')) {
      score += ScoringRules.contactLinkedInScore;
    }
    if (section.contains('github.com')) {
      score += ScoringRules.contactGitHubScore;
    }
    if (ScoringRules.portfolioRegex.hasMatch(section)) {
      score += ScoringRules.contactPortfolioScore;
    }

    if (score < ScoringRules.contactMax) {
      feedback.add('Add complete contact info (email, phone, LinkedIn, GitHub, portfolio).');
    }

    return SectionScore(
      sectionName: 'Contact Info',
      maxScore: ScoringRules.contactMax,
      achievedScore: score.clamp(0, ScoringRules.contactMax),
      feedback: feedback,
      rawContent: section,
    );
  }

  static SectionScore _analyzeSummary(String section) {
    final trimmed = section.trim();
    final feedback = <String>[];

    if (trimmed.isEmpty) {
      feedback.add('Add a professional summary to highlight your goals.');
      return SectionScore(
        sectionName: 'Summary',
        maxScore: ScoringRules.summaryMax,
        achievedScore: 0,
        feedback: feedback,
        rawContent: section,
      );
    }

    final wordCount = trimmed.split(RegExp(r'\s+')).length;
    final achieved = wordCount < ScoringRules.summaryWordThreshold
        ? ScoringRules.summaryPartialScore
        : ScoringRules.summaryMax;

    if (wordCount < ScoringRules.summaryWordThreshold) {
      feedback.add('Expand your summary with impactful language.');
    }

    return SectionScore(
      sectionName: 'Summary',
      maxScore: ScoringRules.summaryMax,
      achievedScore: achieved,
      feedback: feedback,
      rawContent: section,
    );
  }

  static SectionScore _analyzeExperience(String section) {
    final feedback = <String>[];
    final trimmed = section.trim();

    if (trimmed.isEmpty) {
      feedback.add('Include a Work Experience section with details.');
      return SectionScore(
        sectionName: 'Work Experience',
        maxScore: ScoringRules.experienceMax,
        achievedScore: 0,
        feedback: feedback,
        rawContent: section,
      );
    }

    final verbs = ScoringRules.actionVerbs
        .where((v) => trimmed.contains(v))
        .toList();

    final achieved = verbs.length >= ScoringRules.experienceVerbThreshold
        ? ScoringRules.experienceMax
        : ScoringRules.experiencePartialScore;

    if (verbs.length < ScoringRules.experienceVerbThreshold) {
      feedback.add('Use more action verbs (e.g., developed, managed).');
    }

    return SectionScore(
      sectionName: 'Work Experience',
      maxScore: ScoringRules.experienceMax,
      achievedScore: achieved,
      feedback: feedback,
      matchedContent: verbs,
      rawContent: section,
    );
  }

  static SectionScore _analyzeEducation(String section) {
    final feedback = <String>[];
    int score = 0;
    final lower = section.toLowerCase();

    if (!lower.contains('education') && !lower.contains('university')) {
      feedback.add('Add your education history.');
    } else {
      score += ScoringRules.educationBaseScore;
    }

    if (RegExp(r'(bachelor|master|associate|ph\.?d)', caseSensitive: false).hasMatch(section)) {
      score += ScoringRules.educationDegreeScore;
    }
    if (ScoringRules.gradYearRegex.hasMatch(section)) {
      score += ScoringRules.educationYearScore;
    }

    return SectionScore(
      sectionName: 'Education',
      maxScore: ScoringRules.educationMax,
      achievedScore: score.clamp(0, ScoringRules.educationMax),
      feedback: feedback,
      rawContent: section,
    );
  }

  static SectionScore _analyzeSkills(String section, List<String> relevantSkills) {
    final feedback = <String>[];
    final found = <String>[];

    for (final skill in relevantSkills) {
      if (section.toLowerCase().contains(skill.toLowerCase())) {
        found.add(skill[0].toUpperCase() + skill.substring(1));
      }
    }

    if (found.isEmpty) {
      feedback.add('List relevant skills based on your major or field.');
    }

    final achieved = (found.length.clamp(0, ScoringRules.skillsCap)) *
        ScoringRules.pointsPerSkill;

    return SectionScore(
      sectionName: 'Skills',
      maxScore: ScoringRules.skillsMax,
      achievedScore: achieved,
      feedback: feedback,
      matchedContent: found,
      rawContent: section,
    );
  }

  static SectionScore _analyzeProjects(String section) {
    final trimmed = section.trim();
    final feedback = <String>[];

    if (trimmed.isEmpty || trimmed.length < 40) {
      feedback.add('List relevant projects with descriptions.');
      return SectionScore(
        sectionName: 'Projects',
        maxScore: ScoringRules.projectsMax,
        achievedScore: 0,
        feedback: feedback,
        rawContent: section,
      );
    }

    return SectionScore(
      sectionName: 'Projects',
      maxScore: ScoringRules.projectsMax,
      achievedScore: ScoringRules.projectsMax,
      feedback: [],
      rawContent: section,
    );
  }

  static SectionScore _analyzeCertifications(String section) {
    final feedback = <String>[];
    final matches = ScoringRules.certificationRegex
        .allMatches(section)
        .map((m) => m.group(0)!.trim())
        .toList();

    if (matches.isEmpty) {
      feedback.add('Include any relevant certifications you have earned.');
    }

    final achieved = (matches.length * ScoringRules.certificationsMax)
        .clamp(0, ScoringRules.certificationsMax)
        .toInt();

    return SectionScore(
      sectionName: 'Certifications',
      maxScore: ScoringRules.certificationsMax,
      achievedScore: achieved,
      feedback: feedback,
      matchedContent: matches,
      rawContent: section,
    );
  }
}

