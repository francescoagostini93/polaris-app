/// Types of cognitive exercises
enum ExerciseType {
  memory,
  attention,
  fluency,
  numbers,
}

/// A single article for memory exercise
class MemoryArticle {
  final String title;
  final String content;
  final List<String> questions;

  MemoryArticle({
    required this.title,
    required this.content,
    required this.questions,
  });

  factory MemoryArticle.fromJson(Map<String, dynamic> json) {
    return MemoryArticle(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      questions: List<String>.from(json['questions'] ?? []),
    );
  }
}

/// Hidden word for attention exercise
class HiddenWord {
  final String word;
  final String hiddenString;

  HiddenWord({
    required this.word,
    required this.hiddenString,
  });

  factory HiddenWord.fromJson(Map<String, dynamic> json) {
    return HiddenWord(
      word: json['word'] ?? '',
      hiddenString: json['hidden_string'] ?? '',
    );
  }
}

/// Fluency exercise part
class FluencyPart {
  final String type; // 'phonemic', 'semantic', 'alternating'
  final String instruction;
  final String target; // syllable or category

  FluencyPart({
    required this.type,
    required this.instruction,
    required this.target,
  });

  factory FluencyPart.fromJson(Map<String, dynamic> json) {
    return FluencyPart(
      type: json['type'] ?? '',
      instruction: json['instruction'] ?? '',
      target: json['target'] ?? '',
    );
  }
}

/// Number sequence for memorization
class NumberSequence {
  final List<int> digits;

  NumberSequence({required this.digits});

  factory NumberSequence.fromJson(Map<String, dynamic> json) {
    return NumberSequence(
      digits: List<int>.from(json['digits'] ?? []),
    );
  }

  String get displayString => digits.join(' - ');
}

/// Complete exercise set for a session
class ExerciseSet {
  final int difficulty;
  final List<MemoryArticle> memoryArticles;
  final List<List<HiddenWord>> attentionParts;
  final List<FluencyPart> fluencyParts;
  final List<List<NumberSequence>> numberParts;

  ExerciseSet({
    required this.difficulty,
    required this.memoryArticles,
    required this.attentionParts,
    required this.fluencyParts,
    required this.numberParts,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json, int difficulty) {
    // Parse memory articles
    final memoryArticles = (json['memory'] as List?)
            ?.map((a) => MemoryArticle.fromJson(a))
            .toList() ??
        [];

    // Parse attention parts
    final attentionParts = (json['attention'] as List?)
            ?.map((part) => (part as List)
                .map((w) => HiddenWord.fromJson(w))
                .toList())
            .toList() ??
        [];

    // Parse fluency parts
    final fluencyParts = (json['fluency'] as List?)
            ?.map((f) => FluencyPart.fromJson(f))
            .toList() ??
        [];

    // Parse number parts
    final numberParts = (json['numbers'] as List?)
            ?.map((part) => (part as List)
                .map((s) => NumberSequence.fromJson(s))
                .toList())
            .toList() ??
        [];

    return ExerciseSet(
      difficulty: difficulty,
      memoryArticles: memoryArticles,
      attentionParts: attentionParts,
      fluencyParts: fluencyParts,
      numberParts: numberParts,
    );
  }
}
