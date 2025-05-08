// The University of Texas at El Paso: Bryan Perez

import 'dart:developer' as developer;
import '../models/major.dart';

/// Centralized configuration for resume scoring weights, keywords, and rule parameters.
class ScoringRules {
  // ───────────────────────────────────────────────────────
  // SECTION 1: Section Weights & Validation
  // ───────────────────────────────────────────────────────

  /// Total maximum score across all sections.
  static const int totalMaxScore = 100;

  static const int contactMax        = 15;
  static const int summaryMax        = 10;
  static const int experienceMax     = 20;
  static const int educationMax      = 15;
  static const int skillsMax         = 20;
  static const int projectsMax       = 15;
  static const int certificationsMax =  5;

  /// Ensures the sum of all section maxima equals [totalMaxScore].
  static void _validateSectionWeights({bool enableLogging = false}) {
    final sum = contactMax +
        summaryMax +
        experienceMax +
        educationMax +
        skillsMax +
        projectsMax +
        certificationsMax;
    if (sum != totalMaxScore) {
      final msg = 'Section weights sum ($sum) ≠ totalMaxScore ($totalMaxScore)';
      if (enableLogging) developer.log('Weight Validation Error: $msg');
      throw StateError(msg);
    }
  }

  // ───────────────────────────────────────────────────────
  // SECTION 2: Feedback Priorities
  // ───────────────────────────────────────────────────────

  /// Order in which feedback should be shown (lower=higher priority).
  static const Map<String, int> sectionPriorities = {
    'contact':        1,
    'summary':        2,
    'experience':     3,
    'education':      4,
    'skills':         5,
    'projects':       6,
    'certifications': 7,
  };

  // ───────────────────────────────────────────────────────
  // SECTION 3: Common Regex Helpers
  // ───────────────────────────────────────────────────────

  static const String _monthNames =
      r'(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?'
      r'|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)';

  /// Matches date ranges like "August 2021–present" or "2020–2022".
  static final RegExp dateRangeRegex = RegExp(
    r'\b' + _monthNames + r'\s+\d{4}\s*[-–]\s*(?:present|\d{4})\b',
    caseSensitive: false,
  );

  /// Matches graduation years, e.g. "Graduating December 2025"
  static final RegExp gradYearRegex = RegExp(
    r'\b(?:graduating\s+)?' + _monthNames + r'?\s*(20\d{2})\b',
    caseSensitive: false,
  );

  // ───────────────────────────────────────────────────────
  // SECTION 4: Contact Scoring Patterns
  // ───────────────────────────────────────────────────────

  static final RegExp emailRegex = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp phoneRegex = RegExp(
    r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
    caseSensitive: false,
  );

  static final RegExp portfolioRegex = RegExp(
    r'(?:https?://)?(?:www\.)?(?:linkedin\.com|github\.com|behance\.net|dribbble\.com|[A-Z0-9-]+\.[A-Z]{2,})(?:/[A-Z0-9-]+)?',
    caseSensitive: false,
  );

  static const int contactEmailScore     = 7;
  static const int contactPhoneScore     = 5;
  static const int contactLinkedInScore  = 3;
  static const int contactGitHubScore    = 2;
  static const int contactPortfolioScore= 2;

  /// Matches common certification names.
  static final RegExp certificationRegex = RegExp(
    r'(?:certified\s+[a-zA-Z\s]+(?:professional|practitioner|developer|engineer|associate|master)|'
    r'[a-zA-Z\s]+(?:certification|certificate)\s*(?:in|of|for)\s+[a-zA-Z\s]+)',
    caseSensitive: false,
  );

  // ───────────────────────────────────────────────────────
  // SECTION 5: Summary Scoring
  // ───────────────────────────────────────────────────────

  static const int summaryWordThreshold = 30;
  static const int summaryPartialScore  =  5;

  // ───────────────────────────────────────────────────────
  // SECTION 6: Experience Scoring
  // ───────────────────────────────────────────────────────

  static const int experiencePartialScore    = 10;
  static const int experienceVerbThreshold  =  3;
  static const int experienceVerbScore      =  2;
  static const int experienceDateRangeScore =  5;

  static const List<String> actionVerbs = [
    'developed','managed','led','built','designed','created',
    'implemented','optimized','analyzed','automated','oversaw',
    'delivered','mentored','solved','coordinated','executed',
    'improved','streamlined','facilitated','directed',
  ];

  // ───────────────────────────────────────────────────────
  // SECTION 7: Education Scoring
  // ───────────────────────────────────────────────────────

  static const int educationBaseScore   = 10;
  static const int educationDegreeScore =  3;
  static const int educationYearScore   =  2;

  // ───────────────────────────────────────────────────────
  // SECTION 8: Skills Scoring Helpers
  // ───────────────────────────────────────────────────────

  static const int skillsBaseScore = 10;
  static const int skillsCap       = 10;
  static const int pointsPerSkill  =  2;

  /// Fallback when no major is detected.
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

  /// Maps raw tokens → normalized categories.
  static const Map<String, String> skillToCategory = {
    'python': 'programming languages',
    'java': 'programming languages',
    'dart': 'programming languages',
    // …etc…
  };

  // ───────────────────────────────────────────────────────
  // SECTION 9: Major-Specific Skills & Validation
  // ───────────────────────────────────────────────────────

  /// Map from each `Major` enum to its top skill categories.
  /// (Paste your full lists here, keyed by `Major` rather than String.)
  static const Map<Major, List<String>> majorRelevantSkills = {
    Major.computerScience:['programming languages',
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
  'teamwork'],
    Major.businessAdministration: ['communication skills',
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
    Major.mechanicalEngineering: ['cad software',
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
    Major.nursing: [
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
    Major.electricalEngineering: [
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
    Major.psychology: [
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
    Major.biology: [
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
    Major.economics: [
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
    Major.accounting: [
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
    Major.civilEngineering: [
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
    Major.education: [
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
    Major.finance: [
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
    Major.politicalScience: [
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
    Major.marketing: [
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
    Major.communications: [
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
    Major.chemistry: [
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
    Major.informationTechnology: [
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
    Major.graphicDesign: [
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
    Major.mathematics: [
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
    Major.environmentalScience: [
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
    Major.english: [
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
    Major.history: [
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
    Major.sociology: [
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

  /// Ensures every `Major` from the enum has a skills entry.
  static void validateMajorSkills({bool enableLogging = false}) {
    final detectorSet = Major.values.toSet();
    final skillSet    = majorRelevantSkills.keys.toSet();

    final missingInSkills   = detectorSet.difference(skillSet);
    final missingInDetector = skillSet.difference(detectorSet);

    if (missingInSkills.isNotEmpty) {
      final msg = 'Majors missing in skills map: $missingInSkills';
      if (enableLogging) developer.log('Validation Error: $msg');
      throw StateError(msg);
    }
    if (missingInDetector.isNotEmpty) {
      final msg = 'Skills map has unknown majors: $missingInDetector';
      if (enableLogging) developer.log('Validation Error: $msg');
      throw StateError(msg);
    }
  }

  // ───────────────────────────────────────────────────────
  // SECTION 10: Startup Initialization
  // ───────────────────────────────────────────────────────

  /// Must be called once at app startup to sanity-check everything.
  static void initialize({bool enableLogging = false}) {
    _validateSectionWeights(enableLogging: enableLogging);
    validateMajorSkills(enableLogging: enableLogging);
    if (enableLogging) developer.log('ScoringRules initialized successfully');
  }
}
