import 'dart:developer' as developer;
import '../models/major.dart';
import '../utils/scoring_rules.dart';

/// A service that auto-detects a candidate’s academic major from resume text.
///
/// It matches the input text against a predefined set of aliases for each
/// `Major` enum value. Returns the unique detected `Major`, or `null` if
/// none (or more than one) is found. Designed to integrate with
/// `ScoringService` and `ScoringRules` for tailored skill scoring.
class MajorDetector {
  /// Maximum text length to process to prevent excessive memory usage.
  static const int _maxTextLength = 100 * 1024; // 100 KB

  /// Map of each [Major] enum to its list of lowercase aliases.
  static final Map<Major, List<String>> _majorAliases = {
    Major.computerScience:       ['computer science', 'cs', 'comp sci'],
    Major.businessAdministration:['business administration', 'business admin', 'biz admin'],
    Major.mechanicalEngineering: ['mechanical engineering', 'mech eng', 'mechanical eng'],
    Major.nursing:               ['nursing'],
    Major.electricalEngineering: ['electrical engineering', 'ee', 'electrical eng'],
    Major.psychology:            ['psychology', 'psych'],
    Major.biology:               ['biology', 'bio'],
    Major.economics:             ['economics', 'econ'],
    Major.accounting:            ['accounting', 'acct'],
    Major.civilEngineering:      ['civil engineering', 'civil eng'],
    Major.education:             ['education', 'edu'],
    Major.finance:               ['finance', 'fin'],
    Major.politicalScience:      ['political science', 'poli sci'],
    Major.marketing:             ['marketing', 'mktg'],
    Major.communications:        ['communications', 'comm'],
    Major.chemistry:             ['chemistry', 'chem'],
    Major.informationTechnology: ['information technology', 'it', 'info tech'],
    Major.graphicDesign:         ['graphic design', 'gd', 'design'],
    Major.mathematics:           ['mathematics', 'math', 'maths'],
    Major.environmentalScience:  ['environmental science', 'env sci', 'environmental sci'],
    Major.english:               ['english'],
    Major.history:               ['history'],
    Major.sociology:             ['sociology', 'soc sci', 'soc'],
  };

  /// Inverted lookup: alias → canonical [Major].
  static final Map<String, Major> _aliasToMajor = _buildAliasLookup();

  /// Builds a lowercase alias→Major map for O(1) matching.
  static Map<String, Major> _buildAliasLookup() {
    final map = <String, Major>{};
    _majorAliases.forEach((major, aliases) {
      for (var alias in aliases) {
        map[alias.toLowerCase()] = major;
      }
    });
    return map;
  }

  /// Detects the candidate’s academic major from the provided [text].
  ///
  /// - Throws [ArgumentError] if [text] is empty or exceeds [_maxTextLength].
  /// - Returns a single [Major] if exactly one valid match is found.
  /// - Returns `null` if no valid match or multiple distinct matches occur.
  ///
  /// When [enableLogging] is true, logs each detection step for debugging.
  static Major? detectMajor(String text, {bool enableLogging = false}) {
    if (text.isEmpty) {
      throw ArgumentError('Input text cannot be empty');
    }
    if (text.length > _maxTextLength) {
      throw ArgumentError(
          'Input text exceeds maximum length of $_maxTextLength characters');
    }

    final lower = text.toLowerCase();
    final found = <Major>{};

    // Check each alias; if the resume text contains it, record the Major
    for (final entry in _aliasToMajor.entries) {
      if (lower.contains(entry.key)) {
        found.add(entry.value);
        if (enableLogging) {
          developer.log('Alias match: "${entry.key}" → ${entry.value}');
        }
      }
    }

    // Filter to only those Majors we have scoring rules for
    final valid = found.where((m) =>
        ScoringRules.majorRelevantSkills.containsKey(m)).toSet();

    if (enableLogging) {
      if (valid.isEmpty) {
        developer.log('MajorDetector: no valid majors detected');
      } else if (valid.length > 1) {
        developer.log('MajorDetector: ambiguous majors detected: $valid');
      } else {
        developer.log('MajorDetector: detected major: ${valid.first}');
      }
    }

    return valid.length == 1 ? valid.first : null;
  }
}



