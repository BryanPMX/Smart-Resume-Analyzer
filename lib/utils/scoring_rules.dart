// scoring_rules.dart
import 'dart:developer' as developer;
import '../services/major_detector.dart';

/// Centralized configuration for resume scoring weights, keywords, and rule parameters.
/// Supports both general and major-specific skill sets for tailored scoring, used by
/// `ScoringService` to evaluate resumes. Ensures consistency with `MajorDetector` and
/// other services through validation and standardized patterns.
class ScoringRules {
  // ===================== Scoring Constants =====================
  /// Total maximum score across all sections, used for normalization in `ScoringService`.
  static const int totalMaxScore = 100;

  // ===================== Section Weights =====================
  static const int contactMax = 15;
  static const int summaryMax = 10;
  static const int experienceMax = 20;
  static const int educationMax = 15;
  static const int skillsMax = 20;
  static const int projectsMax = 15;
  static const int certificationsMax = 5;

  /// Validates that section weights sum to `totalMaxScore`.
  static void _validateSectionWeights({bool enableLogging = false}) {
    final sum = contactMax +
        summaryMax +
        experienceMax +
        educationMax +
        skillsMax +
        projectsMax +
        certificationsMax;
    if (sum != totalMaxScore) {
      final message =
          'Section weights sum ($sum) does not match totalMaxScore ($totalMaxScore)';
      if (enableLogging) {
        developer.log('Validation Error: $message');
      }
      throw StateError(message);
    }
  }

  // ===================== Feedback Sorting Priorities =====================
  /// Defines the priority order for sorting feedback in `ScoringService`.
  /// Lower values indicate higher priority (displayed first).
  static const Map<String, int> sectionPriorities = {
    'contact': 1,
    'summary': 2,
    'experience': 3,
    'education': 4,
    'skills': 5,
    'projects': 6,
    'certifications': 7,
  };

  // ===================== Contact Scoring =====================
  /// Matches email addresses, resilient to OCR noise and surrounding characters.
  static final RegExp emailRegex = RegExp(
    r'(?:[\s$\cdot|]*)\b[\w.%+-]+@[\w.-]+\.[a-z]{2,}\b(?:[\s$\cdot|]*)',
    caseSensitive: false,
  );

  /// Matches phone numbers, including international formats and various separators.
  static final RegExp phoneRegex = RegExp(
    r'(?<![\w\$])(?:[\s$\cdot|]*)\b(\+\d{1,3}[-.\s]?)?(\d{3}[-.\s]?\d{3}[-.\s]?\d{4})\b(?![@\w])(?:[\s$\cdot|]*)',
    caseSensitive: false,
  );

  static const int contactEmailScore = 7;
  static const int contactPhoneScore = 5;
  static const int contactLinkedInScore = 3;
  static const int contactGitHubScore = 2;
  static const int contactPortfolioScore = 2;

  /// Matches LinkedIn, GitHub, portfolio URLs, or custom portfolio identifiers.
  static final RegExp portfolioRegex = RegExp(
    r'(?:[\s$\cdot|]*)\b(?:https?://)?(?:(?:www\.)?(linkedin|github)\.com/[^\s]+|portfolio|netlify\.app|[A-Za-z0-9_-]{3,20}(?=\s|$))\b(?:[\s$\cdot|]*)',
    caseSensitive: false,
  );

  // ===================== Summary Scoring =====================
  static const int summaryWordThreshold = 30;
  static const int summaryPartialScore = 5;

  // ===================== Experience Scoring =====================
  static const int experienceVerbThreshold = 3;
  static const int experiencePartialScore = 10;
  static const int experienceVerbScore = 2;
  static const int experienceDateRangeScore = 3;

  /// Expanded list of action verbs for Work Experience scoring.
  static const List<String> actionVerbs = [
    'developed',
    'managed',
    'led',
    'built',
    'designed',
    'created',
    'implemented',
    'optimized',
    'analyzed',
    'automated',
    'oversaw',
    'delivered',
    'mentored',
    'solved',
    'coordinated',
    'executed',
    'improved',
    'streamlined',
    'facilitated',
    'directed',
  ];

  /// Matches date ranges (e.g., "2020-2022", "August 2021-present").
  static final RegExp dateRangeRegex = RegExp(
    r'\b(?:january|february|march|april|may|june|july|august|september|october|november|december)?\s*20\d{2}\s*(?:-|to)\s*(?:present|20\d{2})\b',
    caseSensitive: false,
  );

  // ===================== Education Scoring =====================
  static const int educationBaseScore = 10;
  static const int educationDegreeScore = 3;
  static const int educationYearScore = 2;

  /// Matches Graduation years, including within phrases (e.g., "Graduating December 2025").
  static final RegExp gradYearRegex = RegExp(
    r'(?:graduating\s+)?(?:january|february|march|april|may|june|july|august|september|october|november|december)?\s*(20\d{2})',
    caseSensitive: false,
  );

  // ===================== Skills Scoring =====================
  static const int skillsCap = 10;
  static const int skillsBaseScore = 10;
  static const int pointsPerSkill = 2;

  /// Mapping of specific skills to broader categories for better matching.
  static const Map<String, String> skillToCategory = {
    'golang': 'programming languages',
    'python': 'programming languages',
    'java': 'programming languages',
    'c': 'programming languages',
    'scala': 'programming languages',
    'dart': 'programming languages',
    'html': 'programming languages',
    'javascript': 'programming languages',
    'css': 'programming languages',
    'sql': 'programming languages',
    'bash': 'programming languages',
    'git': 'version control',
    'github': 'version control',
    'pytorch': 'machine learning',
    'tensorflow': 'machine learning',
    'numpy': 'data analysis',
    'docker': 'cloud computing',
    'node.js': 'software development',
    'mysql': 'database management',
    'reactjs': 'software development',
    'pandas': 'data analysis',
    'springboot': 'software development',
    'maven': 'software development',
    'flutter': 'software development',
    'advanced object-oriented programming': 'object-oriented programming',
    'data structures': 'data structures',
    'computer security': 'cybersecurity',
    'operating systems': 'operating systems',
    'machine learning': 'machine learning',
    'artificial intelligence': 'machine learning',
    'database systems': 'database management',
  };

  // ===================== Projects Scoring =====================
  /// Matches project section headings (e.g., "PROJECTS", "Project").
  static final RegExp projectSectionRegex = RegExp(
    r'projects?',
    caseSensitive: false,
  );

  // ===================== Certifications Scoring =====================
  /// Matches certification phrases (e.g., "AWS Certified Developer", "Certified ScrumMaster").
  static final RegExp certificationRegex = RegExp(
    r'(certified\s+[a-z\s]+(?:professional|practitioner|developer|engineer|associate|master)|[a-z\s]+(?:certification|certificate)\s*(?:in|of|for)\s+[a-z\s]+)',
    caseSensitive: false,
  );

  // ===================== Fallback Skill Keywords =====================
  /// General skills used when no known major is detected.
  static const List<String> generalRelevantSkills = [
    'communication',
    'teamwork',
    'leadership',
    'management',
    'problem solving',
    'project management',
    'research',
    'organization',
  ];

  // ===================== Major-Specific Skill Keywords =====================
  /// Map from academic major to its top relevant skills, aligned with `MajorDetector`.
  static const Map<String, List<String>> majorRelevantSkills = {
    'Computer Science': [
      'programming languages',
      'data structures',
      'algorithms',
      'operating systems',
      'database management',
      'software development',
      'object-oriented programming',
      'version control',
      'computer networks',
      'cloud computing',
      'machine learning',
      'cybersecurity',
      'software testing',
      'problem-solving',
      'critical thinking',
      'communication skills',
      'teamwork',
    ],
    'Business Administration': [
      'communication skills',
      'leadership',
      'teamwork',
      'customer service',
      'organization',
      'time management',
      'multitasking',
      'attention to detail',
      'critical thinking',
      'strategic planning',
      'project management',
      'administration',
      'computer literacy',
      'work under pressure',
      'problem-solving',
    ],
    'Mechanical Engineering': [
      'cad software',
      'mechanical design',
      'finite element analysis',
      'gd&t',
      'material science',
      'thermodynamics',
      'fluid mechanics',
      'matlab',
      'prototyping',
      'machining',
      'project management',
      'analytical skills',
      'problem-solving',
      'creativity',
      'adaptability',
      'communication',
    ],
    'Nursing': [
      'patient care',
      'vital signs monitoring',
      'medication administration',
      'iv therapy',
      'wound care',
      'infection control',
      'patient assessment',
      'electronic medical records',
      'patient education',
      'time management',
      'attention to detail',
      'emotional stability',
      'physical stamina',
      'compassion',
      'communication skills',
    ],
    'Electrical Engineering': [
      'circuit design',
      'pcb layout',
      'embedded systems',
      'signal processing',
      'control systems',
      'power systems',
      'electronics troubleshooting',
      'programming',
      'cad tools',
      'math skills',
      'problem-solving',
      'project management',
      'continuous learning',
      'communication skills',
    ],
    'Psychology': [
      'counseling',
      'active listening',
      'empathy',
      'research methods',
      'statistical analysis',
      'data analysis',
      'analytical skills',
      'observation',
      'critical thinking',
      'ethics',
      'interpersonal skills',
      'patience',
      'communication skills',
      'problem-solving',
      'cultural competence',
    ],
    'Biology': [
      'laboratory techniques',
      'molecular biology',
      'cell culture',
      'microscopy',
      'biochemical assays',
      'field research',
      'data analysis',
      'scientific writing',
      'research methods',
      'attention to detail',
      'bioinformatics',
      'critical thinking',
      'lab safety',
      'teamwork',
      'presentation skills',
    ],
    'Economics': [
      'statistical analysis',
      'econometrics',
      'data analysis',
      'stata',
      'microeconomics',
      'macroeconomics',
      'analytical reasoning',
      'critical thinking',
      'mathematical modeling',
      'forecasting',
      'financial literacy',
      'policy analysis',
      'research skills',
      'communication skills',
      'excel',
    ],
    'Accounting': [
      'attention to detail',
      'GAAP knowledge',
      'financial reporting',
      'account reconciliation',
      'auditing',
      'tax preparation',
      'budgeting',
      'accounts payable',
      'accounts receivable',
      'quickbooks',
      'excel',
      'analytical skills',
      'math skills',
      'organizational skills',
      'communication skills',
    ],
    'Civil Engineering': [
      'cad',
      'structural analysis',
      'construction management',
      'geotechnical engineering',
      'surveying',
      'transportation engineering',
      'hydrology',
      'building codes',
      'project management',
      'gis',
      'blueprint reading',
      'material science',
      'problem-solving',
      'math skills',
      'communication',
    ],
    'Education': [
      'curriculum development',
      'lesson planning',
      'classroom management',
      'instructional strategies',
      'assessment design',
      'educational technology',
      'public speaking',
      'communication skills',
      'patience',
      'adaptability',
      'special education',
      'collaboration',
      'mentoring',
      'cultural competence',
      'organizational skills',
    ],
    'Finance': [
      'financial analysis',
      'financial modeling',
      'budgeting',
      'investment analysis',
      'portfolio management',
      'risk management',
      'valuation',
      'excel',
      'data analysis',
      'regulatory compliance',
      'accounting principles',
      'quantitative analysis',
      'decision-making',
      'communication skills',
      'attention to detail',
    ],
    'Political Science': [
      'research',
      'critical thinking',
      'policy analysis',
      'government knowledge',
      'public speaking',
      'writing',
      'persuasion',
      'qualitative research',
      'statistical analysis',
      'international relations',
      'legal understanding',
      'campaign strategy',
      'diplomacy',
      'advocacy',
      'collaboration',
    ],
    'Marketing': [
      'seo',
      'sem',
      'content creation',
      'social media marketing',
      'email marketing',
      'crm',
      'analytics',
      'google analytics',
      'market research',
      'branding',
      'copywriting',
      'graphic design',
      'cms management',
      'creativity',
      'project management',
    ],
    'Communications': [
      'public speaking',
      'writing',
      'media relations',
      'social media',
      'storytelling',
      'persuasion',
      'crisis communication',
      'interpersonal skills',
      'editing',
      'content creation',
      'marketing communications',
      'research',
      'event planning',
      'cultural awareness',
      'collaboration',
    ],
    'Chemistry': [
      'laboratory techniques',
      'analytical chemistry',
      'organic synthesis',
      'instrumental analysis',
      'chemical safety',
      'wet lab skills',
      'data analysis',
      'problem-solving',
      'attention to detail',
      'quantitative analysis',
      'laboratory management',
      'teamwork',
      'scientific writing',
      'critical thinking',
      'computational tools',
    ],
    'Information Technology': [
      'technical support',
      'networking',
      'system administration',
      'cybersecurity',
      'cloud computing',
      'database management',
      'scripting',
      'hardware maintenance',
      'software configuration',
      'ITIL processes',
      'troubleshooting',
      'customer service',
      'project management',
      'attention to detail',
      'continuous learning',
    ],
    'Graphic Design': [
      'adobe photoshop',
      'adobe illustrator',
      'adobe indesign',
      'typography',
      'color theory',
      'layout design',
      'branding',
      'ui/ux principles',
      'creativity',
      'attention to detail',
      'time management',
      'print design',
      'digital illustration',
      'web design',
      'communication',
    ],
    'Mathematics': [
      'problem-solving',
      'logical reasoning',
      'statistical analysis',
      'mathematical modeling',
      'calculus',
      'algebra',
      'discrete mathematics',
      'computational skills',
      'data analysis',
      'number theory',
      'attention to detail',
      'proof writing',
      'abstract thinking',
      'critical thinking',
      'persistence',
    ],
    'Environmental Science': [
      'environmental impact assessment',
      'field research',
      'gis',
      'water analysis',
      'soil analysis',
      'ecology',
      'sustainability',
      'climate science',
      'regulatory compliance',
      'data analysis',
      'remote sensing',
      'report writing',
      'critical thinking',
      'public outreach',
      'laboratory skills',
    ],
    'English': [
      'writing',
      'editing',
      'critical thinking',
      'literary analysis',
      'research',
      'communication skills',
      'public speaking',
      'proofreading',
      'content creation',
      'storytelling',
      'cultural awareness',
      'collaboration',
      'time management',
      'attention to detail',
      'creativity',
    ],
    'History': [
      'research',
      'critical thinking',
      'writing',
      'archival research',
      'historical analysis',
      'attention to detail',
      'communication skills',
      'public speaking',
      'cultural awareness',
      'data interpretation',
      'analytical skills',
      'presentation skills',
      'collaboration',
      'time management',
      'persistence',
    ],
    'Sociology': [
      'research methods',
      'statistical analysis',
      'data analysis',
      'critical thinking',
      'writing',
      'survey design',
      'interviewing',
      'cultural competence',
      'social theory',
      'policy analysis',
      'communication skills',
      'collaboration',
      'empathy',
      'analytical skills',
      'presentation skills',
    ],
  };

  /// Validates that all majors defined in `MajorDetector` have corresponding skill sets.
  /// Throws an exception if there are mismatches to ensure scoring consistency.
  static void validateMajorSkills({bool enableLogging = false}) {
    final detectorMajors = MajorDetector.knownMajors.toSet();
    final skillMajors = majorRelevantSkills.keys.toSet();

    final missingInSkills = detectorMajors.difference(skillMajors);
    if (missingInSkills.isNotEmpty) {
      final message =
          'Majors in MajorDetector missing from majorRelevantSkills: $missingInSkills';
      if (enableLogging) {
        developer.log('Validation Error: $message');
      }
      throw StateError(message);
    }

    final missingInDetector = skillMajors.difference(detectorMajors);
    if (missingInDetector.isNotEmpty) {
      final message =
          'Majors in majorRelevantSkills missing from MajorDetector: $missingInDetector';
      if (enableLogging) {
        developer.log('Validation Error: $message');
      }
      throw StateError(message);
    }
  }

  /// Logs regex pattern details for debugging detection issues.
  static void _logRegexPatterns({bool enableLogging = false}) {
    if (!enableLogging) return;
    developer.log('ScoringRules Regex Patterns:');
    developer.log('  emailRegex: ${emailRegex.pattern}');
    developer.log('  phoneRegex: ${phoneRegex.pattern}');
    developer.log('  portfolioRegex: ${portfolioRegex.pattern}');
    developer.log('  gradYearRegex: ${gradYearRegex.pattern}');
    developer.log('  dateRangeRegex: ${dateRangeRegex.pattern}');
    developer.log('  projectSectionRegex: ${projectSectionRegex.pattern}');
    developer.log('  certificationRegex: ${certificationRegex.pattern}');
  }

  /// Initializes and validates the scoring rules configuration.
  /// Should be called at application startup to ensure consistency.
  static void initialize({bool enableLogging = false}) {
    _validateSectionWeights(enableLogging: enableLogging);
    validateMajorSkills(enableLogging: enableLogging);
    _logRegexPatterns(enableLogging: enableLogging);
    if (enableLogging) {
      developer.log('ScoringRules initialized successfully');
    }
  }
}
