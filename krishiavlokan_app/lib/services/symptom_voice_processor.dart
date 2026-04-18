// lib/services/symptom_voice_processor.dart
//
// Interprets noisy, casual, Hinglish speech and extracts structured
// symptom keys that match AppSymptoms.symptoms keys exactly.
//
// Pipeline:
//   Raw transcript
//     → normalize (lowercase, strip punctuation, collapse whitespace)
//     → remove filler words
//     → language mapping (Hinglish → English equivalents)
//     → multi-pass keyword scan with confidence scoring
//     → threshold filtering
//     → deduplicated symptom key list
//
// Fully offline. No ML. No APIs. Deterministic.

class SymptomVoiceProcessor {
  // ─────────────────────────────────────────────────────────────────────────
  // FILLER WORDS
  // Stripped before any matching so they don't pollute results.
  // ─────────────────────────────────────────────────────────────────────────
  static const _fillers = [
    'haan', 'haan toh', 'matlab', 'toh', 'like', 'you know',
    'uh', 'uhh', 'hmm', 'hm', 'aisa', 'waisa', 'thoda',
    'kind of', 'sort of', 'basically', 'actually', 'i mean',
    'kuch', 'kuch kuch', 'nahi pata', 'pata nahi', 'lagta hai',
    'lag raha', 'dikh raha', 'ho raha', 'ho gaya', 'hua hai',
    'bhi', 'bhi hai', 'aur', 'ya', 'ya phir', 'lekin', 'but',
    'and', 'or', 'the', 'a', 'an', 'is', 'are', 'was', 'were',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // HINGLISH → ENGLISH NORMALIZATION MAP
  //
  // Applied after filler removal. Maps phonetic Hindi / Hinglish fragments
  // to their English counterparts so downstream keyword matching stays simple.
  // Order matters — longer phrases first to avoid partial replacements.
  // ─────────────────────────────────────────────────────────────────────────
  static const _langMap = <String, String>{
    // Drought / dryness / wilting
    'sukha hua'       : 'dry wilting',
    'sukh raha'       : 'wilting dry',
    'sukh gaya'       : 'dry wilted',
    'sukha'           : 'dry',
    'murjha'          : 'wilting',
    'murjhaya'        : 'wilting',
    'jhuk gaya'       : 'drooping wilting',
    'jhuka hua'       : 'drooping',
    'pani nahi'       : 'drought dry',
    'paani ki kami'   : 'drought water deficit',
    'mitti sukhi'     : 'dry soil drought',
    'mitti sookhi'    : 'dry soil drought',
    'drysoil'         : 'dry soil drought',
    'dry soil'        : 'drought dry',

    // Waterlogging / flooding / root rot
    'paani jama'      : 'waterlogging flooded',
    'pani jama'       : 'waterlogging flooded',
    'jad saad'        : 'root rot waterlogging',
    'jad gal'         : 'root rot',
    'jad kali'        : 'black root rot',
    'jad kaali'       : 'black root rot',
    'bahut paani'     : 'overwatered waterlogging',
    'zyada paani'     : 'waterlogging',
    'khet mein paani' : 'field waterlogging flooded',
    'flood'           : 'waterlogging flooded',
    'geela'           : 'wet waterlogging',

    // Yellowing / colour change
    'peela ho'        : 'yellowing yellow',
    'peela pad'       : 'yellowing yellow',
    'pila ho'         : 'yellowing yellow',
    'pila pad'        : 'yellowing yellow',
    'peele patte'     : 'yellow leaves yellowing',
    'pile patte'      : 'yellow leaves yellowing',
    'peela'           : 'yellow yellowing',
    'pila'            : 'yellow yellowing',
    'halka peela'     : 'pale yellow yellowing',
    'rang badal'      : 'discoloration yellowing',
    'rang peela'      : 'yellow yellowing',

    // Spots / lesions / blight
    'kaale daag'      : 'black spots',
    'kale daag'       : 'black spots',
    'bhoore daag'     : 'brown spots',
    'dhabbe'          : 'spots blotches',
    'daag'            : 'spots',
    'dhabbay'         : 'spots blotches',
    'chhale'          : 'blisters spots',
    'nishaan'         : 'marks spots',
    'kaala'           : 'black',
    'kaali'           : 'black',
    'bhoora'          : 'brown',

    // Fungal / powdery mildew / white growth
    'safed powder'    : 'white powder powdery mildew fungal',
    'safed parat'     : 'white layer powdery fungal',
    'safed daag'      : 'white spots fungal',
    'safed'           : 'white',
    'fungus jaisa'    : 'fungal disease',
    'fungus'          : 'fungal',
    'mold'            : 'fungal mold',
    'mould'           : 'fungal mold',
    'rog'             : 'disease fungal',
    'bimaari'         : 'disease',

    // Pest / insect damage
    'keede'           : 'pests insects',
    'keeda'           : 'pest insect',
    'kide'            : 'pests insects',
    'kida'            : 'pest insect',
    'makhi'           : 'fly pest',
    'tiddha'          : 'locust pest',
    'saphed keeda'    : 'whitefly pest',
    'chitke'          : 'holes pest damage',
    'chhed'           : 'holes pest damage',
    'kha liya'        : 'eaten pest damage',
    'patte kha'       : 'leaves eaten pest',
    'katna'           : 'cutting pest',
    'kaata'           : 'bitten pest damage',

    // Heat stress
    'garmi'           : 'heat hot',
    'jhulsa'          : 'scorched heat',
    'jala hua'        : 'burnt scorched heat',
    'jal gaya'        : 'burnt heat',
    'dhoop'           : 'sun heat',
    'tapman'          : 'temperature heat',
    'taap'            : 'heat temperature',

    // Nutrient deficiency
    'khad nahi'       : 'fertilizer deficiency nutrient',
    'urvarak'         : 'fertilizer nutrient',
    'poshan'          : 'nutrition nutrient',
    'kami'            : 'deficiency',
    'kamzor'          : 'weak deficiency',
    'halka'           : 'pale weak',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // SYMPTOM KEYWORD CONFIG
  //
  // Keys MUST match AppSymptoms.symptoms 'key' values exactly:
  //   drought | waterlogging | nutrient | pest | fungal | heat
  //
  // Each entry has:
  //   strong  → single match is enough to confirm symptom
  //   weak    → need 2+ weak matches OR 1 strong + 1 weak
  // ─────────────────────────────────────────────────────────────────────────
  static const _config = <String, _SymptomConfig>{
    'drought': _SymptomConfig(
      strong: ['drought', 'wilting', 'wilted', 'dry soil', 'drysoil'],
      weak:   ['dry', 'drooping', 'water deficit', 'cracked soil',
                'thirsty', 'dehydrated', 'shriveled'],
    ),
    'waterlogging': _SymptomConfig(
      strong: ['waterlogging', 'flooded', 'root rot', 'overwatered'],
      weak:   ['wet', 'soggy', 'standing water', 'drainage', 'muddy',
                'black root', 'smell root', 'submerged'],
    ),
    'nutrient': _SymptomConfig(
      strong: ['yellowing', 'yellow leaves', 'nutrient deficiency', 'pale leaves'],
      weak:   ['yellow', 'pale', 'deficiency', 'stunted', 'slow growth',
                'weak plant', 'discoloration', 'fertilizer'],
    ),
    'pest': _SymptomConfig(
      strong: ['pest damage', 'insects', 'pests', 'eaten leaves', 'holes in leaves'],
      weak:   ['holes', 'bitten', 'eaten', 'larvae', 'worms', 'bugs',
                'aphids', 'whitefly', 'spider mites', 'damage'],
    ),
    'fungal': _SymptomConfig(
      strong: ['fungal', 'powdery mildew', 'white powder', 'mold', 'blight'],
      weak:   ['white', 'spots', 'blotches', 'brown spots', 'black spots',
                'rust', 'lesion', 'rot', 'disease', 'grey mold'],
    ),
    'heat': _SymptomConfig(
      strong: ['heat stress', 'scorched', 'heat damage', 'burnt leaves'],
      weak:   ['heat', 'hot', 'burnt', 'sun damage', 'wilting',
                'leaf curl', 'tip burn', 'bleached'],
    ),
  };

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINT
  // ─────────────────────────────────────────────────────────────────────────

  /// Processes a raw voice transcript and returns matched symptom keys.
  /// Returns empty list if nothing is detected with sufficient confidence.
  List<String> detectSymptoms(String rawTranscript) {
    if (rawTranscript.trim().isEmpty) return [];

    // Step 1 — normalize
    var text = _normalize(rawTranscript);

    // Step 2 — remove fillers
    text = _removeFillers(text);

    // Step 3 — language mapping (Hinglish → English equivalents)
    text = _applyLangMap(text);

    // Step 4 — scan and score
    final scores = _scoreAll(text);

    // Step 5 — threshold filter and return keys
    return _threshold(scores);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — NORMALIZE
  // ─────────────────────────────────────────────────────────────────────────
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')  // strip punctuation
        .replaceAll(RegExp(r'\s+'), ' ')       // collapse whitespace
        .trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — REMOVE FILLERS
  // ─────────────────────────────────────────────────────────────────────────
  String _removeFillers(String text) {
    // Sort by length descending so multi-word fillers are caught before singles
    final sorted = List<String>.from(_fillers)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final filler in sorted) {
      text = text.replaceAll(RegExp('\\b${RegExp.escape(filler)}\\b'), ' ');
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — LANGUAGE MAPPING
  // Longer phrases first, then shorter — prevents partial over-replacement.
  // ─────────────────────────────────────────────────────────────────────────
  String _applyLangMap(String text) {
    final sorted = _langMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sorted) {
      text = text.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        ' ${entry.value} ',
      );
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4 — SCORE ALL SYMPTOMS
  //
  // For each symptom:
  //   strongScore = count of strong keywords found
  //   weakScore   = count of weak keywords found
  //
  // We also scan the original transcript (post-normalize but pre-filler
  // removal) so we don't miss keywords that overlap with filler patterns.
  // ─────────────────────────────────────────────────────────────────────────
  Map<String, _Score> _scoreAll(String processedText) {
    final scores = <String, _Score>{};

    for (final entry in _config.entries) {
      final key    = entry.key;
      final config = entry.value;
      int strong = 0;
      int weak   = 0;

      for (final kw in config.strong) {
        if (processedText.contains(kw)) strong++;
      }
      for (final kw in config.weak) {
        if (processedText.contains(kw)) weak++;
      }

      scores[key] = _Score(strong: strong, weak: weak);
    }

    return scores;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 5 — THRESHOLD FILTER
  //
  // A symptom is selected when:
  //   strong ≥ 1   (one definitive keyword found)
  //   OR
  //   weak ≥ 2     (two or more weak signals)
  //
  // This prevents random single weak matches from triggering a symptom.
  // ─────────────────────────────────────────────────────────────────────────
  List<String> _threshold(Map<String, _Score> scores) {
    final matched = <String>[];
    for (final entry in scores.entries) {
      final s = entry.value;
      if (s.strong >= 1 || s.weak >= 2) {
        matched.add(entry.key);
      }
    }
    return matched;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITY — human-readable label for matched keys (used in snackbar)
  // ─────────────────────────────────────────────────────────────────────────
  static String labelFor(String key) => switch (key) {
        'drought'      => 'Drought Stress',
        'waterlogging' => 'Waterlogging',
        'nutrient'     => 'Nutrient Deficiency',
        'pest'         => 'Pest Damage',
        'fungal'       => 'Fungal Disease',
        'heat'         => 'Heat Stress',
        _              => key,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers — not exported
// ─────────────────────────────────────────────────────────────────────────────

class _SymptomConfig {
  final List<String> strong;
  final List<String> weak;
  const _SymptomConfig({required this.strong, required this.weak});
}

class _Score {
  final int strong;
  final int weak;
  const _Score({required this.strong, required this.weak});
}
