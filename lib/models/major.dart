/// Represents the academic or professional major / field of study
/// used to tailor resume scoring rules and feedback.
enum Major {
  /// Computer Science, e.g. software development, algorithms, data structures.
  computerScience,

  /// Business Administration, e.g. management, strategy, finance basics.
  businessAdministration,

  /// Mechanical Engineering, e.g. CAD, thermodynamics, prototyping.
  mechanicalEngineering,

  /// Nursing, e.g. patient care, medication administration, EMR.
  nursing,

  /// Electrical Engineering, e.g. circuit design, signal processing.
  electricalEngineering,

  /// Psychology, e.g. counseling, research methods, statistical analysis.
  psychology,

  /// Biology, e.g. molecular biology, lab techniques, bioinformatics.
  biology,

  /// Economics, e.g. econometrics, forecasting, policy analysis.
  economics,

  /// Accounting, e.g. GAAP, auditing, financial reporting.
  accounting,

  /// Civil Engineering, e.g. structural analysis, surveying, CAD.
  civilEngineering,

  /// Education, e.g. curriculum development, classroom management.
  education,

  /// Finance, e.g. financial modeling, risk management.
  finance,

  /// Political Science, e.g. policy analysis, international relations.
  politicalScience,

  /// Marketing, e.g. SEO, content creation, brand strategy.
  marketing,

  /// Communications, e.g. public speaking, media relations.
  communications,

  /// Chemistry, e.g. analytical chemistry, organic synthesis.
  chemistry,

  /// Information Technology, e.g. networking, system administration.
  informationTechnology,

  /// Graphic Design, e.g. typography, layout design, Photoshop.
  graphicDesign,

  /// Mathematics, e.g. modeling, proofs, statistical analysis.
  mathematics,

  /// Environmental Science, e.g. ecology, GIS, sustainability.
  environmentalScience,

  /// English, e.g. writing, literary analysis, editing.
  english,

  /// History, e.g. archival research, historical analysis.
  history,

  /// Sociology, e.g. survey design, cultural competence.
  sociology,
}

/// Extension to convert between the enum and its canonical display name
extension MajorExtension on Major {
  /// The exact canonical String used as keys in [ScoringRules.majorRelevantSkills]
  /// and in the alias map of [MajorDetector].
  String toDisplayString() {
    switch (this) {
      case Major.computerScience:
        return 'Computer Science';
      case Major.businessAdministration:
        return 'Business Administration';
      case Major.mechanicalEngineering:
        return 'Mechanical Engineering';
      case Major.nursing:
        return 'Nursing';
      case Major.electricalEngineering:
        return 'Electrical Engineering';
      case Major.psychology:
        return 'Psychology';
      case Major.biology:
        return 'Biology';
      case Major.economics:
        return 'Economics';
      case Major.accounting:
        return 'Accounting';
      case Major.civilEngineering:
        return 'Civil Engineering';
      case Major.education:
        return 'Education';
      case Major.finance:
        return 'Finance';
      case Major.politicalScience:
        return 'Political Science';
      case Major.marketing:
        return 'Marketing';
      case Major.communications:
        return 'Communications';
      case Major.chemistry:
        return 'Chemistry';
      case Major.informationTechnology:
        return 'Information Technology';
      case Major.graphicDesign:
        return 'Graphic Design';
      case Major.mathematics:
        return 'Mathematics';
      case Major.environmentalScience:
        return 'Environmental Science';
      case Major.english:
        return 'English';
      case Major.history:
        return 'History';
      case Major.sociology:
        return 'Sociology';
    }
  }

  /// Parses a canonical display string back into the enum, or returns null if none match.
  static Major? fromDisplayString(String display) {
    for (var m in Major.values) {
      if (m.toDisplayString().toLowerCase() == display.toLowerCase()) {
        return m;
      }
    }
    return null;
  }
}
