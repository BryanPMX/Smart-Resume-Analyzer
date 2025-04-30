/// Centralized configuration for resume scoring weights, keywords, and rule parameters.
/// Supports both general and major-specific skill sets for tailored scoring.
class ScoringRules {
  // ===================== Section Weights =====================
  static const int contactMax = 15;
  static const int summaryMax = 10;
  static const int experienceMax = 20;
  static const int educationMax = 15;
  static const int skillsMax = 20;
  static const int projectsMax = 15;
  static const int certificationsMax = 5;

  // ===================== Contact Scoring =====================
  static final RegExp emailRegex =
  RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false);
  static final RegExp phoneRegex =
  RegExp(r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}');
  static const int contactEmailScore = 7;
  static const int contactPhoneScore = 5;
  static const int contactLinkedInScore = 3;
  static const int contactGitHubScore = 2;
  static const int contactPortfolioScore = 2;
  /// Matches LinkedIn, GitHub, or portfolio URLs
  static final RegExp portfolioRegex =
  RegExp(r'(linkedin\.com|github\.com|portfolio|netlify\.app)', caseSensitive: false);

  // ===================== Summary Scoring =====================
  static const int summaryWordThreshold = 30;
  static const int summaryPartialScore = 5;

  // ===================== Experience Scoring =====================
  static const int experienceVerbThreshold = 3;
  static const int experiencePartialScore = 10;
  static const List<String> actionVerbs = [
    'developed', 'managed', 'led', 'built', 'designed', 'created',
    'implemented', 'optimized', 'analyzed', 'automated',
  ];

  // ===================== Education Scoring =====================
  static const int educationBaseScore = 10;
  static const int educationDegreeScore = 3;
  static const int educationYearScore = 2;
  static final RegExp gradYearRegex = RegExp(r'20\d{2}');

  // ===================== Skills Scoring =====================
  static const int skillsCap = 10;
  static const int pointsPerSkill = 2;

  // ===================== Projects Scoring =====================
  static final RegExp projectSectionRegex =
  RegExp(r'project', caseSensitive: false);

  // ===================== Certifications Scoring =====================
  static final RegExp certificationRegex =
  RegExp(r'certified?\s+[a-z ]+|[a-z ]+certification', caseSensitive: false);

  // ===================== Fallback Skill Keywords =====================
  /// When no known major is detected, these general skills are used.
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
  /// Map from academic major to its top relevant skills.
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
      'teamwork'
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
      'problem-solving'
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
      'communication'
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
      'communication skills'
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
      'communication skills'
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
      'cultural competence'
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
      'presentation skills'
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
      'excel'
    ],
    'Accounting': [
      'attention to detail',
      'gaap knowledge',
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
      'communication skills'
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
      'communication'
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
      'organizational skills'
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
      'attention to detail'
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
      'collaboration'
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
      'project management'
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
      'collaboration'
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
      'computational tools'
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
      'itil processes',
      'troubleshooting',
      'customer service',
      'project management',
      'attention to detail',
      'continuous learning'
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
      'communication'
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
      'persistence'
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
      'laboratory skills'
    ],
  };
}