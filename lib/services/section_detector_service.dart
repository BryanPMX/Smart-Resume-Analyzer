/// A service that detects known resume sections within plain text.
/// Recognizes `==SECTION== Section Name` markers inserted during PDF parsing.
class SectionDetectorService {
  /// Extracts known sections from the structured resume [text].
  /// Keys: contact, summary, experience, education, skills, certifications, projects.
  static Map<String, String> detectSections(String text) {
    final sectionRegex = RegExp(r'^==SECTION==\s+(.+)$', multiLine: true);
    final matches = sectionRegex.allMatches(text).toList();

    final result = <String, String>{};
    final knownLabels = _labelAliases();

    // 1. Add everything before the first ==SECTION== as 'contact'
    if (matches.isNotEmpty && matches.first.start > 0) {
      result['contact'] = text.substring(0, matches.first.start).trim();
    } else {
      result['contact'] = '';
    }

    // 2. Iterate through each section marker and extract the block until the next one
    for (var i = 0; i < matches.length; i++) {
      final rawHeader = matches[i].group(1)?.toLowerCase().trim() ?? '';
      final canonical = knownLabels.entries
          .firstWhere(
            (entry) => entry.value.any((alias) => rawHeader == alias),
        orElse: () => const MapEntry('', []),
      )
          .key;

      if (canonical.isEmpty) continue; // skip unknown section labels

      final start = matches[i].end;
      final end = (i < matches.length - 1) ? matches[i + 1].start : text.length;
      final content = text.substring(start, end).trim();

      result[canonical] = content;
    }

    return result;
  }

  /// Maps canonical section labels to all aliases it may be tagged as.
  static Map<String, List<String>> _labelAliases() => {
    'summary': ['summary', 'objective'],
    'experience': ['experience', 'employment', 'work history'],
    'education': ['education', 'academic background', 'studies'],
    'skills': ['skills', 'technologies', 'tools', 'proficiencies'],
    'projects': ['projects', 'portfolio', 'case studies'],
    'certifications': ['certifications', 'licenses', 'credentials'],
  };
}



